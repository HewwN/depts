import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/debt_transaction.dart';
import '../../models/person_debt.dart';
import '../../services/google_sheets_service.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class SheetsEvent extends Equatable {
  const SheetsEvent();
  @override
  List<Object?> get props => [];
}

class SheetsFetchPeople extends SheetsEvent {
  final bool forceRefresh;
  const SheetsFetchPeople({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class SheetsAddPerson extends SheetsEvent {
  final String name;
  const SheetsAddPerson(this.name);
  @override
  List<Object?> get props => [name];
}

class SheetsFetchTransactions extends SheetsEvent {
  final String personName;
  final bool forceRefresh;
  const SheetsFetchTransactions(this.personName, {this.forceRefresh = false});
  @override
  List<Object?> get props => [personName, forceRefresh];
}

class SheetsAddTransaction extends SheetsEvent {
  final String personName;
  final DebtTransaction transaction;
  const SheetsAddTransaction(
      {required this.personName, required this.transaction});
  @override
  List<Object?> get props => [personName, transaction];
}

class SheetsCloseTransactions extends SheetsEvent {
  final String personName;
  const SheetsCloseTransactions(this.personName);
  @override
  List<Object?> get props => [personName];
}

// ── States ─────────────────────────────────────────────────────────────────

abstract class SheetsState extends Equatable {
  const SheetsState();
  @override
  List<Object?> get props => [];
}

class SheetsInitial extends SheetsState {}

class SheetsLoading extends SheetsState {}

class SheetsPeopleLoaded extends SheetsState {
  final List<PersonDebt> people;
  const SheetsPeopleLoaded(this.people);
  @override
  List<Object?> get props => [people];
}

class SheetsTransactionsLoaded extends SheetsState {
  final PersonDebt person;
  const SheetsTransactionsLoaded(this.person);
  @override
  List<Object?> get props => [person];
}

class SheetsOperationSuccess extends SheetsState {
  final String message;
  const SheetsOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SheetsError extends SheetsState {
  final String message;
  const SheetsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────

class SheetsBloc extends Bloc<SheetsEvent, SheetsState> {
  final GoogleSheetsService _service;

  SheetsBloc(this._service) : super(SheetsInitial()) {
    on<SheetsFetchPeople>(_onFetchPeople);
    on<SheetsAddPerson>(_onAddPerson);
    on<SheetsFetchTransactions>(_onFetchTransactions);
    on<SheetsAddTransaction>(_onAddTransaction);
    on<SheetsCloseTransactions>(_onCloseTransactions);
  }

  Future<void> _onFetchPeople(
      SheetsFetchPeople event, Emitter<SheetsState> emit) async {
    emit(SheetsLoading());
    try {
      final people = await _service.fetchAllPeople(
          forceRefresh: event.forceRefresh);
      emit(SheetsPeopleLoaded(people));
    } catch (e) {
      emit(SheetsError(e.toString()));
    }
  }

  Future<void> _onAddPerson(
      SheetsAddPerson event, Emitter<SheetsState> emit) async {
    emit(SheetsLoading());
    try {
      await _service.addPerson(event.name);
      final people = await _service.fetchAllPeople(forceRefresh: true);
      emit(SheetsPeopleLoaded(people));
    } catch (e) {
      emit(SheetsError(e.toString()));
    }
  }

  Future<void> _onFetchTransactions(
      SheetsFetchTransactions event, Emitter<SheetsState> emit) async {
    emit(SheetsLoading());
    try {
      final person = await _service.fetchPerson(event.personName,
          forceRefresh: event.forceRefresh);
      emit(SheetsTransactionsLoaded(person));
    } catch (e) {
      emit(SheetsError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(
      SheetsAddTransaction event, Emitter<SheetsState> emit) async {
    emit(SheetsLoading());
    try {
      await _service.addTransaction(event.personName, event.transaction);
      final person =
          await _service.fetchPerson(event.personName, forceRefresh: true);
      emit(SheetsTransactionsLoaded(person));
    } catch (e) {
      emit(SheetsError(e.toString()));
    }
  }

  Future<void> _onCloseTransactions(
      SheetsCloseTransactions event, Emitter<SheetsState> emit) async {
    emit(SheetsLoading());
    try {
      await _service.closeAllTransactions(event.personName);
      final person =
          await _service.fetchPerson(event.personName, forceRefresh: true);
      emit(SheetsTransactionsLoaded(person));
    } catch (e) {
      emit(SheetsError(e.toString()));
    }
  }
}
