import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/session_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const double _maxContentWidth = 430;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF020817) : const Color(0xFFF2F6FD);

  List<Color> get _pageGradientColors => _isDarkMode
      ? const [Color(0xFF020817), Color(0xFF0F172A)]
      : const [Color(0xFFDBEAFE), Color(0xFFF6F9FF)];

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF253041) : const Color(0xFFE2E8F0);

  Color get _surfaceMutedColor =>
      _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  Color get _mutedTextColor =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  List<BoxShadow> get _surfaceShadows => _isDarkMode
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ];

  List<BoxShadow> get _heroShadows => [
    BoxShadow(
      color: const Color(
        0xFF1D4ED8,
      ).withValues(alpha: _isDarkMode ? 0.18 : 0.24),
      blurRadius: _isDarkMode ? 20 : 24,
      offset: const Offset(0, 12),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = await auth.login(email, password);

    if (!mounted) return;

    final bool success = result['success'] == true;

    if (success) {
      if (_rememberMe) {
        await SessionStorage.saveRememberedEmail(email);
      } else {
        await SessionStorage.clearRememberedCredentials();
      }

      final user = result['user'] as Map<String, dynamic>? ?? {};
      await auth.setUser(user);

      if (currentRoute != '/' && mounted) {
        navigator.pushReplacementNamed('/');
      }
    } else {
      // Login gagal dengan animasi shake
      _showErrorSnackBar(result['message']?.toString() ?? 'Login gagal');
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final rememberMeEnabled = await SessionStorage.isRememberMeEnabled();
    final rememberedCredentials =
        await SessionStorage.getRememberedCredentials();

    if (!mounted) {
      return;
    }

    setState(() {
      _rememberMe = rememberMeEnabled;
      _emailController.text = rememberedCredentials['email'] ?? '';
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Validators
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _pageGradientColors,
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -40,
            child: _buildBackgroundOrb(
              size: 220,
              color: const Color(
                0xFF2563EB,
              ).withValues(alpha: _isDarkMode ? 0.18 : 0.10),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _buildBackgroundOrb(
              size: 160,
              color: const Color(
                0xFF14B8A6,
              ).withValues(alpha: _isDarkMode ? 0.14 : 0.08),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -50,
            child: _buildBackgroundOrb(
              size: 220,
              color: const Color(
                0xFF1D4ED8,
              ).withValues(alpha: _isDarkMode ? 0.16 : 0.08),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeroSection(),
                          const SizedBox(height: 16),
                          _buildLoginCard(isLoading),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Version 1.0.0',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _mutedTextColor.withValues(
                                  alpha: _isDarkMode ? 0.82 : 0.72,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? const [Color(0xFF1D4ED8), Color(0xFF172554)]
              : const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: _heroShadows,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -32,
            right: -24,
            child: _buildBackgroundOrb(
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -44,
            left: -20,
            child: _buildBackgroundOrb(
              size: 100,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secure Access',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue into your HR workspace with the same account and process you already use.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _surfaceShadows,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _primaryTextColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use your email and password to access the app.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.45,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF2563EB,
                    ).withValues(alpha: _isDarkMode ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Mobile',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode
                          ? Colors.white
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryTextColor,
              ),
              validator: _validateEmail,
              enabled: !isLoading,
              decoration: _buildInputDecoration(
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryTextColor,
              ),
              validator: _validatePassword,
              enabled: !isLoading,
              decoration: _buildInputDecoration(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _secondaryTextColor,
                    size: 20,
                  ),
                  onPressed: !isLoading
                      ? () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildRememberForgotRow(isLoading),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logging in...',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow(bool isLoading) {
    final rememberRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: !isLoading
              ? (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                }
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          activeColor: const Color(0xFF2563EB),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          'Remember me',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _mutedTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final forgotButton = TextButton(
      onPressed: !isLoading ? _showForgotPasswordDialog : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: const Color(0xFF2563EB),
      ),
      child: Text(
        'Forgot Password?',
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rememberRow,
              Align(alignment: Alignment.centerRight, child: forgotButton),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [rememberRow, forgotButton],
        );
      },
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: _secondaryTextColor,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: _secondaryTextColor.withValues(alpha: 0.75),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _surfaceBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.6),
      ),
      filled: true,
      fillColor: _surfaceMutedColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        titlePadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Color(0xFF2563EB),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Forgot Password',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact your administrator to reset your password.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: _secondaryTextColor,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
