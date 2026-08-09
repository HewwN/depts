import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/sheets/sheets_bloc.dart';
import '../models/person_debt.dart';
import 'person_screen.dart';
import 'add_person_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showClosed = false;

  @override
  void initState() {
    super.initState();
    context.read<SheetsBloc>().add(const SheetsFetchPeople());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        actions: [
          IconButton(
            icon: Icon(_showClosed ? Icons.visibility_off : Icons.visibility),
            tooltip: _showClosed ? 'Hide closed' : 'Show closed',
            onPressed: () => setState(() => _showClosed = !_showClosed),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<SheetsBloc>()
                .add(const SheetsFetchPeople(forceRefresh: true)),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                context.read<AuthBloc>().add(AuthSignOutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add person'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPersonScreen()),
        ),
      ),
      body: BlocBuilder<SheetsBloc, SheetsState>(
        builder: (context, state) {
          if (state is SheetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SheetsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SheetsBloc>()
                        .add(const SheetsFetchPeople(forceRefresh: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SheetsPeopleLoaded) {
            final people = _showClosed
                ? state.people
                : state.people.where((p) => !p.isClosed).toList();

            if (people.isEmpty) {
              return const Center(
                child: Text('No people yet. Add someone!'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context
                  .read<SheetsBloc>()
                  .add(const SheetsFetchPeople(forceRefresh: true)),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: people.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => _PersonTile(person: people[i]),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final PersonDebt person;
  const _PersonTile({required this.person});

  @override
  Widget build(BuildContext context) {
    final balance = person.balance;
    final isClosed = person.isClosed;
    final color = isClosed
        ? Colors.grey
        : balance > 0
            ? Colors.green
            : balance < 0
                ? Colors.red
                : Colors.blueGrey;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        person.name,
        style: isClosed
            ? const TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
      subtitle: isClosed
          ? const Text('Closed')
          : Text(
              balance > 0
                  ? 'Owes me: ${balance.toStringAsFixed(2)}'
                  : balance < 0
                      ? 'I owe: ${(-balance).toStringAsFixed(2)}'
                      : 'Balanced',
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonScreen(personName: person.name),
        ),
      ),
    );
  }
}
