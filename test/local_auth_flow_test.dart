import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firstapp/pages/home_screen.dart';
import 'package:flutter_firstapp/pages/login_screen.dart';
import 'package:flutter_firstapp/pages/signup_screen.dart';
import 'package:flutter_firstapp/pages/welcome_screen.dart';
import 'package:flutter_firstapp/services/api_client.dart';
import 'package:flutter_firstapp/services/location_service.dart';

void main() {
  testWidgets('Sign Up then valid Login opens Welcome and Home', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    final navigatorKey = GlobalKey<NavigatorState>();
    final accounts = <String, ({String name, String password})>{};

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: LoginScreen(
          register:
              ({
                required name,
                required email,
                required password,
                required passwordConfirmation,
              }) async {
                accounts[email] = (name: name, password: password);
              },
          authenticate: ({required email, required password}) async {
            final account = accounts[email];
            if (account == null || account.password != password) {
              throw const ApiException('Email atau kata sandi salah.');
            }
            return AuthenticatedUser(
              id: 1,
              name: account.name,
              email: email,
              token: '',
            );
          },
          onLogin: (account) {
            navigatorKey.currentState!.pushReplacement<void, void>(
              MaterialPageRoute<void>(
                builder: (_) => WelcomeScreen(
                  account: account,
                  onContinue: (context) =>
                      Navigator.of(context).pushReplacement<void, void>(
                        MaterialPageRoute<void>(
                          builder: (_) => HomeScreen(
                            account: account,
                            locationService: LocationService(),
                            apiClient: ApiClient(),
                          ),
                        ),
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    final signUpFields = find.byType(TextFormField);
    await tester.enterText(signUpFields.at(0), 'Rani Rahmadani');
    await tester.enterText(signUpFields.at(1), 'rani@example.com');
    await tester.enterText(signUpFields.at(2), 'safePassword123');
    await tester.enterText(signUpFields.at(3), 'safePassword123');
    await tester.tap(find.byType(Checkbox));
    final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    expect(accounts.keys, contains('rani@example.com'));
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('Akun disimpan di perangkat ini. Silakan login.'),
      findsOneWidget,
    );

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'rani@example.com');
    await tester.enterText(loginFields.at(1), 'wrongPassword');
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(loginFields.at(1), 'safePassword123');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Nanti saja'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
