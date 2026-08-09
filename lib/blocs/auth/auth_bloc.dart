import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../services/google_sheets_service.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthSignInRequested extends AuthEvent {}

class AuthSignInSilentlyRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthSpreadsheetSelected extends AuthEvent {
  final String spreadsheetId;
  const AuthSpreadsheetSelected(this.spreadsheetId);
  @override
  List<Object?> get props => [spreadsheetId];
}

class AuthSpreadsheetCreated extends AuthEvent {
  final String name;
  const AuthSpreadsheetCreated(this.name);
  @override
  List<Object?> get props => [name];
}

// ── States ─────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSignedIn extends AuthState {
  final GoogleSignInAccount user;
  final List<drive.File> spreadsheets;
  const AuthSignedIn({required this.user, required this.spreadsheets});
  @override
  List<Object?> get props => [user, spreadsheets];
}

class AuthSpreadsheetReady extends AuthState {
  final GoogleSignInAccount user;
  final String spreadsheetId;
  const AuthSpreadsheetReady(
      {required this.user, required this.spreadsheetId});
  @override
  List<Object?> get props => [user, spreadsheetId];
}

class AuthSignedOut extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSheetsService _service;

  AuthBloc(this._service) : super(AuthInitial()) {
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignInSilentlyRequested>(_onSignInSilently);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthSpreadsheetSelected>(_onSpreadsheetSelected);
    on<AuthSpreadsheetCreated>(_onSpreadsheetCreated);
  }

  Future<void> _onSignIn(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _service.signIn();
      if (user == null) {
        emit(AuthSignedOut());
        return;
      }
      final spreadsheets = await _service.listSpreadsheets();
      emit(AuthSignedIn(user: user, spreadsheets: spreadsheets));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInSilently(
      AuthSignInSilentlyRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _service.signInSilently();
      if (user == null) {
        emit(AuthSignedOut());
        return;
      }
      final id = _service.spreadsheetId;
      if (id != null) {
        emit(AuthSpreadsheetReady(user: user, spreadsheetId: id));
      } else {
        final spreadsheets = await _service.listSpreadsheets();
        emit(AuthSignedIn(user: user, spreadsheets: spreadsheets));
      }
    } catch (e) {
      emit(AuthSignedOut());
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _service.signOut();
    emit(AuthSignedOut());
  }

  Future<void> _onSpreadsheetSelected(
      AuthSpreadsheetSelected event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      _service.setSpreadsheetId(event.spreadsheetId);
      final user = await _service.signInSilently();
      emit(AuthSpreadsheetReady(
          user: user!, spreadsheetId: event.spreadsheetId));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSpreadsheetCreated(
      AuthSpreadsheetCreated event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final id = await _service.createSpreadsheet(event.name);
      _service.setSpreadsheetId(id);
      final user = await _service.signInSilently();
      emit(AuthSpreadsheetReady(user: user!, spreadsheetId: id));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
