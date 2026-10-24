import 'package:flutter/material.dart';

import 'pages/login_screen.dart';
import 'pages/splash_screen.dart';
import 'pages/welcome_screen.dart';
import 'theme/app_colors.dart';

void main() => runApp(const SiagaBanjirApp());

class SiagaBanjirApp extends StatefulWidget {
  const SiagaBanjirApp({super.key});

  @override
  State<SiagaBanjirApp> createState() => _SiagaBanjirAppState();
}

class _SiagaBanjirAppState extends State<SiagaBanjirApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siaga Banjir Padang',
      debugShowCheckedModeBanner: false,
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
        onFinished: (context) => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => LoginScreen(
              authenticate: null,
              onLogin: (account) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => WelcomeScreen(account: account),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
