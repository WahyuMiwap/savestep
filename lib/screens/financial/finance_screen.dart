import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../features/finance/data/finance_provider.dart';
import '../../features/finance/domain/models/transaction_model.dart';
import 'add_transaction_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

// 0=Semua, 1=Pemasukan, 2=Pengeluaran
class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _filterIndex = 0;
  final _currFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _catIcons = <String, IconData>{
    'Gaji': Icons.work_rounded,
    'Bisnis': Icons.store_rounded,
    'Investasi': Icons.trending_up_rounded,
    'Bonus': Icons.card_giftcard_rounded,
    'Makanan': Icons.restaurant_rounded,
    'Transportasi': Icons.directions_car_rounded,
    'Belanja': Icons.shopping_bag_rounded,
    'Kesehatan': Icons.favorite_rounded,
    'Hiburan': Icons.sports_esports_rounded,
    'Tagihan': Icons.receipt_long_rounded,
    'Pendidikan': Icons.school_rounded,
    'Lainnya': Icons.more_horiz_rounded,
  };

  static const _filterLabels = ['Semua', 'Pemasukan', 'Pengeluaran'];

  List<TransactionModel> _filtered(List<TransactionModel> all) {
    if (_filterIndex == 1) return all.where((t) => t.isIncome).toList();
    if (_filterIndex == 2) return all.where((t) => !t.isIncome).toList();
    return all;
  }

  /// Kelompokkan berdasarkan tanggal
  Map<String, List<TransactionModel>> _group(List<TransactionModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<TransactionModel>>{};

    for (final t in list) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      String label;
      if (d == today) {
        label = 'Hari Ini';
      } else if (d == yesterday) {
        label = 'Kemarin';
      } else {
        label = DateFormat('dd MMMM yyyy', 'id_ID').format(t.date);
      }
      map.putIfAbsent(label, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final filtered = _filtered(state.transactions);
    final grouped = _group(filtered);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero Card ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Bersih',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  state.isLoading
                      ? SizedBox(
                          height: 36,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _currFmt.format(state.balance),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Pemasukan',
                          amount: _currFmt.format(state.totalIncome),
                          icon: Icons.arrow_circle_up_rounded,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Pengeluaran',
                          amount: _currFmt.format(state.totalExpense),
                          icon: Icons.arrow_circle_down_rounded,
                          color: const Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Filter Toggle ──────────────────────────────────────
            _buildToggle(),
            const SizedBox(height: 16),

            // ── Transaction List ───────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryPurple))
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          children: grouped.entries.map((entry) {
                            return _buildGroup(
                                entry.key, entry.value);
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildToggle() {
    return Container(
      width: 280,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _filterIndex == 0
                ? 4
                : _filterIndex == 1
                    ? (280 - 8) / 3
                    : (280 - 8) / 3 * 2,
            top: 4,
            bottom: 4,
            width: (280 - 8) / 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final active = _filterIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _filterIndex = i),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                      child: Text(_filterLabels[i]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String label, List<TransactionModel> items) {
    final groupTotal = items.fold<double>(
        0, (sum, t) => t.isIncome ? sum + t.amount : sum - t.amount);
    final isPositive = groupTotal >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${_currFmt.format(groupTotal)}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return _buildTile(e.value, isLast: isLast);
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTile(TransactionModel tx, {required bool isLast}) {
    final isIncome = tx.isIncome;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = _catIcons[tx.category] ?? Icons.more_horiz_rounded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Category icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              // Title + category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.category,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Amount + delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${_currFmt.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => _confirmDelete(tx),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 74,
              endIndent: 16,
              color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Tekan + untuk menambahkan',
            style:
                TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddTransactionScreen()),
        );
      },
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
              color: AppColors.primaryPurple.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Future<void> _confirmDelete(TransactionModel tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Transaksi?'),
        content: Text(
            'Transaksi "${tx.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(financeProvider.notifier).deleteTransaction(tx.id);
    }
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
