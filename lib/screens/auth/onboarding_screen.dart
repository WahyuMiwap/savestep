import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Intro animation (card slide up + content fade in)
  late AnimationController _introController;
  late Animation<double> _cardAnimation;
  late Animation<double> _contentAnimation;

  // Fade animation for card text & icon on page change
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Background gradient animation on page change
  late AnimationController _bgController;
  late Animation<Color?> _bgTopColor;
  late Animation<Color?> _bgBottomColor;

  // Gradient palettes per page
  final List<List<Color>> _gradients = [
    [const Color(0xFF9C6FDE), const Color(0xFF6A3FB5)],
    [const Color(0xFF7B5EA7), const Color(0xFF4A2D8F)],
    [const Color(0xFF8B55C9), const Color(0xFF5B2FA8)],
    [const Color(0xFFAD7FE8), const Color(0xFF7845C0)],
  ];

  List<Color> get _currentGradient => _gradients[_currentIndex];
  List<Color> get _prevGradient =>
      _gradients[_prevIndex < 0 ? 0 : _prevIndex];
  int _prevIndex = -1;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.account_balance_wallet_outlined,
      "title": "Kelola Keuangan Lebih Mudah",
      "description":
          "Pantau setiap pengeluaran dan pemasukan dengan presisi dalam satu dashboard pintar.",
    },
    {
      "icon": Icons.savings_outlined,
      "title": "Capai Target Tabunganmu",
      "description":
          "Monitor progress tabungan dan capai tujuan finansialmu lebih cepat.",
    },
    {
      "icon": Icons.calendar_month_outlined,
      "title": "Jangan Lewatkan Jadwal Penting",
      "description":
          "Kelola deadline, tugas, dan aktivitas penting secara teratur.",
    },
    {
      "icon": Icons.auto_graph_outlined,
      "title": "Semua Dalam Satu Aplikasi",
      "description":
          "SaveStep membantu kamu tetap produktif dan finansial lebih terorganisir.",
    },
  ];

  @override
  void initState() {
    super.initState();

    // Intro animation
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _cardAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
    );
    _contentAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.78, 1, curve: Curves.easeOut),
    );
    _introController.forward();

    // Fade controller for content inside card + icon
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // BG color tween controller
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgTopColor = ColorTween(
      begin: _gradients[0][0],
      end: _gradients[0][0],
    ).animate(_bgController);
    _bgBottomColor = ColorTween(
      begin: _gradients[0][1],
      end: _gradients[0][1],
    ).animate(_bgController);
  }

  @override
  void dispose() {
    _introController.dispose();
    _fadeController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int index) async {
    if (index == _currentIndex) return;
    _prevIndex = _currentIndex;

    // Start fade out
    await _fadeController.reverse();

    // Animate background gradient
    _bgTopColor = ColorTween(
      begin: _prevGradient[0],
      end: _gradients[index][0],
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _bgBottomColor = ColorTween(
      begin: _prevGradient[1],
      end: _gradients[index][1],
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _bgController.reset();
    _bgController.forward();

    setState(() {
      _currentIndex = index;
    });

    // Fade back in
    await _fadeController.forward();
  }

  void _onHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200 && _currentIndex < onboardingData.length - 1) {
      // Swipe left → next
      _goToPage(_currentIndex + 1);
    } else if (velocity > 200 && _currentIndex > 0) {
      // Swipe right → previous
      _goToPage(_currentIndex - 1);
    }
  }

  void _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    
    // Transisi langsung tanpa fade agar animasi card naik-turun dari LoginScreen
    // terlihat menyatu (seamless) dari OnboardingScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenH = size.height;
    final double screenW = size.width;

    // Responsive scaling
    final double cardPaddingH = screenW * 0.07;
    final double cardPaddingV = screenH * 0.035;
    final double iconSize = (screenH * 0.12).clamp(80.0, 130.0);
    final double iconContainerSize = (screenH * 0.25).clamp(160.0, 260.0);
    final double titleFontSize = (screenW * 0.068).clamp(20.0, 30.0);
    final double descFontSize = (screenW * 0.038).clamp(13.0, 16.0);
    final double btnHeight = (screenH * 0.072).clamp(50.0, 65.0);
    final double btnFontSize = (screenW * 0.045).clamp(15.0, 20.0);
    final double titleBoxH = (screenH * 0.1).clamp(70.0, 100.0);
    final double descBoxH = (screenH * 0.11).clamp(80.0, 110.0);
    final double indicatorSpacerH = (screenH * 0.035).clamp(20.0, 40.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onHorizontalDragEnd: _onHorizontalDrag,
        child: Stack(
          children: [
            // --- Animated background gradient ---
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _bgTopColor.value ?? _currentGradient[0],
                        _bgBottomColor.value ?? _currentGradient[1],
                      ],
                    ),
                  ),
                );
              },
            ),

            // --- Main content ---
            SafeArea(
              child: Column(
                children: [
                  // Top spacer
                  SizedBox(height: screenH * 0.04),

                  // --- Icon area (animated, fades on change) ---
                  Expanded(
                    flex: 4,
                    child: FadeTransition(
                      opacity: _contentAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Center(
                          child: SizedBox(
                            height: iconContainerSize,
                            width: iconContainerSize,
                            child: Container(
                              key: ValueKey(_currentIndex),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).cardColor.withOpacity(0.10),
                              ),
                              child: Center(
                                child: Icon(
                                  onboardingData[_currentIndex]["icon"],
                                  size: iconSize,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Floating card ---
                  AnimatedBuilder(
                    animation: _cardAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _cardAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 350 * (1 - _cardAnimation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: cardPaddingH,
                        vertical: cardPaddingV,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(42),
                          topRight: Radius.circular(42),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _contentAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- Page indicator dots ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                onboardingData.length,
                                (index) => GestureDetector(
                                  onTap: () => _goToPage(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    height: 8,
                                    width: _currentIndex == index ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color: _currentIndex == index
                                          ? AppColors.primaryPurple
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: indicatorSpacerH),

                            // --- Title (fade on change) ---
                            SizedBox(
                              height: titleBoxH,
                              child: Center(
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: Text(
                                    onboardingData[_currentIndex]["title"],
                                    key: ValueKey(
                                        '${_currentIndex}_title'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // --- Description (fade on change) ---
                            SizedBox(
                              height: descBoxH,
                              child: Center(
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: Text(
                                    onboardingData[_currentIndex]["description"],
                                    key: ValueKey(
                                        '${_currentIndex}_desc'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: descFontSize,
                                      height: 1.6,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: indicatorSpacerH),

                            // --- Get Started button ---
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                splashColor:
                                    Colors.white.withOpacity(0.12),
                                onTap: _navigateToLogin,
                                child: Ink(
                                  height: btnHeight,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.secondaryPurple,
                                        AppColors.primaryPurple,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.28),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Get Started",
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: btnFontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: AppColors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenH * 0.015),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}