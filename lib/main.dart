import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/firebase_messaging_service.dart';
import 'navigation/app_route_factory.dart';
import 'pages/login_screen.dart';
import 'pages/home_screen.dart';
import 'pages/splash_screen.dart';
import 'pages/welcome_screen.dart';
import 'services/api_client.dart';
import 'services/location_service.dart';
import 'theme/app_colors.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SiagaBanjirApp());
}

class SiagaBanjirApp extends StatefulWidget {
  const SiagaBanjirApp({super.key});

  @override
  State<SiagaBanjirApp> createState() => _SiagaBanjirAppState();
}

class _SiagaBanjirAppState extends State<SiagaBanjirApp> {
  final _locationService = LocationService();
  final _apiClient = ApiClient();
  final _firebaseMessagingService = FirebaseMessagingService();
  final _navigatorKey = GlobalKey<NavigatorState>();

  Future<String?>? _firebaseInstallationIdFuture;

  @override
  void initState() {
    super.initState();

    _firebaseInstallationIdFuture = _initializeFirebaseMessaging();
  }

  Future<String?> _initializeFirebaseMessaging() async {
    try {
      return await _firebaseMessagingService.initialize();
    } catch (error) {
      debugPrint('Gagal menginisialisasi FCM: $error');
      return null;
    }
  }

  Future<void> _handleLogin(AuthenticatedUser account) async {
    try {
      final installationId = await _firebaseInstallationIdFuture;

      if (installationId != null) {
        await _apiClient.registerDeviceToken(
          token: account.token,
          installationId: installationId,
          platform: 'android',
        );

        debugPrint('Perangkat berhasil didaftarkan ke Laravel.');
      } else {
        debugPrint('Firebase Installation ID belum tersedia.');
      }
    } catch (error) {
      debugPrint('Gagal mendaftarkan perangkat: $error');
    }

    if (!mounted) return;

    _showWelcome(account);
  }

  void _showWelcome(AuthenticatedUser account) {
    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WelcomeScreen(
          account: account,
          onContinue: (welcomeContext) {
            Navigator.of(welcomeContext).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => HomeScreen(
                  account: account,
                  locationService: _locationService,
                  apiClient: _apiClient,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openLogin() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          authenticate:
              ({required String email, required String password}) async {
                return _apiClient.login(email: email, password: password);
              },
          register:
              ({
                required String name,
                required String email,
                required String password,
                required String passwordConfirmation,
              }) async {
                await _apiClient.register(
                  name: name,
                  email: email,
                  password: password,
                  passwordConfirmation: passwordConfirmation,
                );
              },
          onLogin: _handleLogin,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siaga Banjir Padang',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        return AppRouteFactory.generate(settings, onLogout: _openLogin);
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.navy,
          secondary: AppColors.teal,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F8FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          hintStyle: const TextStyle(color: AppColors.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.7),
          ),
        ),
      ),
      home: SplashScreen(
        onFinished: (context) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => LoginScreen(
                authenticate:
                    ({required String email, required String password}) async {
                      return _apiClient.login(email: email, password: password);
                    },
                register:
                    ({
                      required String name,
                      required String email,
                      required String password,
                      required String passwordConfirmation,
                    }) async {
                      await _apiClient.register(
                        name: name,
                        email: email,
                        password: password,
                        passwordConfirmation: passwordConfirmation,
                      );
                    },
                onLogin: _handleLogin,
              ),
            ),
          );
        },
      ),
    );
  }
}
