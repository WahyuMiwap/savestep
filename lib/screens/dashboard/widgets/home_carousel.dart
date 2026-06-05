import 'dart:io' as io;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/planner/data/planner_provider.dart';
import '../../../features/planner/domain/models/note_model.dart';
import '../../../features/savings/data/savings_provider.dart';
import '../../../features/finance/data/finance_provider.dart';
import 'package:intl/intl.dart';

class HomeCarousel extends ConsumerStatefulWidget {
  const HomeCarousel({super.key});

  @override
  ConsumerState<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends ConsumerState<HomeCarousel> with TickerProviderStateMixin {
  // _pageOffset represents the continuous page scroll position.
  // 0.0 -> card 0 is center
  // 1.0 -> card 1 is center
  // 2.0 -> card 2 is center
  double _pageOffset = 0.0;
  AnimationController? _animationController;

  static String _getTodayDate() {
    final now = DateTime.now();
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  final List<Map<String, dynamic>> _cardData = [
    {
      'title': 'Catatan',
      'subtitle': '6/10 selesai',
      'icon': Icons.edit_document,
      'items': [
        {'text': 'Beli Parfum', 'label': null},
        {'text': 'Bayar Hutang', 'label': '2 hari lagi'},
        {'text': 'Hutang Ke radit', 'label': null},
        {'text': 'Belajar Uts statistika', 'label': null},
        {'text': 'Make up Mata kecil', 'label': null},
      ],
    },
    {
      'title': 'Keuangan',
      'subtitle': '',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'title': 'Tabungan',
      'subtitle': '',
      'icon': Icons.inventory_2_outlined,
    },
  ];

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _animateToPage(double targetOffset) {
    _animationController?.dispose();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    final animation = Tween<double>(begin: _pageOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOutCubic)
    );

    animation.addListener(() {
      setState(() {
        _pageOffset = animation.value;
      });
    });

    _animationController!.forward();
  }

  void _goToPage(int index) {
    double currentPos = _pageOffset;
    double diff = (index - currentPos) % 3;
    if (diff > 1.5) diff -= 3;
    if (diff < -1.5) diff += 3;
    _animateToPage(currentPos + diff);
  }

  Widget _buildCardContent(Map<String, dynamic> data, double cardWidth) {
    if (data['title'] == 'Catatan') {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data['icon'], size: 36, color: Theme.of(context).textTheme.bodyLarge?.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data['subtitle'],
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: data['items'].isEmpty 
                ? Center(child: Text('Belum ada catatan', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data['items'].length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
                    itemBuilder: (context, index) {
                      final NoteModel note = data['items'][index];
                      String label = '';
                      if (note.date != null) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final noteDate = DateTime(note.date!.year, note.date!.month, note.date!.day);
                        if (noteDate.isAtSameMomentAs(today)) {
                          label = 'Hari ini';
                        } else {
                          label = DateFormat('dd MMM').format(note.date!);
                        }
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                ref.read(plannerProvider.notifier).toggleNoteStatus(note.id);
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: note.isCompleted ? AppColors.primaryPurple : Colors.transparent,
                                  border: Border.all(
                                    color: note.isCompleted ? AppColors.primaryPurple : Colors.grey.shade400, 
                                    width: 1.5
                                  ),
                                ),
                                child: note.isCompleted 
                                  ? Icon(Icons.check, size: 14, color: Theme.of(context).cardColor)
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (label.isNotEmpty)
                              Text(
                                label,
                                style: const TextStyle(fontSize: 10, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      );
    } else if (data['title'] == 'Keuangan') {
      final finState = ref.watch(financeProvider);
      final fmt =
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Hanya transaksi hari ini
      final todayTx = finState.transactions.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d == today;
      }).toList();

      final todayIncome =
          todayTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final todayExpense =
          todayTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final todayBalance = todayIncome - todayExpense;

      const _hari = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
      ];
      const _bulan = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final dateLabel =
          '${_hari[now.weekday - 1]}, ${now.day} ${_bulan[now.month - 1]} ${now.year}';

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                Icon(data['icon'] as IconData, size: 30, color: Theme.of(context).textTheme.bodyLarge?.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keuangan',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(dateLabel,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Saldo Bersih ────────────────────────────────────
            Text('Saldo Bersih:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              fmt.format(todayBalance),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: todayBalance >= 0 ? Theme.of(context).textTheme.bodyLarge?.color : Colors.red.shade600,
              ),
            ),

            const Spacer(),
            Divider(color: Colors.grey.shade200),
            const Spacer(),

            // ── Pemasukan & Pengeluaran ─────────────────────────
            Row(
              children: [
                // Pemasukan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pemasukan',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                Icons.arrow_circle_up_rounded,
                                color: Colors.green,
                                size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fmt.format(todayIncome),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyLarge?.color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Garis pemisah vertikal
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                // Pengeluaran
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pengeluaran',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                Icons.arrow_circle_down_rounded,
                                color: Colors.red,
                                size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fmt.format(todayExpense),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyLarge?.color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      );

    } else {
      // Tabungan — data diambil dari pinned goal
      final savingsState = ref.watch(savingsProvider);
      final pinned = savingsState.pinnedGoal;
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      if (pinned == null) {
        // Tidak ada goal yang di-pin
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(data['icon'], size: 36, color: Theme.of(context).textTheme.bodyLarge?.color),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Belum ada yang di-pin', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.push_pin_outlined, color: Colors.grey.shade300, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Pin salah satu tabungan\nuntuk ditampilkan di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      }

      // Ada pinned goal — tampilkan data asli
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(data['icon'], size: 28, color: Theme.of(context).textTheme.bodyLarge?.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tabungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        pinned.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Pin indicator
                Icon(Icons.push_pin_rounded, color: AppColors.primaryPurple, size: 16),
              ],
            ),
            const SizedBox(height: 12),

            // Cover image (kecil)
            if (pinned.imagePath != null && pinned.imagePath!.isNotEmpty && (pinned.imagePath!.startsWith('http') || io.File(pinned.imagePath!).existsSync())) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: (kIsWeb || pinned.imagePath!.startsWith('http'))
                      ? Image.network(pinned.imagePath!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300))
                      : Image.file(io.File(pinned.imagePath!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Terkumpul
            Text('Terkumpul:', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(
              fmt.format(pinned.currentAmount),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
            ),
            Text(
              'dari ${fmt.format(pinned.targetAmount)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const Spacer(),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pinned.progressPercentage,
                minHeight: 8,
                backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                color: pinned.isAchieved ? Colors.green : AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 6),

            // Progress % + countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pinned.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple, fontSize: 13),
                ),
                Text(
                  pinned.countdownText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: pinned.isAchieved ? Colors.green : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  bool _isAutoAnimating = false;
  double _dragStartOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    var activeNotes = plannerState.notes.where((note) {
      if (note.isCompleted) return false;
      if (note.date != null) {
        final noteDate = DateTime(note.date!.year, note.date!.month, note.date!.day);
        if (noteDate.isBefore(today)) return false; // Exclude overdue
      }
      return true;
    }).toList();

    activeNotes.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });

    final totalCompleted = plannerState.notes.where((n) => n.isCompleted).length;
    _cardData[0]['subtitle'] = '$totalCompleted/${plannerState.notes.length} selesai';
    _cardData[0]['items'] = activeNotes;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            final double cardWidth = width * 0.75;
            // Clamp tinggi kartu supaya tidak overflow di layar kecil
            final double cardHeight = (height * 0.88).clamp(200.0, 380.0);

            return GestureDetector(
              onHorizontalDragStart: (details) {
                _animationController?.stop();
                _isAutoAnimating = false;
                _dragStartOffset = _pageOffset.roundToDouble();
              },
              onHorizontalDragUpdate: (details) {
                if (_isAutoAnimating) return;

                setState(() {
                  double sensitivity = width * 0.75;
                  if (sensitivity <= 0) sensitivity = 1;
                  _pageOffset -= details.delta.dx / sensitivity;

                  // Jika sudah geser lebih dari setengah jalan (0.5), langsung pindah otomatis
                  if ((_pageOffset - _dragStartOffset).abs() >= 0.5) {
                    _isAutoAnimating = true;
                    double targetOffset = _pageOffset > _dragStartOffset
                        ? _dragStartOffset + 1.0
                        : _dragStartOffset - 1.0;
                    _animateToPage(targetOffset);
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                if (_isAutoAnimating) return; // Kalau sudah snap otomatis, abaikan

                double velocity = details.primaryVelocity ?? 0;
                double targetOffset = 0.0;
                
                if (_pageOffset.isNaN) {
                  _pageOffset = 0.0;
                }

                if (velocity < -300) {
                  targetOffset = _pageOffset.floorToDouble() + 1.0;
                } else if (velocity > 300) {
                  targetOffset = _pageOffset.ceilToDouble() - 1.0;
                } else {
                  targetOffset = _pageOffset.roundToDouble();
                }

                _animateToPage(targetOffset);
              },
              child: Container(
                color: Colors.transparent, // Expand gesture area
                child: Stack(
                  alignment: Alignment.center,
                  children: (() {
                    // Generate items with their positions
                    List<Map<String, dynamic>> items = List.generate(3, (index) {
                      double offset = _pageOffset;
                      if (offset.isNaN) offset = 0.0;
                      
                      double x = (index - offset) % 3;
                      if (x > 1.5) x -= 3.0;
                      if (x < -1.5) x += 3.0;

                      double absX = x.abs();

                      double alignX;
                      double scale;
                      double blur;
                      double overlay;
                      int zIndex;

                      if (absX <= 1.0) {
                        // Between center and side
                        alignX = 0.85 * x; 
                        scale = 1.0 - (0.15 * absX);
                        blur = 2.0 * absX;
                        overlay = 0.15 * absX;
                        zIndex = (100 - (absX * 100)).toInt();
                      } else {
                        // Far back crossing
                        if (x > 0) {
                          double t = (x - 1.0) / 0.5;
                          alignX = 0.85 * (1.0 - t);
                        } else {
                          double t = (absX - 1.0) / 0.5;
                          alignX = -0.85 * (1.0 - t);
                        }
                        scale = 0.85 - 0.1 * ((absX - 1.0) / 0.5); 
                        blur = 2.0 + 1.0 * ((absX - 1.0) / 0.5); 
                        overlay = 0.15 + 0.15 * ((absX - 1.0) / 0.5);
                        zIndex = 0; 
                      }

                      return {
                        'index': index,
                        'x': x,
                        'absX': absX,
                        'alignX': alignX,
                        'scale': scale,
                        'blur': blur,
                        'overlay': overlay,
                        'zIndex': zIndex,
                      };
                    });

                    // Sort by zIndex so the front card is on top
                    items.sort((a, b) => a['zIndex'].compareTo(b['zIndex']));

                    return items.map((item) {
                      int index = item['index'];
                      double alignX = item['alignX'];
                      double scale = item['scale'];
                      double blur = item['blur'];
                      double overlay = item['overlay'];

                      return Align(
                        alignment: Alignment(alignX, 0),
                        child: Transform.scale(
                          scale: scale,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: Stack(
                              children: [
                                Container(
                                  width: cardWidth,
                                  height: cardHeight,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: _buildCardContent(_cardData[index], cardWidth),
                                ),
                                IgnorePointer(
                                  child: Container(
                                    width: cardWidth,
                                    height: cardHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(overlay),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList();
                  })(),
                ),
              ),
            );
          }),
        ),

        // Indicator dots only
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              double offset = _pageOffset;
              if (offset.isNaN) offset = 0.0;
              
              int currentIndex = (offset.round()) % 3;
              if (currentIndex < 0) currentIndex += 3;

              return GestureDetector(
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? AppColors.primaryPurple
                        : AppColors.primaryPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
