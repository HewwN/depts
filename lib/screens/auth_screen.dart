import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../blocs/auth/auth_bloc.dart';
import 'home_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSpreadsheetReady) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthSignedIn) {
          return _SpreadsheetPickerScreen(spreadsheets: state.spreadsheets);
        }

        return _SignInScreen();
      },
    );
  }
}

class _SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              'Debt Tracker',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Sync with Google Sheets',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthSignInRequested()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpreadsheetPickerScreen extends StatelessWidget {
  final List<drive.File> spreadsheets;
  const _SpreadsheetPickerScreen({required this.spreadsheets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Spreadsheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                context.read<AuthBloc>().add(AuthSignOutRequested()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: spreadsheets.isEmpty
                ? const Center(child: Text('No spreadsheets found.'))
                : ListView.builder(
                    itemCount: spreadsheets.length,
                    itemBuilder: (context, i) {
                      final file = spreadsheets[i];
                      return ListTile(
                        leading: const Icon(Icons.table_chart),
                        title: Text(file.name ?? 'Unnamed'),
                        onTap: () {
                          context.read<AuthBloc>().add(
                                AuthSpreadsheetSelected(file.id!),
                              );
                        },
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create "Debt_Tracker_DB"'),
              onPressed: () {
                context.read<AuthBloc>().add(
                      const AuthSpreadsheetCreated('Debt_Tracker_DB'),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
