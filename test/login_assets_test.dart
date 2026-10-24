import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firstapp/pages/login_screen.dart';
import 'package:flutter_firstapp/pages/signup_screen.dart';

void main() {
  testWidgets('Login loads Atkinson Hyperlegible and Google logo assets', (
    tester,
  ) async {
    final regularFont = await rootBundle.load(
      'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
    );
    final boldFont = await rootBundle.load(
      'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
    );
    final googleLogo = await rootBundle.load('assets/login/google_g_logo.png');
    expect(regularFont.lengthInBytes, greaterThan(0));
    expect(boldFont.lengthInBytes, greaterThan(0));
    expect(googleLogo.lengthInBytes, greaterThan(0));

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authenticate: null, onLogin: (_) {})),
    );
    await tester.pump();

    final titleStyle = tester
        .renderObject<RenderParagraph>(find.text('Login').first)
        .text
        .style;
    expect(titleStyle?.fontFamily, 'AtkinsonHyperlegible');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login opens Sign Up and system back returns to Login', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authenticate: null, onLogin: (_) {})),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.text('Login'), findsWidgets);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Login validates without making an authentication request', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authenticate: null, onLogin: (_) {})),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'rani@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(
      find.text('Login belum dihubungkan pada tahap UI ini.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
