import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../features/savings/data/savings_provider.dart';
import '../../features/savings/domain/models/savings_model.dart';
import 'add_savings_screen.dart';
import 'savings_detail_screen.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  bool _showAchieved = false;
  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  void _openAdd() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddSavingsScreen()));
  }

  void _openDetail(SavingsModel goal) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => SavingsDetailScreen(goal: goal)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 16),
            _buildToggle(state),
            const SizedBox(height: 24),

            // ── Tab Content ──────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryPurple))
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _showAchieved
                          ? _buildList(state.achieved, isAchieved: true)
                          : _buildList(state.ongoing, isAchieved: false),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────
      floatingActionButton: GestureDetector(
        onTap: _openAdd,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildToggle(SavingsState state) {
    return Container(
      width: 280,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _showAchieved ? 140 : 4,
            top: 4,
            bottom: 4,
            width: 136,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showAchieved = false),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: !_showAchieved ? Colors.white : AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      child: Text('Berlangsung'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showAchieved = true),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: _showAchieved ? Colors.white : AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      child: Text('Tercapai'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SavingsModel> goals, {required bool isAchieved}) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              isAchieved
                  ? 'Belum ada tabungan tercapai'
                  : 'Belum ada tabungan aktif',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: goals.length,
      itemBuilder: (_, i) => _buildCard(goals[i]),
    );
  }

  Widget _buildCard(SavingsModel goal) {
    return GestureDetector(
      onTap: () => _openDetail(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + pin button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(savingsProvider.notifier).togglePin(goal.id);
                    },
                    child: Icon(
                      goal.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: goal.isPinned
                          ? AppColors.primaryPurple
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCover(goal, 160),
              ),
            ),

            const SizedBox(height: 14),

            // Amount + progress ring + countdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fmt.format(goal.targetAmount),
                          style: TextStyle(
                            color: goal.isAchieved
                                ? Colors.green
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (goal.savingPlanLabel.isNotEmpty)
                          Text(
                            goal.savingPlanLabel,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          goal.countdownText,
                          style: TextStyle(
                            color: goal.isAchieved
                                ? Colors.green
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CircularProgressRing(
                    progress: goal.progressPercentage,
                    size: 64,
                    color: goal.isAchieved
                        ? Colors.green
                        : AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(SavingsModel goal, double height) {
    final hasImage = goal.imagePath != null && goal.imagePath!.isNotEmpty && 
                     (kIsWeb || goal.imagePath!.startsWith('http') || io.File(goal.imagePath!).existsSync());
    if (!hasImage) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(Icons.landscape_rounded,
              color: Colors.grey.shade500, size: 48),
        ),
      );
    }
    // Gambar bisa berupa URL cloud (https) atau path lokal
    final isUrl = goal.imagePath!.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isUrl
          ? Image.network(
              goal.imagePath!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      height: height,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
              errorBuilder: (_, __, ___) => Container(
                  height: height,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.broken_image, color: Colors.grey.shade500)),
            )
          : (kIsWeb
              ? Image.network(
                  goal.imagePath!,
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: height, color: Colors.grey.shade300, child: Icon(Icons.broken_image)),
                )
              : Image.file(
                  io.File(goal.imagePath!),
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
    );
  }
}

// ── Circular Progress Ring Widget ────────────────────────────
class _CircularProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;

  const _CircularProgressRing({
    required this.progress,
    this.size = 60,
    this.color = AppColors.primaryPurple,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
