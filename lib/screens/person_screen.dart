import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/sheets/sheets_bloc.dart';
import '../models/debt_transaction.dart';
import '../models/person_debt.dart';
import 'add_transaction_screen.dart';

class PersonScreen extends StatefulWidget {
  final String personName;
  const PersonScreen({super.key, required this.personName});

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<SheetsBloc>()
        .add(SheetsFetchTransactions(widget.personName));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SheetsBloc, SheetsState>(
      listener: (context, state) {
        if (state is SheetsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        PersonDebt? person;
        if (state is SheetsTransactionsLoaded) person = state.person;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.personName),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<SheetsBloc>().add(
                      SheetsFetchTransactions(widget.personName,
                          forceRefresh: true),
                    ),
              ),
              if (person != null && !person.isClosed)
                TextButton(
                  onPressed: () => _confirmClose(context),
                  child: const Text('Close all',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Add transaction'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddTransactionScreen(personName: widget.personName),
              ),
            ),
          ),
          body: _buildBody(context, state, person),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, SheetsState state, PersonDebt? person) {
    if (state is SheetsLoading && person == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is SheetsError && person == null) {
      return Center(child: Text(state.message));
    }

    if (person == null) return const SizedBox.shrink();

    final balance = person.balance;
    final balanceColor =
        balance > 0 ? Colors.green : balance < 0 ? Colors.red : Colors.grey;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: balanceColor.withOpacity(0.1),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Balance', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: balanceColor),
              ),
              if (balance > 0)
                const Text('Owes you',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              if (balance < 0)
                const Text('You owe',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        if (state is SheetsLoading)
          const LinearProgressIndicator()
        else
          const SizedBox(height: 4),
        Expanded(
          child: person.transactions.isEmpty
              ? const Center(child: Text('No transactions yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  reverse: true,
                  itemCount: person.transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = person.transactions[i];
                    return _TransactionTile(transaction: t);
                  },
                ),
        ),
      ],
    );
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close all debts?'),
        content: Text(
            'This will mark all active transactions for ${widget.personName} as CLOSED.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<SheetsBloc>()
                  .add(SheetsCloseTransactions(widget.personName));
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final DebtTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isClosed = transaction.status == TransactionStatus.closed;
    final isGave = transaction.type == TransactionType.gave;
    final color = isClosed ? Colors.grey : isGave ? Colors.green : Colors.red;
    final sign = isGave ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(
          isGave ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Row(
        children: [
          Text(
            '$sign${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              decoration: isClosed ? TextDecoration.lineThrough : null,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isClosed
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isClosed ? 'CLOSED' : 'ACTIVE',
              style: TextStyle(
                fontSize: 11,
                color: isClosed ? Colors.grey : Colors.blue,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transaction.date,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (transaction.note.isNotEmpty)
            Text(transaction.note,
                style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
      isThreeLine: transaction.note.isNotEmpty,
    );
  }
}
