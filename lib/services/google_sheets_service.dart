import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import '../models/debt_transaction.dart';
import '../models/person_debt.dart';

class GoogleSheetsService {
  // `drive.file` grants access only to files created or explicitly opened
  // by this app — the app cannot see or modify any other files on the
  // user's Google Drive. It is also sufficient for all Sheets API calls
  // used here (create, get, values.get/update/append, batchUpdate).
  static const _scopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];

  final _googleSignIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? _currentUser;
  http.Client? _httpClient;
  sheets.SheetsApi? _sheetsApi;
  drive.DriveApi? _driveApi;

  String? _spreadsheetId;

  // ── In-memory cache ────────────────────────────────────────────────────────
  List<PersonDebt>? _cachedPeople;

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser != null) {
      await _initClients();
    }
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _httpClient = null;
    _sheetsApi = null;
    _driveApi = null;
    _spreadsheetId = null;
    _cachedPeople = null;
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    _currentUser = await _googleSignIn.signInSilently();
    if (_currentUser != null) {
      await _initClients();
    }
    return _currentUser;
  }

  Future<void> _initClients() async {
    _httpClient = await _googleSignIn.authenticatedClient();
    if (_httpClient == null) {
      throw Exception('Failed to obtain authenticated HTTP client.');
    }
    _sheetsApi = sheets.SheetsApi(_httpClient!);
    _driveApi = drive.DriveApi(_httpClient!);
  }

  /// Re-authenticate if the token has expired, then retry [action].
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('invalid_grant')) {
        // Force token refresh.
        _currentUser = await _googleSignIn.signInSilently(reAuthenticate: true);
        if (_currentUser == null) {
          _currentUser = await _googleSignIn.signIn();
        }
        if (_currentUser == null) throw Exception('Re-authentication failed.');
        await _initClients();
        return await action();
      }
      rethrow;
    }
  }

  void _ensureReady() {
    if (_sheetsApi == null || _driveApi == null || _spreadsheetId == null) {
      throw Exception(
          'Service not ready. Sign in and select a spreadsheet first.');
    }
  }

  // ── Spreadsheet selection / creation ──────────────────────────────────────

  void setSpreadsheetId(String id) {
    _spreadsheetId = id;
    _cachedPeople = null;
  }

  String? get spreadsheetId => _spreadsheetId;

  /// List spreadsheets in Drive that the user owns / has access to.
  Future<List<drive.File>> listSpreadsheets() async {
    if (_driveApi == null) throw Exception('Not signed in.');
    return _withRetry(() async {
      final result = await _driveApi!.files.list(
        q: "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
        $fields: 'files(id, name)',
      );
      return result.files ?? [];
    });
  }

  /// Create a new spreadsheet named [name] and return its ID.
  Future<String> createSpreadsheet(String name) async {
    if (_sheetsApi == null) throw Exception('Not signed in.');
    return _withRetry(() async {
      final spreadsheet = sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: name),
      );
      final result = await _sheetsApi!.spreadsheets.create(spreadsheet);
      return result.spreadsheetId!;
    });
  }

  // ── People (sheets/tabs) ───────────────────────────────────────────────────

  Future<List<PersonDebt>> fetchAllPeople({bool forceRefresh = false}) async {
    _ensureReady();
    if (!forceRefresh && _cachedPeople != null) return _cachedPeople!;

    return _withRetry(() async {
      final spreadsheet = await _sheetsApi!.spreadsheets
          .get(_spreadsheetId!, includeGridData: false);

      final people = <PersonDebt>[];

      for (final sheet in spreadsheet.sheets ?? []) {
        final title = sheet.properties?.title ?? '';
        if (title.isEmpty) continue;

        final transactions = await _fetchTransactions(title);
        people.add(PersonDebt(name: title, transactions: transactions));
      }

      _cachedPeople = people;
      return people;
    });
  }

  Future<PersonDebt> fetchPerson(String name,
      {bool forceRefresh = false}) async {
    _ensureReady();
    if (!forceRefresh && _cachedPeople != null) {
      final cached = _cachedPeople!.where((p) => p.name == name).toList();
      if (cached.isNotEmpty) return cached.first;
    }
    return _withRetry(() async {
      final transactions = await _fetchTransactions(name);
      final person = PersonDebt(name: name, transactions: transactions);
      _updateCache(person);
      return person;
    });
  }

  Future<List<DebtTransaction>> _fetchTransactions(String sheetName) async {
    final range = "'$sheetName'!A2:E";
    try {
      final response = await _sheetsApi!.spreadsheets.values
          .get(_spreadsheetId!, range);
      final rows = response.values ?? [];
      return List.generate(rows.length, (i) {
        return DebtTransaction.fromRow(rows[i], i + 2); // row 1 = header
      });
    } catch (_) {
      return [];
    }
  }

  /// Add a new sheet (person) and write the header row.
  Future<void> addPerson(String name) async {
    _ensureReady();
    return _withRetry(() async {
      // 1. Add sheet via batchUpdate.
      final addRequest = sheets.Request(
        addSheet: sheets.AddSheetRequest(
          properties: sheets.SheetProperties(title: name),
        ),
      );
      await _sheetsApi!.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: [addRequest]),
        _spreadsheetId!,
      );

      // 2. Write header row.
      final headerRange = "'$name'!A1:E1";
      await _sheetsApi!.spreadsheets.values.update(
        sheets.ValueRange(
          range: headerRange,
          values: [
            ['Дата', 'Сумма', 'Тип', 'Статус', 'Заметка'],
          ],
        ),
        _spreadsheetId!,
        headerRange,
        valueInputOption: 'USER_ENTERED',
      );

      _cachedPeople = null; // invalidate cache
    });
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<void> addTransaction(
      String personName, DebtTransaction transaction) async {
    _ensureReady();
    return _withRetry(() async {
      final range = "'$personName'!A:E";
      await _sheetsApi!.spreadsheets.values.append(
        sheets.ValueRange(
          range: range,
          values: [transaction.toRow()],
        ),
        _spreadsheetId!,
        range,
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
      _cachedPeople = null; // invalidate cache
    });
  }

  /// Close all active transactions for [personName].
  Future<void> closeAllTransactions(String personName) async {
    _ensureReady();
    return _withRetry(() async {
      final transactions = await _fetchTransactions(personName);
      final activeTransactions =
          transactions.where((t) => t.status == TransactionStatus.active).toList();

      if (activeTransactions.isEmpty) return;

      // Build individual update requests for each active row.
      final requests = activeTransactions.map((t) {
        final range = "'$personName'!D${t.rowIndex}";
        return sheets.Request(
          updateCells: sheets.UpdateCellsRequest(
            range: sheets.GridRange(
              sheetId: null, // resolved via range string approach below
            ),
            fields: 'userEnteredValue',
            rows: [
              sheets.RowData(values: [
                sheets.CellData(
                  userEnteredValue:
                      sheets.ExtendedValue(stringValue: 'CLOSED'),
                ),
              ]),
            ],
          ),
        );
      }).toList();

      // Use values.update per row (simpler than batchUpdate with sheetId lookup).
      for (final t in activeTransactions) {
        final range = "'$personName'!D${t.rowIndex}";
        await _sheetsApi!.spreadsheets.values.update(
          sheets.ValueRange(
            range: range,
            values: [
              ['CLOSED'],
            ],
          ),
          _spreadsheetId!,
          range,
          valueInputOption: 'USER_ENTERED',
        );
      }

      _cachedPeople = null;
    });
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  void _updateCache(PersonDebt person) {
    if (_cachedPeople == null) return;
    final idx = _cachedPeople!.indexWhere((p) => p.name == person.name);
    if (idx >= 0) {
      _cachedPeople![idx] = person;
    } else {
      _cachedPeople!.add(person);
    }
  }

  void invalidateCache() => _cachedPeople = null;
}
