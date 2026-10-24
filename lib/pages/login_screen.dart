import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../utils/validators.dart';
import '../widgets/field_label.dart';
import '../widgets/press_scale.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authenticate,
    required this.onLogin,
  });

  final Future<AuthenticatedUser> Function({
    required String email,
    required String password,
  })?
  authenticate;
  final ValueChanged<AuthenticatedUser> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _entryController;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;
  bool _reducedMotion = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
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
    Widget child, {
    required double start,
    required double end,
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
                begin: const Offset(0, .035),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openSignUp() async {
    setState(() => _error = null);
    final registeredEmail = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const SignUpScreen()),
    );
    if (!mounted || registeredEmail == null) return;
    _emailController.text = registeredEmail;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final authenticate = widget.authenticate;
    if (authenticate == null) {
      setState(() => _error = 'Login belum dihubungkan pada tahap UI ini.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final account = await authenticate(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      widget.onLogin(account);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
      primaryTextTheme: Theme.of(context).primaryTextTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
    );
    return Theme(
      data: loginTheme,
      child: Scaffold(
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
                Image.asset(
                  'assets/login/flood_background.jpeg',
                  fit: BoxFit.cover,
                ),
                start: 0,
                end: .38,
                slide: false,
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 22,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 44).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 54).clamp(
                                0.0,
                                double.infinity,
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(17, 4, 9, 37),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .52),
                              borderRadius: BorderRadius.circular(29),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .16),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _entry(
                                      Center(
                                        child: Image.asset(
                                          'assets/splash/home_water_logo.png',
                                          width: 104,
                                          height: 112,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      start: .03,
                                      end: .39,
                                      scale: true,
                                    ),
                                    const SizedBox(height: 19),
                                    _entry(
                                      const Text(
                                        'Login',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF0B2E3B),
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      start: .14,
                                      end: .48,
                                    ),
                                    const SizedBox(height: 7),
                                    _entry(
                                      const Text(
                                        'Log in to your account to continue',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF0B2E3B),
                                          fontSize: 14,
                                        ),
                                      ),
                                      start: .2,
                                      end: .52,
                                    ),
                                    const SizedBox(height: 19),
                                    _entry(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 18),
                                            child: FieldLabel(
                                              'Email Address',
                                              color: Color(0xFF0B2E3B),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 58,
                                            ),
                                            child: TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              autofillHints: const [
                                                AutofillHints.email,
                                              ],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily:
                                                    'AtkinsonHyperlegible',
                                              ),
                                              decoration: _loginFieldDecoration(
                                                hint: 'Rani rahmadani',
                                                icon: Icons
                                                    .person_outline_rounded,
                                              ),
                                              validator: emailValidator,
                                              onChanged: (_) =>
                                                  setState(() => _error = null),
                                            ),
                                          ),
                                        ],
                                      ),
                                      start: .27,
                                      end: .59,
                                    ),
                                    const SizedBox(height: 5),
                                    _entry(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 18),
                                            child: FieldLabel(
                                              'Password',
                                              color: Color(0xFF0B2E3B),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 58,
                                            ),
                                            child: TextFormField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              textInputAction:
                                                  TextInputAction.done,
                                              autofillHints: const [
                                                AutofillHints.password,
                                              ],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily:
                                                    'AtkinsonHyperlegible',
                                              ),
                                              decoration:
                                                  _loginFieldDecoration(
                                                    hint: '*******',
                                                    icon: Icons
                                                        .lock_outline_rounded,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      tooltip: _obscurePassword
                                                          ? 'Tampilkan kata sandi'
                                                          : 'Sembunyikan kata sandi',
                                                      onPressed: () => setState(
                                                        () => _obscurePassword =
                                                            !_obscurePassword,
                                                      ),
                                                      icon: AnimatedSwitcher(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 240,
                                                            ),
                                                        child: Icon(
                                                          _obscurePassword
                                                              ? Icons
                                                                    .visibility_outlined
                                                              : Icons
                                                                    .visibility_off_outlined,
                                                          key: ValueKey(
                                                            _obscurePassword,
                                                          ),
                                                          size: 19,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              validator: (value) =>
                                                  (value == null ||
                                                      value.isEmpty)
                                                  ? 'Kata sandi wajib diisi.'
                                                  : null,
                                              onFieldSubmitted: (_) => _login(),
                                              onChanged: (_) =>
                                                  setState(() => _error = null),
                                            ),
                                          ),
                                        ],
                                      ),
                                      start: .35,
                                      end: .66,
                                    ),
                                    _entry(
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 14,
                                          right: 24,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 34,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) => setState(
                                                  () => _rememberMe =
                                                      value ?? false,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFF7D888A),
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Flexible(
                                              child: Text(
                                                'Remember me',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            const Spacer(),
                                            Flexible(
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: () {
                                                  ScaffoldMessenger.of(context)
                                                    ..hideCurrentSnackBar()
                                                    ..showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Halaman pemulihan kata sandi belum tersedia.',
                                                        ),
                                                      ),
                                                    );
                                                },
                                                child: Semantics(
                                                  button: true,
                                                  child: Text(
                                                    'Forgot Password?',
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      color: Color(0xFF0B2E3B),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      start: .43,
                                      end: .7,
                                    ),
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOut,
                                      child: _error == null
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                top: 5,
                                              ),
                                              child: Text(
                                                _error!,
                                                style: const TextStyle(
                                                  color: Color(0xFFB3261E),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 17),
                                    _entry(
                                      PressScale(
                                        child: SizedBox(
                                          height: 57,
                                          child: ElevatedButton(
                                            onPressed: _isSubmitting
                                                ? null
                                                : _login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF0B2E3B,
                                              ),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
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
                                                    'Login',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      start: .54,
                                      end: .82,
                                      scale: true,
                                    ),
                                    const Spacer(flex: 2),
                                    _entry(
                                      Row(
                                        children: [
                                          const Expanded(child: Divider()),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'Or continue with',
                                              style: TextStyle(
                                                color: Colors.blueGrey.shade600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: Divider()),
                                        ],
                                      ),
                                      start: .65,
                                      end: .89,
                                    ),
                                    const SizedBox(height: 23),
                                    _entry(
                                      Center(
                                        child: Semantics(
                                          label: 'Google Sign-In belum dikonfigurasi',
                                          child: ExcludeSemantics(
                                            child: CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.white,
                                              child: Image.asset(
                                                'assets/login/google_g_logo.png',
                                                width: 27,
                                                height: 27,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      start: .7,
                                      end: .93,
                                    ),
                                    const Spacer(flex: 5),
                                    _entry(
                                      Center(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          children: [
                                            const Text(
                                              'Donâ€™t have an account? ',
                                              style: TextStyle(
                                                color: Color(0xFF72797B),
                                                fontSize: 14,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _openSignUp,
                                              child: const Text(
                                                'Sign up',
                                                style: TextStyle(
                                                  color: Color(0xFF0B2E3B),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      start: .76,
                                      end: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _loginFieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    const borderColor = Color(0xFFD0D2D3);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB1B1B1),
        fontSize: 14,
        fontFamily: 'AtkinsonHyperlegible',
      ),
      prefixIcon: Icon(icon, color: Colors.black87, size: 23),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(color: Color(0xFF0B2E3B), width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(color: Color(0xFFB3261E), width: 1.4),
      ),
    );
  }
}
