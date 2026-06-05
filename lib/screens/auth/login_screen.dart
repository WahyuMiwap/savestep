import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../dashboard/main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromRegister;
  
  const LoginScreen({
    super.key,
    this.isFromRegister = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isPasswordHidden = true;
  bool _isLoading = false;
  bool _isResendingVerification = false;
  String? _errorMessage;
  String? _emailFieldError;
  String? _passwordFieldError;
  bool _isEmailNotVerified = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  // Focus nodes untuk dismiss keyboard
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _controller;
  late Animation<double> _marginSequence;
  late Animation<double> _fadeAnimation;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Durasi dipercepat agar UX lebih responsif
      duration: const Duration(milliseconds: 1400),
    );

    _marginSequence = TweenSequence<double>([
      // Stage 0: Tahan sesaat untuk crossfade
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 25,
      ),
      // Stage 1: Naik (lebih cepat)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 30,
      ),
      // Stage 2: Turun
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 2.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      // Stage 3: Hold
      TweenSequenceItem(
        tween: ConstantTween<double>(2.0),
        weight: 15,
      ),
    ]).animate(_controller);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _colorAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // LOGIN HANDLER
  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validasi input
    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailFieldError = 'Wajib diisi');
      hasError = true;
    } else if (!email.toLowerCase().endsWith('@gmail.com')) {
      setState(() => _emailFieldError = 'Hanya @gmail.com yang diizinkan');
      hasError = true;
    } else {
      setState(() => _emailFieldError = null);
    }
    
    if (password.isEmpty) {
      setState(() => _passwordFieldError = 'Wajib diisi');
      hasError = true;
    } else {
      setState(() => _passwordFieldError = null);
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailFieldError = null;
      _passwordFieldError = null;
    });

    try {
      await _authService.login(email: email, password: password);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
          // Cek apakah error karena email belum diverifikasi
          _isEmailNotVerified = errorMsg.contains('belum diverifikasi');
        });
      }
    }
  }

  // SOCIAL LOGIN HANDLER
  Future<void> _handleSocialLogin({required bool isGoogle}) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isGoogle) {
        final credential = await _authService.signInWithGoogle();
        // Jika null berarti user membatalkan dialog Google
        if (credential == null) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      } else {
        await _authService.signInAsGuest();
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    // Mengambil tinggi layar yang sebenarnya (tidak terpengaruh saat keyboard muncul)
    final screenHeight = mediaQuery.size.height + mediaQuery.viewInsets.bottom;

    // Menghitung rasio skala berdasarkan referensi device standar (iPhone X: 375x812)
    final double scaleWidth = screenWidth / 375.0;
    final double scaleHeight = screenHeight / 812.0;

    // Menggunakan skala terkecil antara lebar atau tinggi layar agar konten selalu muat.
    final double scale = (scaleWidth < scaleHeight ? scaleWidth : scaleHeight).clamp(0.75, 1.3);

    // Pre-build konten form agar tidak di-render ulang setiap frame animasi (mengatasi animasi patah-patah)
    final Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ERROR MESSAGE
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20 * scale),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12.5 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Tombol kirim ulang verifikasi (hanya muncul kalau error verifikasi)
                if (_isEmailNotVerified) ...[
                  SizedBox(height: 8 * scale),
                  GestureDetector(
                    onTap: _isResendingVerification
                        ? null
                        : () async {
                            setState(() => _isResendingVerification = true);
                            try {
                              // Login sementara untuk kirim ulang verifikasi
                              await _authService.login(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );
                            } catch (_) {}
                            try {
                              await _authService.resendVerificationEmail();
                              await _authService.logout();
                            } catch (_) {}
                            if (mounted) {
                              setState(() {
                                _isResendingVerification = false;
                                _errorMessage =
                                    'Email verifikasi telah dikirim ulang. Cek inbox kamu.';
                                _isEmailNotVerified = false;
                              });
                            }
                          },
                    child: Text(
                      _isResendingVerification
                          ? 'Mengirim...'
                          : 'Kirim ulang email verifikasi →',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16 * scale),
        ],

        // EMAIL LABEL
        Text(
          "Email",
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.black,
          ),
        ),
        SizedBox(height: 8 * scale),

        // EMAIL FIELD
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          style: TextStyle(fontSize: 14 * scale, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "example@gmail.com",
            errorText: _emailFieldError,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.35) ?? Colors.black.withOpacity(0.35),
              fontSize: 14 * scale,
            ),
            prefixIcon: Icon(
              Icons.mail_outline,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.45) ?? Colors.black.withOpacity(0.45),
              size: 22 * scale,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16 * scale,
              horizontal: 16 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: _emailFieldError != null ? Colors.red : Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: _emailFieldError != null ? Colors.red : Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: _emailFieldError != null ? Colors.red : AppColors.primaryPurple,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 16 * scale),

        // PASSWORD LABEL
        Text(
          "Password",
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.black,
          ),
        ),
        SizedBox(height: 8 * scale),

        // PASSWORD FIELD
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: isPasswordHidden,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          style: TextStyle(fontSize: 14 * scale, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "Password",
            errorText: _passwordFieldError,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.35) ?? Colors.black.withOpacity(0.35),
              fontSize: 14 * scale,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.45) ?? Colors.black.withOpacity(0.45),
              size: 22 * scale,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  isPasswordHidden = !isPasswordHidden;
                });
              },
              icon: Icon(
                isPasswordHidden
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.45) ?? Colors.black.withOpacity(0.45),
                size: 22 * scale,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16 * scale,
              horizontal: 16 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: _passwordFieldError != null ? Colors.red : Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: _passwordFieldError != null ? Colors.red : Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: _passwordFieldError != null ? Colors.red : AppColors.primaryPurple,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 4 * scale),

        // FORGOT PASSWORD
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ForgotPasswordScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Text(
              "Lupa Password?",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
                fontSize: 12 * scale,
              ),
            ),
          ),
        ),
        SizedBox(height: 6 * scale),

        // LOGIN BUTTON
        SizedBox(
          width: double.infinity,
          height: 52 * scale,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPurple,
              disabledBackgroundColor: AppColors.buttonPurple.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * scale),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 22 * scale,
                    width: 22 * scale,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    "Login",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 20 * scale),

        // DIVIDER
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
              ),
              child: Text(
                "Atau Masuk Dengan",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4) ?? Colors.black.withOpacity(0.4),
                  fontSize: 12 * scale,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * scale),

        // SOCIAL LOGIN
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            socialButton(
              imagePath: 'assets/images/google_logo.png',
              label: "Google",
              scale: scale,
              onTap: () => _handleSocialLogin(isGoogle: true),
            ),
            SizedBox(width: 28 * scale),
            socialButton(
              imagePath: 'assets/images/guest_icon.png',
              label: "Guest",
              scale: scale,
              onTap: () => _handleSocialLogin(isGoogle: false),
            ),
          ],
        ),

        // Memberikan ruang untuk area bawah tanpa menggunakan Spacer() agar lebih optimal untuk performa animasi
        SizedBox(height: 35 * scale),

        // REGISTER
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Belum Punya Akun?",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.55) ?? Colors.black.withOpacity(0.55),
                fontSize: 13 * scale,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const RegisterScreen();
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Text(
                "Daftar",
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * scale,
                ),
              ),
            ),
          ],
        ),

        // COPYRIGHT
        Center(
          child: Text(
            "© 2025 SaveStep. All rights reserved.",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.35) ?? Colors.black.withOpacity(0.35),
              fontSize: 11 * scale,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Stack(
                children: [
                  // 1. PURPLE HEADER (BACKGROUND)
                  // Latar berubah warna saat kartu meluncur turun
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final Color? topColor = ColorTween(
                        begin: const Color(0xFF9C6FDE),
                        end: AppColors.primaryPurple,
                      ).evaluate(_colorAnimation);
                      
                      final Color? bottomColor = ColorTween(
                        begin: const Color(0xFF6A3FB5),
                        end: AppColors.background,
                      ).evaluate(_colorAnimation);

                      return Container(
                        width: double.infinity,
                        height: constraints.maxHeight,
                        padding: EdgeInsets.only(
                          top: constraints.maxHeight * 0.10,
                          left: 28 * scale,
                          right: 28 * scale,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              topColor ?? const Color(0xFF9C6FDE),
                              bottomColor ?? const Color(0xFF6A3FB5),
                            ],
                          ),
                        ),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Login",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 34 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          "Selamat datang kembali, user\nSilakan masuk untuk melanjutkan",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14 * scale,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. WHITE CARD (FOREGROUND)
                  // Menggunakan margin animasi untuk keamanan UI, memastikan tidak ada garis/bolong di bagian bawah
                  AnimatedBuilder(
                    animation: _marginSequence,
                    builder: (context, child) {
                      final double animValue = _marginSequence.value;
                      
                      // Menghitung posisi awal
                      final double marginStart;
                      if (widget.isFromRegister) {
                        marginStart = constraints.maxHeight * 0.26;
                      } else {
                        marginStart = mediaQuery.size.height - 393.0 + mediaQuery.padding.top;
                      }
                      
                      final double marginUp = constraints.maxHeight * 0.10;
                      final double marginNormal = constraints.maxHeight * 0.28;

                      double currentMargin;
                      if (animValue <= 1.0) {
                        currentMargin = marginStart + (marginUp - marginStart) * animValue;
                      } else {
                        currentMargin = marginUp + (marginNormal - marginUp) * (animValue - 1.0);
                      }
                      
                      return Container(
                        margin: EdgeInsets.only(top: currentMargin),
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - currentMargin).clamp(0.0, double.infinity),
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(42 * scale),
                            topRight: Radius.circular(42 * scale),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 28 * scale,
                            right: 28 * scale,
                            top: 35 * scale,
                            bottom: 16 * scale,
                          ),
                          child: AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, childForm) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: childForm,
                              );
                            },
                            child: child, // formContent caching
                          ),
                        ),
                      );
                    },
                    child: formContent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget socialButton({
    required String imagePath,
    required String label,
    required double scale,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16 * scale),
          onTap: _isLoading ? null : onTap,
          child: Container(
            height: 52 * scale,
            width: 52 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(10 * scale),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7) ?? Colors.black.withOpacity(0.7),
            fontSize: 12 * scale,
          ),
        ),
      ],
    );
  }
}