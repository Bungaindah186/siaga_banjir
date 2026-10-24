import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final void Function(BuildContext context) onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backgroundFade;
  late final Animation<double> _whiteOverlay;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  Timer? _reducedMotionTimer;
  bool _assetsRequested = false;
  bool _assetsReady = false;
  bool _animationStarted = false;
  bool _animationStartScheduled = false;
  bool _navigated = false;
  bool _reducedMotion = false;
  String? _assetLoadError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener(_handleAnimationStatus);
    _backgroundFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .5, curve: Curves.easeOut),
    );
    _whiteOverlay = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.12, .62, curve: Curves.easeInOut),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.28, .72, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: .92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(.28, .72, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.28, .72, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.53, .9, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.53, .9, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsRequested) return;
    _assetsRequested = true;
    _loadSplashAssets();
  }

  Future<void> _loadSplashAssets() async {
    const assetPaths = [
      'assets/splash/flood_background.png',
      'assets/splash/home_water_logo.png',
      'assets/splash/welcome_title.png',
    ];
    final errors = <String, Object>{};

    try {
      final pendingLoads = assetPaths.map((path) {
        return precacheImage(
          AssetImage(path),
          context,
          onError: (error, stackTrace) => errors[path] = error,
        );
      });
      await Future.wait(pendingLoads);
    } catch (error) {
      if (mounted) setState(() => _assetLoadError = error.toString());
      return;
    }

    if (!mounted) return;
    if (errors.isNotEmpty) {
      setState(() {
        _assetLoadError = errors.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
      });
      return;
    }

    setState(() => _assetsReady = true);
  }

  void _startAnimationAfterFirstSizedFrame() {
    if (_animationStarted || _animationStartScheduled) return;
    _animationStartScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationStartScheduled = false;
      if (!mounted || !_assetsReady || _animationStarted) return;
      _animationStarted = true;

      if (MediaQuery.disableAnimationsOf(context)) {
        _reducedMotion = true;
        _controller.value = 1;
        _reducedMotionTimer = Timer(const Duration(milliseconds: 500), _finish);
      } else {
        _controller.forward();
      }
    });
  }

  void _retryAssetLoad() {
    setState(() {
      _assetsRequested = true;
      _assetsReady = false;
      _assetLoadError = null;
    });
    _loadSplashAssets();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _reducedMotion) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
  }

  void _finish() {
    if (!mounted || _navigated) return;
    _navigated = true;
    widget.onFinished(context);
  }

  @override
  void dispose() {
    _reducedMotionTimer?.cancel();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0B2E3B),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: _assetLoadError != null
            ? _SplashAssetError(
                details: _assetLoadError!,
                onRetry: _retryAssetLoad,
              )
            : !_assetsReady
            ? const _SplashLoading()
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                    return const _SplashLoading();
                  }
                  _startAnimationAfterFirstSizedFrame();

                  final logoWidth = (constraints.maxWidth * .622).clamp(
                    0.0,
                    250.0,
                  );
                  final titleWidth = (constraints.maxWidth * .592).clamp(
                    0.0,
                    238.0,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFFF4F6F4)),
                      FadeTransition(
                        opacity: _backgroundFade,
                        child: Image.asset(
                          'assets/splash/flood_background.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          semanticLabel: 'Foto udara kawasan banjir',
                          errorBuilder: (context, error, stackTrace) =>
                              _SplashAssetError(
                                details: 'Gagal menampilkan foto latar: $error',
                                onRetry: _retryAssetLoad,
                              ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _whiteOverlay,
                        builder: (context, child) => ColoredBox(
                          color: Colors.white.withValues(
                            alpha: _whiteOverlay.value * .08,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: FractionalTranslation(
                          translation: const Offset(0, -.045),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FadeTransition(
                                  opacity: _logoFade,
                                  child: SlideTransition(
                                    position: _logoSlide,
                                    child: ScaleTransition(
                                      scale: _logoScale,
                                      child: Image.asset(
                                        'assets/splash/home_water_logo.png',
                                        width: logoWidth,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        semanticLabel:
                                            'Logo rumah dan gelombang air',
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => _SplashAssetError(
                                              details:
                                                  'Gagal menampilkan logo: $error',
                                              onRetry: _retryAssetLoad,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FadeTransition(
                                  opacity: _titleFade,
                                  child: SlideTransition(
                                    position: _titleSlide,
                                    child: Image.asset(
                                      'assets/splash/welcome_title.png',
                                      width: titleWidth,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      semanticLabel: 'Welcome to Flood alert',
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => _SplashAssetError(
                                            details:
                                                'Gagal menampilkan judul: $error',
                                            onRetry: _retryAssetLoad,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8DE1D6)),
            SizedBox(height: 18),
            Text(
              'Memuat tampilan awalâ€¦',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashAssetError extends StatelessWidget {
  const _SplashAssetError({required this.details, required this.onRetry});

  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFFFFB4AB),
                size: 42,
              ),
              const SizedBox(height: 16),
              const Text(
                'Layar awal gagal dimuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                details,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD8E5ED), fontSize: 12),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF8DE1D6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
