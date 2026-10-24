// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_firstapp/main.dart';
import 'package:flutter_firstapp/pages/splash_screen.dart';

void main() {
  testWidgets('Splash fits common Android screen sizes', (
    WidgetTester tester,
  ) async {
    const screenSizes = [Size(320, 568), Size(360, 800), Size(412, 915)];

    tester.view.devicePixelRatio = 1;
    for (final size in screenSizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const SiagaBanjirApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();

      const assetLabels = [
        'Foto udara kawasan banjir',
        'Logo rumah dan gelombang air',
        'Welcome to Flood alert',
      ];
      bool allSplashImagesExist() => assetLabels.every(
        (label) => find
            .byWidgetPredicate(
              (widget) => widget is Image && widget.semanticLabel == label,
            )
            .evaluate()
            .isNotEmpty,
      );
      for (var frame = 0; frame < 20 && !allSplashImagesExist(); frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Layar awal gagal dimuat'), findsNothing);
      for (final label in assetLabels) {
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Image && widget.semanticLabel == label,
          ),
          findsOneWidget,
          reason: 'Splash asset "$label" should be rendered at $size',
        );
      }
      expect(tester.takeException(), isNull, reason: 'Layout at $size');

      await tester.pumpWidget(const SizedBox.shrink());
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Splash waits for assets and completes before navigation', (
    WidgetTester tester,
  ) async {
    var didFinish = false;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinished: (_) => didFinish = true)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();

    final logoFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.semanticLabel == 'Logo rumah dan gelombang air',
    );
    for (var frame = 0; frame < 20 && logoFinder.evaluate().isEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Layar awal gagal dimuat'), findsNothing);
    expect(logoFinder, findsOneWidget);
    expect(didFinish, isFalse);

    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(didFinish, isTrue);
  });
}
