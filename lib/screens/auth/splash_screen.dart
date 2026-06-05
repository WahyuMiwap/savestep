import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import '../dashboard/main_screen.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300), 
      value: 1.0
    );
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Tampil 3 detik sesuai request user
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authService = AuthService();
    final user = authService.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    if (hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        )
      );
    } else {
      // Fade out teks
      await _fadeCtrl.reverse();
      
      if (!mounted) return;
      // Lanjut onboarding (yang akan memainkan animasi card putih naik)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9C6FDE), Color(0xFF6A3FB5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Name (Tanpa Icon Dompet)
              const Text(
                'SaveStep',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola Keuangan Lebih Mudah',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Spacer untuk ganti loading indicator (karena loading bisa merusak look transisi)
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}