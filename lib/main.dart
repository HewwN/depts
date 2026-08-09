import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/sheets/sheets_bloc.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/google_sheets_service.dart';

void main() {
  runApp(const DebtTrackerApp());
}

class DebtTrackerApp extends StatelessWidget {
  const DebtTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GoogleSheetsService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GoogleSheetsService>.value(value: service),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) =>
                AuthBloc(service)..add(AuthSignInSilentlyRequested()),
          ),
          BlocProvider<SheetsBloc>(
            create: (_) => SheetsBloc(service),
          ),
        ],
        child: MaterialApp(
          title: 'Debt Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSpreadsheetReady) {
                return const HomeScreen();
              }
              return const AuthScreen();
            },
          ),
        ),
      ),
    );
  }
}
