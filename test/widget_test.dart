import 'package:ecopay/main.dart';
import 'package:ecopay/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the session in memory so widget tests do not need secure storage.
class FakeAuthService extends AuthService {
  String? _email;

  @override
  Future<String?> restoreSession() async => _email;

  @override
  Future<void> signIn({required String email, required String pin}) async {
    _email = email;
  }

  @override
  Future<void> signOut() async => _email = null;
}

void main() {
  testWidgets('user signs in and sees the wallet balance', (tester) async {
    await tester.pumpWidget(EcoPayApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'jay@example.com');
    await tester.enterText(find.byKey(const Key('pin')), '1234');
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('balance')), findsOneWidget);
    expect(find.text('USD 500.00'), findsOneWidget);
  });

  testWidgets('login form rejects a bad PIN', (tester) async {
    await tester.pumpWidget(EcoPayApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email')), 'jay@example.com');
    await tester.enterText(find.byKey(const Key('pin')), '12');
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pump();

    expect(find.text('Your PIN must be 4 digits'), findsOneWidget);
  });
}
