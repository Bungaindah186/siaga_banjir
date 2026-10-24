import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firstapp/pages/signup_screen.dart';

void main() {
  testWidgets(
    'Sign Up fits common phone sizes without a permanent backend notice',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      for (final size in const [
        Size(320, 568),
        Size(360, 800),
        Size(402, 874),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Sign Up'), findsNWidgets(2));
        expect(find.byType(TextFormField), findsNWidgets(4));
        expect(find.byType(Checkbox), findsOneWidget);
        expect(
          find.text('Registrasi belum dihubungkan pada tahap UI ini.'),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: 'Layout at $size');

        await tester.pumpWidget(const SizedBox.shrink());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('Sign Up waves stay anchored when the keyboard opens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    final screen = MaterialApp(home: const SignUpScreen());
    await tester.pumpWidget(screen);
    await tester.pumpAndSettle();

    final wave = find.byKey(const ValueKey('signup-waves'));
    expect(wave, findsOneWidget);
    final topWithoutKeyboard = tester.getTopLeft(wave).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpWidget(screen);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(wave).dy, closeTo(topWithoutKeyboard, 1));
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Sign Up dimensions follow the supplied mobile reference', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    final firstField = tester.getRect(fields.at(0));
    final secondField = tester.getRect(fields.at(1));
    final thirdField = tester.getRect(fields.at(2));
    final fourthField = tester.getRect(fields.at(3));
    final button = tester.getRect(
      find.widgetWithText(ElevatedButton, 'Sign Up'),
    );

    expect(firstField.width, closeTo(318, 1));
    expect(firstField.height, closeTo(52, 1));
    expect(secondField.top - firstField.bottom, closeTo(17, 1));
    expect(thirdField.top - secondField.bottom, closeTo(17, 1));
    expect(fourthField.top - thirdField.bottom, closeTo(17, 1));
    expect(button.width, closeTo(318, 1));
    expect(button.height, 53);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Sign Up validates locally without registering to a server', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(ElevatedButton, 'Sign Up');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rani Rahmadani');
    await tester.enterText(fields.at(1), 'rani@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(
      find.text('Registrasi belum dihubungkan pada tahap UI ini.'),
      findsOneWidget,
    );
    expect(find.text('Pendaftaran berhasil.'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
