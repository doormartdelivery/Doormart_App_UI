import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import 'user_home_screen.dart';
import 'signup_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeDeep = Color(0xFFD44010);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF7F7F8);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A2E);
const _kTextMid = Color(0xFF8A8A9A);
const _kBorder = Color(0xFFE5E5EA);
const _kGreen = Color(0xFF22C55E);
const _kRed = Color(0xFFEF4444);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Tab ──────────────────────────────────────────────────────────────────
  late final TabController _tabCtrl =
      TabController(length: 2, vsync: this);

  // ── Form keys ─────────────────────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // ── Login controllers ──────────────────────────────────────────────────────
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // ── Signup controllers ─────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _obscureLogin = true;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _loading = false;
  String? _error;

  // ── Entry animation ────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _tabCtrl.dispose();
    _entryCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Password strength ──────────────────────────────────────────────────────
  int _strength(String pwd) {
    if (pwd.isEmpty) return 0;
    var s = 0;
    if (pwd.length >= 6) s++;
    if (pwd.length >= 10 &&
        RegExp(r'[A-Z]').hasMatch(pwd) &&
        RegExp(r'[0-9]').hasMatch(pwd)) s++;
    if (pwd.length >= 8 &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) s++;
    return s.clamp(0, 3);
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().loginWithPassword(
        email: _loginEmailCtrl.text.trim(),
        password: _loginPassCtrl.text,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushNamedAndRemoveUntil(
        UserHomeScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    setState(() => _error = null);
    if (!_signupFormKey.currentState!.validate()) return;
    if (!_agreed) {
      setState(() =>
          _error = 'Please agree to the Terms of Service and Privacy Policy');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().register(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        addressLabel: 'Home',
        addressLine1: '',
        city: '',
        pincode: '',
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushNamedAndRemoveUntil(
        UserHomeScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Orange hero header ───────────────────────────────────
            _HeroHeader(tabCtrl: _tabCtrl),

            // ── Scrollable form body ─────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: TabBarView(
                    controller: _tabCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // ── Login tab ─────────────────────────────────
                      _LoginTab(
                        formKey: _loginFormKey,
                        emailCtrl: _loginEmailCtrl,
                        passCtrl: _loginPassCtrl,
                        obscure: _obscureLogin,
                        onToggleObscure: () =>
                            setState(() => _obscureLogin = !_obscureLogin),
                        loading: _loading,
                        error: _error,
                        onLogin: _login,
                        onGoRegister: () => _tabCtrl.animateTo(1),
                      ),

                      // ── Sign up tab ───────────────────────────────
                      _SignupTab(
                        formKey: _signupFormKey,
                        nameCtrl: _nameCtrl,
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        passCtrl: _passCtrl,
                        confirmPassCtrl: _confirmPassCtrl,
                        obscurePass: _obscurePass,
                        obscureConfirm: _obscureConfirm,
                        onTogglePass: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        onToggleConfirm: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        agreed: _agreed,
                        onToggleAgreed: () =>
                            setState(() => _agreed = !_agreed),
                        loading: _loading,
                        error: _error,
                        strength: _strength(_passCtrl.text),
                        onPasswordChanged: () => setState(() {}),
                        onSignUp: _signUp,
                        onGoLogin: () => _tabCtrl.animateTo(0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.tabCtrl});
  final TabController tabCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF26522), Color(0xFFD44010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 16),

                // Back + logo row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16),
                        ),
                      ),
                      const Spacer(),
                      // Logo badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Title
                const Text(
                  'Doormart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fresh groceries • Delivered in 10 minutes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Tab bar — sits at bottom of header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: tabCtrl,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: _kOrange,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Log In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 0),

                // White curve at bottom of header
                Container(
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Login Tab ────────────────────────────────────────────────────────────────

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.error,
    required this.onLogin,
    required this.onGoRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final String? error;
  final VoidCallback onLogin;
  final VoidCallback onGoRegister;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            _WelcomeCard(
              emoji: '👋',
              title: 'Welcome back!',
              subtitle: 'Login to order fresh groceries',
            ),

            const SizedBox(height: 24),

            _FieldLabel('Email address'),
            const SizedBox(height: 8),
            _Field(
              controller: emailCtrl,
              hint: 'you@example.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 16),

            _FieldLabel('Password'),
            const SizedBox(height: 8),
            _Field(
              controller: passCtrl,
              hint: 'Enter your password',
              icon: Icons.lock_rounded,
              obscure: obscure,
              suffix: _EyeToggle(
                  obscure: obscure, onToggle: onToggleObscure),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _kOrange,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Forgot password?',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),

            if (error != null) ...[
              const SizedBox(height: 4),
              _ErrorBanner(message: error!),
            ],

            const SizedBox(height: 20),

            _PrimaryBtn(
              label: 'Login to Doormart',
              icon: Icons.login_rounded,
              loading: loading,
              onTap: onLogin,
            ),

            const SizedBox(height: 20),

            const _OrDivider(),

            const SizedBox(height: 20),

            // Social buttons
            Row(
              children: [
                Expanded(
                  child: _SocialBtn(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Google',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialBtn(
                    icon: Icons.apple_rounded,
                    label: 'Apple',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _SwitchPrompt(
              question: "Don't have an account? ",
              action: 'Sign Up',
              onTap: onGoRegister,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Up Tab ──────────────────────────────────────────────────────────────

class _SignupTab extends StatelessWidget {
  const _SignupTab({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passCtrl,
    required this.confirmPassCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.agreed,
    required this.onToggleAgreed,
    required this.loading,
    required this.error,
    required this.strength,
    required this.onPasswordChanged,
    required this.onSignUp,
    required this.onGoLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final bool agreed;
  final VoidCallback onToggleAgreed;
  final bool loading;
  final String? error;
  final int strength;
  final VoidCallback onPasswordChanged;
  final VoidCallback onSignUp;
  final VoidCallback onGoLogin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(
              emoji: '✨',
              title: 'Create account',
              subtitle: 'Join Doormart for fast grocery delivery',
            ),

            const SizedBox(height: 24),

            // ── Full name ────────────────────────────────────────────
            _FieldLabel('Full name'),
            const SizedBox(height: 8),
            _Field(
              controller: nameCtrl,
              hint: 'Jane Doe',
              icon: Icons.person_rounded,
              keyboardType: TextInputType.name,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your full name';
                }
                if (v.trim().length < 2) return 'Name is too short';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Email ────────────────────────────────────────────────
            _FieldLabel('Email address'),
            const SizedBox(height: 8),
            _Field(
              controller: emailCtrl,
              hint: 'you@example.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Phone ────────────────────────────────────────────────
            _FieldLabel('Phone number'),
            const SizedBox(height: 8),
            _Field(
              controller: phoneCtrl,
              hint: '+91 98765 43210',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your phone number';
                }
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Password ─────────────────────────────────────────────
            _FieldLabel('Password'),
            const SizedBox(height: 8),
            _Field(
              controller: passCtrl,
              hint: 'At least 6 characters',
              icon: Icons.lock_rounded,
              obscure: obscurePass,
              suffix: _EyeToggle(
                  obscure: obscurePass, onToggle: onTogglePass),
              onChanged: (_) => onPasswordChanged(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Create a password';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            // Password strength bar
            if (passCtrl.text.isNotEmpty)
              _StrengthBar(strength: strength),

            const SizedBox(height: 16),

            // ── Confirm password ──────────────────────────────────────
            _FieldLabel('Confirm password'),
            const SizedBox(height: 8),
            _Field(
              controller: confirmPassCtrl,
              hint: 'Re-enter your password',
              icon: Icons.lock_outlined,
              obscure: obscureConfirm,
              suffix: _EyeToggle(
                  obscure: obscureConfirm, onToggle: onToggleConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Confirm your password';
                }
                if (v != passCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Terms ─────────────────────────────────────────────────
            _TermsRow(agreed: agreed, onToggle: onToggleAgreed),

            if (error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: error!),
            ],

            const SizedBox(height: 20),

            _PrimaryBtn(
              label: 'Create Account',
              icon: Icons.person_add_rounded,
              loading: loading,
              onTap: onSignUp,
            ),

            const SizedBox(height: 24),

            _SwitchPrompt(
              question: 'Already have an account? ',
              action: 'Log In',
              onTap: onGoLogin,
            ),

            const SizedBox(height: 20),

            // Perks strip
            const _PerksStrip(),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Card ─────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
  final String emoji, title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _kOrange.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF26522), Color(0xFFD44010)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12.5, color: _kTextMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextDark,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─── Input field ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        onChanged: onChanged,
        validator: validator,
        style: const TextStyle(
          color: _kTextDark,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: _kTextMid.withValues(alpha: 0.6), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(icon, color: _kOrange, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 46),
          suffixIcon: suffix,
          errorStyle: const TextStyle(
            color: _kRed,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Eye toggle ───────────────────────────────────────────────────────────────

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscure, required this.onToggle});
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure
            ? Icons.visibility_off_rounded
            : Icons.visibility_rounded,
        color: _kTextMid,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}

// ─── Password strength bar ────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (strength) {
      1 => ('Weak', _kRed),
      2 => ('Fair', const Color(0xFFF59E0B)),
      _ => ('Strong', _kGreen),
    };

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (i) {
              final filled = i < strength;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? color : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Terms row ────────────────────────────────────────────────────────────────

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.agreed, required this.onToggle});
  final bool agreed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              gradient: agreed
                  ? const LinearGradient(
                      colors: [Color(0xFFF26522), Color(0xFFD44010)])
                  : null,
              color: agreed ? null : _kCard,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: agreed ? Colors.transparent : _kBorder,
                width: 1.5,
              ),
              boxShadow: agreed
                  ? [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.30),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: agreed
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    color: _kTextMid, fontSize: 12.5, height: 1.5),
                children: [
                  TextSpan(text: "I agree to Doormart's "),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                        color: _kOrange, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                        color: _kOrange, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, color: _kRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _kRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Or divider ───────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or continue with',
            style: TextStyle(
                fontSize: 13,
                color: _kTextMid.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500),
          ),
        ),
        const Expanded(child: Divider(color: _kBorder)),
      ],
    );
  }
}

// ─── Social button ────────────────────────────────────────────────────────────

class _SocialBtn extends StatefulWidget {
  const _SocialBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _s =
      Tween<double>(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 22, color: _kTextDark),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _s =
      Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => _c.forward(),
      onTapUp: widget.loading
          ? null
          : (_) {
              _c.reverse();
              widget.onTap();
            },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF26522), Color(0xFFD44010)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.loading
                ? const Color(0xFFE0E0E0)
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.loading
                ? []
                : [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Switch prompt ────────────────────────────────────────────────────────────

class _SwitchPrompt extends StatelessWidget {
  const _SwitchPrompt({
    required this.question,
    required this.action,
    required this.onTap,
  });
  final String question, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13.5),
            children: [
              TextSpan(
                  text: question,
                  style: const TextStyle(color: _kTextMid)),
              TextSpan(
                text: action,
                style: const TextStyle(
                  color: _kOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Perks strip (signup only) ────────────────────────────────────────────────

class _PerksStrip extends StatelessWidget {
  const _PerksStrip();

  @override
  Widget build(BuildContext context) {
    const perks = [
      (Icons.bolt_rounded, '10 min\nDelivery'),
      (Icons.verified_rounded, 'Fresh\nProducts'),
      (Icons.local_offer_rounded, 'Best\nPrices'),
      (Icons.support_agent_rounded, '24/7\nSupport'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _kOrange.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Doormart?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: perks.map((p) {
              return Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(p.$1, color: _kOrange, size: 20),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    p.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                      height: 1.3,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
