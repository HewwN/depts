import 'package:equatable/equatable.dart';

enum TransactionType { gave, took }

enum TransactionStatus { active, closed }

class DebtTransaction extends Equatable {
  final String date;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String note;

  /// 1-based row index in the spreadsheet (row 1 = header).
  final int rowIndex;

  const DebtTransaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
    required this.note,
    required this.rowIndex,
  });

  factory DebtTransaction.fromRow(List<dynamic> row, int rowIndex) {
    return DebtTransaction(
      date: row.isNotEmpty ? row[0].toString() : '',
      amount: row.length > 1 ? double.tryParse(row[1].toString()) ?? 0.0 : 0.0,
      type: row.length > 2 && row[2].toString() == 'TOOK'
          ? TransactionType.took
          : TransactionType.gave,
      status: row.length > 3 && row[3].toString() == 'CLOSED'
          ? TransactionStatus.closed
          : TransactionStatus.active,
      note: row.length > 4 ? row[4].toString() : '',
      rowIndex: rowIndex,
    );
  }

  List<Object> toRow() {
    return [
      date,
      amount,
      type == TransactionType.gave ? 'GAVE' : 'TOOK',
      status == TransactionStatus.active ? 'ACTIVE' : 'CLOSED',
      note,
    ];
  }

  DebtTransaction copyWith({TransactionStatus? status}) {
    return DebtTransaction(
      date: date,
      amount: amount,
      type: type,
      status: status ?? this.status,
      note: note,
      rowIndex: rowIndex,
    );
  }

  @override
  List<Object?> get props => [date, amount, type, status, note, rowIndex];
}
