import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/exchange_rate_service.dart';
import 'services/transfer_repository.dart';
import 'state/auth_provider.dart';
import 'state/wallet_provider.dart';
import 'theme/app_theme.dart';

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
        theme: AppTheme.light(),
        builder: (context, child) => _LockLayer(child: child!),
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

/// Locks the app with the PIN screen whenever it is hidden or minimised.
class _LockLayer extends StatefulWidget {
  const _LockLayer({required this.child});

  final Widget child;

  @override
  State<_LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends State<_LockLayer> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => context.read<AuthProvider>().lock());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final showLock = auth.locked && auth.status == AuthStatus.signedIn;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showLock ? const LockScreen() : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
