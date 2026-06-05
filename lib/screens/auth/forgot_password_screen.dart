import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _emailFieldError;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

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

    if (hasError) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailFieldError = null;
    });

    try {
      await _authService.sendPasswordReset(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
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
    final screenHeight = mediaQuery.size.height + mediaQuery.viewInsets.bottom;

    final double scaleWidth = screenWidth / 375.0;
    final double scaleHeight = screenHeight / 812.0;
    final double scale =
        (scaleWidth < scaleHeight ? scaleWidth : scaleHeight).clamp(0.75, 1.3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double marginNormal = constraints.maxHeight * 0.28;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                children: [
                  // 1. PURPLE HEADER
                  Container(
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
                          AppColors.secondaryPurple,
                          AppColors.primaryPurple,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        SizedBox(height: 24 * scale),
                        Text(
                          "Reset\nPassword",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 36 * scale,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. WHITE CARD
                  Container(
                    margin: EdgeInsets.only(top: marginNormal),
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - marginNormal)
                          .clamp(0.0, double.infinity),
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
                        top: 40 * scale,
                        bottom: 16 * scale,
                      ),
                      child: _emailSent
                          ? _buildSuccessState(scale)
                          : _buildFormState(scale),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // STATE: Form input email
  Widget _buildFormState(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Masukkan email kamu untuk menerima\nlink reset password",
          style: TextStyle(
            fontSize: 14 * scale,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7) ?? Colors.black.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        SizedBox(height: 12 * scale),

        // INFO NOTE
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16 * scale,
                color: AppColors.primaryPurple,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  'Fitur ini hanya untuk akun yang didaftarkan dengan email & password. '
                  'Jika kamu login dengan Google, reset password melalui akun Google kamu.',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.primaryPurple.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * scale),

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
                Icon(Icons.error_outline,
                    color: Colors.red.shade700, size: 20 * scale),
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
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleResetPassword(),
          style: TextStyle(fontSize: 14 * scale, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "example@gmail.com",
            errorText: _emailFieldError,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.35) ?? Colors.black.withValues(alpha: 0.35),
              fontSize: 14 * scale,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.45) ?? Colors.black.withValues(alpha: 0.45),
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
        SizedBox(height: 24 * scale),

        // KIRIM BUTTON
        SizedBox(
          width: double.infinity,
          height: 52 * scale,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPurple,
              disabledBackgroundColor:
                  AppColors.buttonPurple.withValues(alpha: 0.6),
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
                    "Kirim Link Reset",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        SizedBox(height: 16 * scale),

        // BACK TO LOGIN
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Kembali ke Login",
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
                fontSize: 13 * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STATE: Setelah email berhasil dikirim
  Widget _buildSuccessState(double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20 * scale),

        // SUCCESS ICON
        Container(
          padding: EdgeInsets.all(24 * scale),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 56 * scale,
            color: AppColors.primaryPurple,
          ),
        ),
        SizedBox(height: 24 * scale),

        Text(
          "Email Terkirim! 📬",
          style: TextStyle(
            fontSize: 22 * scale,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.black,
          ),
        ),
        SizedBox(height: 12 * scale),

        Text(
          "Link reset password telah dikirim ke:\n${_emailController.text.trim()}",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14 * scale,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6) ?? Colors.black.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          "Cek inbox atau folder spam kamu.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13 * scale,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.45) ?? Colors.black.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: 32 * scale),

        // KEMBALI KE LOGIN
        SizedBox(
          width: double.infinity,
          height: 52 * scale,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPurple,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * scale),
              ),
            ),
            child: Text(
              "Kembali ke Login",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SizedBox(height: 16 * scale),

        // KIRIM ULANG
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
                _emailController.clear();
              });
            },
            child: Text(
              "Kirim ke email lain",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5) ?? Colors.black.withValues(alpha: 0.5),
                fontSize: 13 * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
