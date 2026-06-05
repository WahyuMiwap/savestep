import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _usernameFieldError;
  String? _emailFieldError;
  String? _passwordFieldError;
  String? _confirmPasswordFieldError;
  String _passwordStrength = ''; // '', 'lemah', 'sedang', 'kuat'

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  // Focus nodes
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

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

    // Sekuens pergerakan margin atas kartu putih menggunakan nilai abstrak (0.0 sampai 2.0)
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

    // Animasi fade-in memudar masuk di akhir sekuens
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    // Animasi perubahan warna background saat kartu meluncur turun
    _colorAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // REGISTER HANDLER
  Future<void> _handleRegister() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validasi input
    bool hasError = false;
    
    // Validasi Username
    if (username.isEmpty) {
      setState(() => _usernameFieldError = 'Wajib diisi');
      hasError = true;
    } else if (username.length < 3) {
      setState(() => _usernameFieldError = 'Username minimal 3 karakter');
      hasError = true;
    } else if (username.length > 10) {
      setState(() => _usernameFieldError = 'Username maksimal 10 karakter');
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameFieldError = 'Hanya huruf, angka, dan underscore (_)');
      hasError = true;
    } else {
      setState(() => _usernameFieldError = null);
    }

    // Validasi Email
    if (email.isEmpty) {
      setState(() => _emailFieldError = 'Wajib diisi');
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _emailFieldError = 'Format email tidak valid');
      hasError = true;
    } else if (!email.toLowerCase().endsWith('@gmail.com')) {
      setState(() => _emailFieldError = 'Hanya @gmail.com yang diizinkan');
      hasError = true;
    } else {
      setState(() => _emailFieldError = null);
    }

    // Validasi Password
    if (password.isEmpty) {
      setState(() => _passwordFieldError = 'Wajib diisi');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordFieldError = 'Password minimal 6 karakter');
      hasError = true;
    } else {
      setState(() => _passwordFieldError = null);
    }

    // Validasi Confirm Password
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordFieldError = 'Wajib diisi');
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordFieldError = 'Password dan Confirm Password tidak sama');
      hasError = true;
    } else {
      setState(() => _confirmPasswordFieldError = null);
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _usernameFieldError = null;
      _emailFieldError = null;
      _passwordFieldError = null;
      _confirmPasswordFieldError = null;
    });

    try {
      await _authService.register(
        email: email,
        password: password,
        username: username,
      );

      // Logout tanpa await (fire-and-forget) supaya tidak menambah delay
      _authService.logout();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage =
              'Pendaftaran berhasil! Cek inbox email kamu dan klik link verifikasi sebelum login.';
        });

        // Tunggu sebentar untuk user baca pesan, lalu pindah ke login
        await Future.delayed(const Duration(milliseconds: 1200));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(isFromRegister: true),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
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

  String _getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
    if (password.length >= 8 && hasUpper && hasDigit && hasSpecial) return 'kuat';
    if (password.length >= 6 && (hasUpper || hasDigit || hasSpecial)) return 'sedang';
    return 'lemah';
  }

  Widget _buildStrengthBar(double scale) {
    if (_passwordStrength.isEmpty) return const SizedBox.shrink();
    Color color;
    String label;
    int bars;
    switch (_passwordStrength) {
      case 'kuat':
        color = Colors.green;
        label = 'Kuat 💪';
        bars = 3;
        break;
      case 'sedang':
        color = Colors.orange;
        label = 'Sedang';
        bars = 2;
        break;
      default:
        color = Colors.red;
        label = 'Lemah';
        bars = 1;
    }
    return Padding(
      padding: EdgeInsets.only(top: 6 * scale),
      child: Row(
        children: [
          ...List.generate(3, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: i < bars ? color : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11 * scale, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required double scale,
    TextEditingController? controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? isHidden,
    VoidCallback? onToggleVisibility,
    bool isLastField = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.black,
          ),
        ),
        SizedBox(height: 8 * scale),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword ? (isHidden ?? true) : false,
          keyboardType: keyboardType,
          textInputAction: isLastField ? TextInputAction.done : TextInputAction.next,
          maxLength: maxLength,
          onChanged: onChanged,
          buildCounter: maxLength != null
              ? (_, {required currentLength, required isFocused, maxLength}) => null
              : null,
          onSubmitted: (_) {
            if (isLastField) {
              _handleRegister();
            } else {
              nextFocus?.requestFocus();
            }
          },
          style: TextStyle(fontSize: 14 * scale, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.35) ?? Colors.black.withOpacity(0.35),
              fontSize: 14 * scale,
            ),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.45) ?? Colors.black.withOpacity(0.45),
              size: 22 * scale,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      (isHidden ?? true) ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.45) ?? Colors.black.withOpacity(0.45),
                      size: 22 * scale,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16 * scale,
              horizontal: 16 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14 * scale),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : AppColors.primaryPurple,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height + mediaQuery.viewInsets.bottom;

    final double scaleWidth = screenWidth / 375.0;
    final double scaleHeight = screenHeight / 812.0;

    final double scale = (scaleWidth < scaleHeight ? scaleWidth : scaleHeight).clamp(0.75, 1.3);

    // Pre-build konten form
    final Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SUCCESS MESSAGE
        if (_successMessage != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12.5 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),
        ],

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
            child: Row(
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
          ),
          SizedBox(height: 16 * scale),
        ],

        _buildTextField(
          label: "Username",
          hint: "Username (maks. 10 karakter)",
          icon: Icons.person_outline,
          scale: scale,
          controller: _usernameController,
          focusNode: _usernameFocus,
          nextFocus: _emailFocus,
          maxLength: 10,
          errorText: _usernameFieldError,
        ),
        SizedBox(height: 16 * scale),

        _buildTextField(
          label: "Email",
          hint: "example@gmail.com",
          icon: Icons.mail_outline,
          scale: scale,
          controller: _emailController,
          focusNode: _emailFocus,
          nextFocus: _passwordFocus,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailFieldError,
        ),
        SizedBox(height: 16 * scale),

        _buildTextField(
          label: "Password",
          hint: "Password",
          icon: Icons.lock_outline,
          scale: scale,
          controller: _passwordController,
          focusNode: _passwordFocus,
          nextFocus: _confirmPasswordFocus,
          isPassword: true,
          isHidden: isPasswordHidden,
          errorText: _passwordFieldError,
          onChanged: (val) => setState(() => _passwordStrength = _getPasswordStrength(val)),
          onToggleVisibility: () {
            setState(() {
              isPasswordHidden = !isPasswordHidden;
            });
          },
        ),
        _buildStrengthBar(scale),
        SizedBox(height: 16 * scale),

        _buildTextField(
          label: "Confirm Password",
          hint: "Confirm Password",
          icon: Icons.lock_outline,
          scale: scale,
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          isPassword: true,
          isHidden: isConfirmPasswordHidden,
          isLastField: true,
          errorText: _confirmPasswordFieldError,
          onToggleVisibility: () {
            setState(() {
              isConfirmPasswordHidden = !isConfirmPasswordHidden;
            });
          },
        ),
        SizedBox(height: 20 * scale),

        // DAFTAR BUTTON
        Center(
          child: SizedBox(
            width: 220 * scale,
            height: 52 * scale,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
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
                      "Daftar",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),

        SizedBox(height: 16 * scale),

        // LOGIN LINK
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Sudah Punya Akun?",
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
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(isFromRegister: true),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * scale,
                ),
              ),
            ),
          ],
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
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final Color? topColor = ColorTween(
                        begin: AppColors.secondaryPurple,
                        end: AppColors.primaryPurple,
                      ).evaluate(_colorAnimation);
                      
                      final Color? bottomColor = ColorTween(
                        begin: AppColors.primaryPurple,
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
                              topColor ?? AppColors.secondaryPurple,
                              bottomColor ?? AppColors.primaryPurple,
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
                          "Register",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 34 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          "Senang bertemu denganmu\nBuat akun untuk memulai",
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
                      
                      // Posisi awal Register adalah posisi normal Login (0.28)
                      final double marginStart = constraints.maxHeight * 0.28;
                      final double marginUp = constraints.maxHeight * 0.05;
                      // Margin istirahat dibuat 0.26 agar card lebih pendek di atas dan tulisan header tidak tertutup
                      final double marginNormal = constraints.maxHeight * 0.26;

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
}
