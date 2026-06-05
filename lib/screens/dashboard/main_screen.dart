import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import '../../core/constants/app_colors.dart';
import '../planner/planner_screen.dart';
import '../savings/savings_screen.dart';
import '../financial/finance_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.edit_document, label: 'Catatan'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Keuangan'),
    _NavItem(icon: Icons.inventory_2_outlined, label: 'Tabungan'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const PlannerScreen(),
      const FinanceScreen(),
      const SavingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Jika tidak di tab Home, kembali ke tab Home dulu
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // Jika sudah di tab Home, tampilkan dialog konfirmasi keluar
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.exit_to_app_rounded, color: AppColors.primaryPurple),
                SizedBox(width: 10),
                Text('Keluar Aplikasi?'),
              ],
            ),
            content: Text(
              'Apakah kamu yakin ingin keluar dari SaveStep?',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Keluar'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop(); // Tutup aplikasi
        }
      },
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: _CustomNavBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _CustomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<_CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<_CustomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;
    _glowAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_CustomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double navHeight = 70;
    final int count = widget.items.length;

    return Container(
      height: navHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return CustomPaint(
              painter: _SpotlightPainter(
                itemCount: count,
                activeIndex: widget.currentIndex,
                progress: _glowAnim.value,
              ),
              child: SizedBox(
                height: navHeight,
                child: Row(
                  children: List.generate(count, (i) {
                    final bool isActive = i == widget.currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: isActive ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: Icon(
                                  widget.items[i].icon,
                                  size: 24,
                                  color: isActive
                                      ? AppColors.primaryPurple
                                      : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.items[i].label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isActive
                                      ? AppColors.primaryPurple
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final int itemCount;
  final int activeIndex;
  final double progress;

  _SpotlightPainter({
    required this.itemCount,
    required this.activeIndex,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double itemWidth = size.width / itemCount;
    final double centerX = itemWidth * activeIndex + itemWidth / 2;

    // Spotlight radius (ellipse spreading from top)
    const double spotW = 70.0;
    const double spotH = 18.0;

    final Rect spotRect = Rect.fromCenter(
      center: Offset(centerX, 0),
      width: spotW * progress,
      height: spotH * progress,
    );

    // Outer glow gradient (wide, soft)
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.35 * progress),
          const Color(0xFFA78BFA).withOpacity(0.12 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCenter(
          center: Offset(centerX, 0),
          width: 90,
          height: 50,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 0),
        width: 90 * progress,
        height: 50 * progress,
      ),
      glowPaint,
    );

    // Inner bright spot (tight ellipse at top edge)
    final Paint innerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [
          const Color(0xFFB197FC).withOpacity(0.85 * progress),
          const Color(0xFF8B5CF6).withOpacity(0.4 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(spotRect);

    canvas.drawOval(spotRect, innerPaint);

    // Top border accent line
    final Paint linePaint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.7 * progress)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 18 * progress, 0),
      Offset(centerX + 18 * progress, 0),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.activeIndex != activeIndex || old.progress != progress;
}

