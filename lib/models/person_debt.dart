import 'package:equatable/equatable.dart';
import 'debt_transaction.dart';

class PersonDebt extends Equatable {
  final String name;
  final List<DebtTransaction> transactions;

  const PersonDebt({required this.name, required this.transactions});

  /// Positive balance means the person owes me; negative means I owe them.
  double get balance {
    double total = 0;
    for (final t in transactions) {
      if (t.status == TransactionStatus.active) {
        total += t.type == TransactionType.gave ? t.amount : -t.amount;
      }
    }
    return total;
  }

  bool get isClosed =>
      transactions.isNotEmpty &&
      transactions.every((t) => t.status == TransactionStatus.closed);

  @override
  List<Object?> get props => [name, transactions];
}
