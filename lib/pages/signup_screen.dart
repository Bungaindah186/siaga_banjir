import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../utils/validators.dart';
import '../widgets/press_scale.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.register});

  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  })?
  register;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final AnimationController _entryController;
  bool _acceptedPrivacy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _reducedMotion = false;
  bool _isSubmitting = false;

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _confirmationController.text.isNotEmpty &&
      _passwordController.text == _confirmationController.text;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _reducedMotion = true;
        _entryController.value = 1;
      } else {
        _entryController.forward();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_reducedMotion) return;
    if (state == AppLifecycleState.resumed &&
        !_entryController.isCompleted &&
        !_entryController.isAnimating) {
      _entryController.forward();
    } else if (state != AppLifecycleState.resumed &&
        _entryController.isAnimating) {
      _entryController.stop(canceled: false);
    }
  }

  Widget _entry(
    Widget child,
    double start,
    double end, {
    bool scale = false,
    bool slide = true,
  }) {
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    Widget result = slide
        ? FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          )
        : FadeTransition(opacity: animation, child: child);
    if (scale) {
      result = ScaleTransition(
        scale: Tween<double>(begin: .97, end: 1).animate(animation),
        child: result,
      );
    }
    return result;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    if (!_acceptedPrivacy) {
      _showMessage('Setujui persyaratan privasi untuk melanjutkan.');
      return;
    }
    final register = widget.register;
    if (register == null) {
      _showMessage('Penyimpanan akun lokal belum tersedia.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_emailController.text.trim().toLowerCase());
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFFB2B2B2),
      fontSize: 14,
      fontFamily: 'AtkinsonHyperlegible',
    ),
    prefixIcon: Icon(icon, color: Colors.black, size: 22),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(19),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(19),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(19),
      borderSide: const BorderSide(color: Color(0xFF0B2E3B), width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(19),
      borderSide: const BorderSide(color: Color(0xFFFFD1CC), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(19),
      borderSide: const BorderSide(color: Color(0xFFFFD1CC), width: 1.2),
    ),
  );

  Widget _signupField({required Widget child}) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30002A36),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final signupTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
      primaryTextTheme: Theme.of(context).primaryTextTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
    );
    return Theme(
      data: signupTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF147F91),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF0B2E3B),
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF0B2E3B),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _entry(
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF126A7C), Color(0xFF148BA0)],
                    ),
                  ),
                ),
                0,
                .32,
                slide: false,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -keyboardInset,
                height: 150,
                child: _entry(
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/login/flood_background.jpeg',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                      const ColoredBox(
                        color: Color.fromRGBO(255, 255, 255, .55),
                      ),
                    ],
                  ),
                  0,
                  .38,
                  slide: false,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                height: 380,
                bottom: 1 - keyboardInset,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0,85 * (1 - _entryController.value)),
                      child: child,
                    ),
                    child: const CustomPaint(
                      key: ValueKey('signup-waves'),
                      painter: _SignupWavesPainter(),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;

                  final horizontalInset = (screenWidth * 0.1045)
                    .clamp(24.0, 48.0);

                  final topPadding = (screenHeight * 0.055)
                    .clamp(24.0, 48.0);

                  final titleGap = (screenHeight * 0.035)
                    .clamp(18.0, 31.0);

                  final fieldGap = (screenHeight * 0.019)
                    .clamp(10.0, 17.0);

                  final checkboxGap = (screenHeight * 0.012)
                    .clamp(8.0, 11.0);

                  final buttonGap = (screenHeight * 0.034)
                    .clamp(18.0, 30.0);

                  final buttonHeight = (screenHeight * 0.061)
                    .clamp(48.0, 56.0);
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalInset,
                        topPadding,
                        horizontalInset,
                        30,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _entry(
                                  const Text(
                                    'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  .08,
                                  .34,
                                ),
                                SizedBox(height: titleGap),
                                _entry(
                                  _signupField(
                                    child: TextFormField(
                                      controller: _nameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontFamily: 'AtkinsonHyperlegible',
                                        fontSize: 14,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: 'Rani rahmadani',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      validator: (value) =>
                                          (value == null ||
                                              value.trim().length < 2)
                                          ? 'Nama lengkap wajib diisi.'
                                          : null,
                                    ),
                                  ),
                                  .18,
                                  .43,
                                ),
                                SizedBox(height: fieldGap),
                                _entry(
                                  _signupField(
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontFamily: 'AtkinsonHyperlegible',
                                        fontSize: 14,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: 'Ranirahmadani@gmail.com',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: emailValidator,
                                    ),
                                  ),
                                  .26,
                                  .5,
                                ),
                                SizedBox(height: fieldGap),
                                _entry(
                                  _signupField(
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontFamily: 'AtkinsonHyperlegible',
                                        fontSize: 14,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: '*******',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Tampilkan kata sandi'
                                              : 'Sembunyikan kata sandi',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              key: ValueKey(_obscurePassword),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          (value == null || value.length < 8)
                                          ? 'Kata sandi minimal 8 karakter.'
                                          : null,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  .34,
                                  .58,
                                ),
                                SizedBox(height: fieldGap),
                                _entry(
                                  _signupField(
                                    child: TextFormField(
                                      controller: _confirmationController,
                                      obscureText: _obscureConfirmation,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(
                                        fontFamily: 'AtkinsonHyperlegible',
                                        fontSize: 14,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: '*******',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 240,
                                              ),
                                              transitionBuilder:
                                                  (child, animation) =>
                                                      ScaleTransition(
                                                        scale: animation,
                                                        child: child,
                                                      ),
                                              child: _passwordsMatch
                                                  ? const Icon(
                                                      Icons.check_circle,
                                                      key: ValueKey('valid'),
                                                      color: Color(0xFF79B93B),
                                                      size: 21,
                                                    )
                                                  : const SizedBox(
                                                      key: ValueKey('empty'),
                                                      width: 0,
                                                    ),
                                            ),
                                            IconButton(
                                              tooltip: _obscureConfirmation
                                                  ? 'Tampilkan konfirmasi kata sandi'
                                                  : 'Sembunyikan konfirmasi kata sandi',
                                              onPressed: () => setState(
                                                () => _obscureConfirmation =
                                                    !_obscureConfirmation,
                                              ),
                                              icon: Icon(
                                                _obscureConfirmation
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Konfirmasi kata sandi wajib diisi.';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Konfirmasi kata sandi tidak sama.';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setState(() {}),
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                  ),
                                  .42,
                                  .66,
                                ),
                                SizedBox(height: checkboxGap),
                                _entry(
                                  Padding(
                                    padding: const EdgeInsets.only(left: 11),
                                    child: SizedBox(
                                      height: 32,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: Checkbox(
                                              value: _acceptedPrivacy,
                                              onChanged: (value) => setState(
                                                () => _acceptedPrivacy =
                                                    value ?? false,
                                              ),
                                              fillColor:
                                                  const WidgetStatePropertyAll(
                                                    Colors.white,
                                                  ),
                                              checkColor: const Color(
                                                0xFF0B2E3B,
                                              ),
                                              side: const BorderSide(
                                                color: Colors.white,
                                                width: 1.2,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          const Expanded(
                                            child: Text(
                                              'I agree to the privacy terms.',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  .52,
                                  .76,
                                ),
                                SizedBox(height: buttonGap),
                                _entry(
                                  PressScale(
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0B2E3B,
                                          ),
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shadowColor: const Color(0x66001624),
                                          shape: const StadiumBorder(),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox.square(
                                                dimension: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  .62,
                                  .9,
                                  scale: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupWavesPainter extends CustomPainter {
  const _SignupWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const tealColor = Color(0xFF12809A);
    const navyColor = Color(0xFF0B2E3B);

    Paint wavePaint(double start, double end) => Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tealColor, navyColor],
      ).createShader(
        Rect.fromLTWH(0, height * start, width, height * (end - start)),
      );

    final upper = wavePaint(.15, .45);
    final teal = wavePaint(.36, .76);


    // Wave contours and vertical gradients follow the supplied Sign Up image.
    final first = Path()
      ..moveTo(0, height * .155)
      ..cubicTo(
        width * .12,
        height * .15,
        width * .21,
        height * .255,
        width * .30,
        height * .335,
      )
      ..cubicTo(
        width * .40,
        height * .17,
        width * .45,
        height * .145,
        width * .52,
        height * .17,
      )
      ..cubicTo(
        width * .65,
        height * .18,
        width * .72,
        height * .275,
        width * .78,
        height * .31,
      )
      ..cubicTo(
        width * .88,
        height * .265,
        width * .95,
        height * .20,
        width,
        height * .245,
      )
      ..lineTo(width, height * .435)
      ..cubicTo(
        width * .87,
        height * .435,
        width * .68,
        height * .38,
        width * .50,
        height * .38,
      )
      ..cubicTo(
        width * .34,
        height * .39,
        width * .20,
        height * .55,
        0,
        height * .435,
      )
      ..close();
    canvas.drawPath(first, upper);

    final second = Path()
      ..moveTo(0, height * .435)
      ..cubicTo(
        width * .12,
        height * .40,
        width * .21,
        height * .52,
        width * .30,
        height * .545,
      )
      ..cubicTo(
        width * .43,
        height * .40,
        width * .46,
        height * .36,
        width * .52,
        height * .38,
      )
      ..cubicTo(
        width * .65,
        height * .40,
        width * .76,
        height * .53,
        width * .89,
        height * .47,
      )
      ..lineTo(width, height * .44)
      ..lineTo(width, height * .63)
      ..cubicTo(
        width * .90,
        height * .66,
        width * .82,
        height * .59,
        width * .74,
        height * .60,
      )
      ..cubicTo(
        width * .56,
        height * .62,
        width * .42,
        height * .87,
        width * .25,
        height * .81,
      )
      ..cubicTo(
        width * .16,
        height * .77,
        width * .08,
        height * .72,
        0,
        height * .76,
      )
      ..close();
    canvas.drawPath(second, teal);

}
  @override
  bool shouldRepaint(covariant _SignupWavesPainter oldDelegate) => false;
}
