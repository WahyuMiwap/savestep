import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/app_colors.dart';
import '../../features/savings/data/savings_provider.dart';
import '../../features/savings/domain/models/savings_model.dart';
import 'add_savings_screen.dart';

class SavingsDetailScreen extends ConsumerWidget {
  final SavingsModel goal;
  const SavingsDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch fresh data so card updates after deposit
    final currentGoal = ref.watch(savingsProvider).goals.firstWhere(
          (g) => g.id == goal.id,
          orElse: () => goal,
        );

    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
    final timeFmt = DateFormat('dd MMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.primaryPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSavingsScreen(goalToEdit: currentGoal),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Hapus Tabungan',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                  content: Text(
                    'Hapus "${currentGoal.title}"? Data tidak dapat dikembalikan.',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Batal', style: TextStyle(color: Colors.grey.shade600))),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Hapus',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref
                    .read(savingsProvider.notifier)
                    .deleteGoal(currentGoal.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text('Hapus',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Title
          Text(
            currentGoal.title,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 26,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _buildImage(currentGoal, 200),
          ),
          const SizedBox(height: 20),

          // Amount + achieved info
          Text(
            fmt.format(currentGoal.targetAmount),
            style: TextStyle(
              color: currentGoal.isAchieved ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentGoal.isAchieved
                ? 'Tercapai dalam waktu ${currentGoal.achievedAt != null ? currentGoal.createdAt.difference(currentGoal.achievedAt!).abs().inDays : "-"} Hari'
                : 'Terkumpul: ${fmt.format(currentGoal.currentAmount)}  •  ${currentGoal.countdownText}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: currentGoal.progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: currentGoal.isAchieved
                  ? Colors.green
                  : AppColors.primaryPurple,
            ),
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),

          // Meta info
          _infoRow(context, 'Tanggal Dibuat', dateFmt.format(currentGoal.createdAt)),
          if (currentGoal.achievedAt != null)
            _infoRow(context, 'Tanggal Tercapai',
                dateFmt.format(currentGoal.achievedAt!)),
          if (currentGoal.savingAmountPerPeriod > 0) ...[
            const SizedBox(height: 4),
            _infoRow(context, 'Rencana Pengisian', currentGoal.savingPlanLabel),
          ],

          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),

          // Transaction history
          if (currentGoal.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada riwayat simpanan',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ...currentGoal.transactions.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeFmt.format(tx.createdAt),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      Text(
                        '+ ${fmt.format(tx.amount)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 100),
        ],
      ),

      // FAB Tambah Simpanan
      floatingActionButton: currentGoal.isAchieved
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primaryPurple,
              icon: Icon(Icons.add_rounded, color: Theme.of(context).cardColor),
              label: Text('Tambah Simpanan',
                  style: TextStyle(
                      color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
              onPressed: () => _showDepositDialog(context, ref, currentGoal, fmt),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref,
      SavingsModel currentGoal, NumberFormat fmt) {
    final ctrl = TextEditingController();
    double amount = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Tambah Simpanan',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  labelText: 'Jumlah',
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.primaryPurple, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1)),
                ),
                onChanged: (v) => setS(() => amount = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
              ),
              const SizedBox(height: 16),
              // Quick presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [10000, 50000, 100000, 250000, 500000]
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setS(() {
                                amount = p.toDouble();
                                ctrl.text = fmt.format(p);
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: amount == p
                                      ? AppColors.primaryPurple
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: amount == p
                                        ? Colors.transparent
                                        : AppColors.primaryPurple,
                                  ),
                                ),
                                child: Text(
                                  fmt.format(p),
                                  style: TextStyle(
                                      color: amount == p ? Colors.white : AppColors.primaryPurple,
                                      fontWeight: amount == p ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal',
                    style: TextStyle(color: Colors.grey.shade600))),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (amount <= 0) return;
                ref.read(savingsProvider.notifier).deposit(
                    id: currentGoal.id, amount: amount);
                Navigator.pop(ctx);
              },
              child: Text('Simpan'),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildImage(SavingsModel g, double height) {
    final hasImage = g.imagePath != null && g.imagePath!.isNotEmpty && 
                     (kIsWeb || g.imagePath!.startsWith('http') || io.File(g.imagePath!).existsSync());
    if (!hasImage) {
      return Container(
        height: height,
        color: Colors.grey.shade300,
        child: Center(
          child: Icon(Icons.landscape_rounded, color: Colors.grey.shade500, size: 60),
        ),
      );
    }
    final isUrl = g.imagePath!.startsWith('https://');
    return isUrl
        ? Image.network(
            g.imagePath!,
            height: height,
            fit: BoxFit.cover,
            width: double.infinity,
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
                g.imagePath!,
                height: height,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                    height: height, color: Colors.grey.shade300, child: Icon(Icons.broken_image)),
              )
            : Image.file(
                io.File(g.imagePath!),
                height: height,
                fit: BoxFit.cover,
                width: double.infinity,
              ));
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
