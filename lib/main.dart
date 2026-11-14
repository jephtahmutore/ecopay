import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/exchange_rate_service.dart';
import 'services/transfer_repository.dart';
import 'state/auth_provider.dart';
import 'state/wallet_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcoPayApp());
}

class EcoPayApp extends StatelessWidget {
  const EcoPayApp({super.key, this.authService});

  /// Allows tests to inject a fake auth service.
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService ?? AuthService())..restore(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(
            rates: ExchangeRateService(),
            repository: TransferRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'EcoPay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4C5C)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows the login screen or the wallet depending on the session.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const HomeScreen();
    }
  }
}
