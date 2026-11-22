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

  Future<void> signIn(WidgetTester tester) async {
    await tester.pumpWidget(EcoPayApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), 'jay@example.com');
    await tester.enterText(find.byKey(const Key('pin')), '1234');
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();
  }

  testWidgets('user sends USD to an EcoCash wallet and sees the receipt', (tester) async {
    await signIn(tester);

    await tester.tap(find.byKey(const Key('sendMoney')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('recipientName')), 'Rudo Chikore');
    await tester.enterText(find.byKey(const Key('recipientPhone')), '0772123456');
    await tester.enterText(find.byKey(const Key('amount')), '20');
    await tester.ensureVisible(find.byKey(const Key('getQuote')));
    await tester.tap(find.byKey(const Key('getQuote')));
    await tester.pumpAndSettle();

    // The confirm button is below the quote card, so scroll the form until
    // the list builds it.
    await tester.scrollUntilVisible(
      find.byKey(const Key('confirm')),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Money sent'), findsOneWidget);
    expect(find.text('Paid into the EcoCash wallet'), findsOneWidget);
  });

  testWidgets('user buys Econet airtime', (tester) async {
    await signIn(tester);

    await tester.tap(find.byKey(const Key('buyAirtime')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('airtimePhone')), '0782000111');
    await tester.ensureVisible(find.byKey(const Key('confirmAirtime')));
    await tester.tap(find.byKey(const Key('confirmAirtime')));
    await tester.pumpAndSettle();

    expect(find.text('Airtime sent'), findsOneWidget);
  });

  testWidgets('send form blocks a non Econet number for EcoCash', (tester) async {
    await signIn(tester);

    await tester.tap(find.byKey(const Key('sendMoney')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('recipientName')), 'Rudo Chikore');
    await tester.enterText(find.byKey(const Key('recipientPhone')), '0712345678');
    await tester.enterText(find.byKey(const Key('amount')), '20');
    await tester.ensureVisible(find.byKey(const Key('getQuote')));
    await tester.tap(find.byKey(const Key('getQuote')));
    await tester.pumpAndSettle();

    expect(find.text('EcoCash needs an Econet number starting with 077 or 078'), findsOneWidget);
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
