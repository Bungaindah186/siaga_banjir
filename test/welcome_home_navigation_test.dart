import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firstapp/navigation/app_route_factory.dart';
import 'package:flutter_firstapp/pages/home_screen.dart';
import 'package:flutter_firstapp/pages/welcome_screen.dart';
import 'package:flutter_firstapp/services/api_client.dart';
import 'package:flutter_firstapp/services/location_service.dart';

void main() {
  const account = AuthenticatedUser(
    id: 1,
    name: 'Rina',
    email: 'rina@example.com',
    token: '',
  );

  testWidgets('Welcome switches gate continue, while skip always continues', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
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

    final continueButton = find.widgetWithText(
      FilledButton,
      'Izinkan dan lanjut',
    );
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    final continueDecoration = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('welcome-continue-gradient')),
    );
    expect(
      (continueDecoration.decoration as BoxDecoration).gradient,
      isA<LinearGradient>(),
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    final skipButton = find.text('Nanti saja');
    expect(
      tester.getRect(skipButton).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
    await tester.tap(skipButton);
    await tester.pumpAndSettle();
    expect(find.text('Halo, Rina'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Home calendar and bottom navigation open destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouteFactory.generate,
        home: HomeScreen(
          account: account,
          locationService: LocationService(),
          apiClient: ApiClient(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Kalender'));
    await tester.pumpAndSettle();
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.textContaining('Kalender kesiapsiagaan'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evakuasi'));
    await tester.pumpAndSettle();
    expect(find.text('Evakuasi'), findsNWidgets(2));
    expect(find.text('Mulai rute'), findsOneWidget);
    expect(find.textContaining('Informasi Jalan'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Home key dimensions follow the Figma phone frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(account: account, locationService: LocationService()),
      ),
    );
    await tester.pumpAndSettle();

    final alert = tester.getRect(find.byKey(const ValueKey('home-alert-card')));
    final weather = tester.getRect(
      find.byKey(const ValueKey('home-weather-card')),
    );
    final map = tester.getRect(find.byKey(const ValueKey('home-map-preview')));
    final siaga = tester.getRect(
      find.byKey(const ValueKey('home-area-tunggul')),
    );
    final aman = tester.getRect(
      find.byKey(const ValueKey('home-area-air-tawar')),
    );
    final sos = tester.getRect(find.byKey(const ValueKey('home-sos-button')));

    expect(alert.left, closeTo(38, 1));
    expect(alert.top, closeTo(147, 1));
    expect(alert.height, closeTo(114, 1));
    expect(weather.left, closeTo(41, 1));
    expect(weather.top, closeTo(279, 1));
    expect(weather.height, closeTo(66, 1));
    expect(map.left, closeTo(41, 1));
    expect(map.top, closeTo(365, 1));
    expect(map.height, closeTo(182, 1));
    expect(siaga.left, closeTo(41, 1));
    expect(siaga.top, closeTo(592, 2));
    expect(siaga.height, closeTo(43, 1));
    expect(aman.top, closeTo(644, 2));
    expect(sos.width, closeTo(125, 1));
    expect(sos.height, closeTo(54, 1));
    expect(sos.top, closeTo(700, 3));
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'Notifications open river details and SOS requires confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouteFactory.generate,
          home: HomeScreen(
            account: account,
            locationService: LocationService(),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Notifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Ketinggian air meningkat'), findsOneWidget);
      await tester.tap(find.text('Lihat ketinggian sungai').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Tren 6 jam'), findsOneWidget);

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi SOS'), findsOneWidget);
      await tester.tap(find.text('Lanjutkan'));
      await tester.pump();
      expect(
        find.text('Pengiriman SOS belum terhubung dan tidak dikirim.'),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
