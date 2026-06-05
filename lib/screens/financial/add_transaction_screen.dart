import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/app_colors.dart';
import '../../features/finance/data/finance_provider.dart';
import '../../features/finance/domain/models/transaction_model.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = 'Makanan';
  DateTime _date = DateTime.now();
  bool _isLoading = false;



  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primaryPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(financeProvider.notifier).addTransaction(
          title: _titleCtrl.text.trim(),
          amount: double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          type: _type,
          category: _category,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          date: _date,
        );

    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inputDeco(BuildContext context, String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon:
            Icon(icon, color: AppColors.primaryPurple.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;
    final accentColor = isIncome ? Colors.green : Colors.red;
    final fmt = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Transaksi',
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Theme.of(context).cardColor))
                  : Text('Simpan',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Type Toggle ────────────────────────────────────────
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TypeButton(
                    label: 'Pengeluaran',
                    icon: Icons.arrow_circle_down_rounded,
                    isSelected: !isIncome,
                    color: Colors.red,
                    onTap: () {
                      setState(() {
                        _type = TransactionType.expense;
                        _category = 'Makanan';
                      });
                    },
                  ),
                  _TypeButton(
                    label: 'Pemasukan',
                    icon: Icons.arrow_circle_up_rounded,
                    isSelected: isIncome,
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        _type = TransactionType.income;
                        _category = 'Gaji';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Amount Box ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIncome ? 'Jumlah Pemasukan' : 'Jumlah Pengeluaran',
                    style:
                        TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Rp',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: accentColor)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: accentColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(fontSize: 28),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (v) {
                            final n = double.tryParse(v?.replaceAll('.', '') ?? '');
                            if (n == null || n <= 0) {
                              return 'Masukkan nominal valid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Title & Note ────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: _inputDeco(context, 'Keterangan / Nama Transaksi', Icons.edit_rounded),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _noteCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: _inputDeco(context, 'Catatan (opsional)', Icons.notes_rounded),
            ),
            const SizedBox(height: 20),

            // ─── Date Picker ─────────────────────────────────────────
            Text('Tanggal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: AppColors.primaryPurple, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      fmt.format(_date),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Category Picker ─────────────────────────────────────
            Text('Kategori',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(financeProvider);
                final categories = isIncome ? state.incomeCategories : state.expenseCategories;
                
                // Ensure selected category is valid
                if (!categories.contains(_category)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _category = categories.first);
                  });
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...categories.map((cat) {
                      final selected = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        onLongPress: () => _showCategoryActionDialog(cat, isIncome),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryPurple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : AppColors.primaryPurple,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Tambah Kategori
                    GestureDetector(
                      onTap: () => _showAddCategoryDialog(isIncome),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryPurple.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '+ Tambah',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(bool isIncome) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kategori Baru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama kategori...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(financeProvider.notifier).addCategory(result, isIncome);
      if (mounted) setState(() => _category = result);
    }
  }

  void _showCategoryActionDialog(String category, bool isIncome) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opsi Kategori: $category',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: Colors.blue),
                title: Text('Edit Kategori'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category, isIncome);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.red),
                title: Text('Hapus Kategori'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCategory(category, isIncome);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(String oldCategory, bool isIncome) {
    final tc = TextEditingController(text: oldCategory);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Kategori'),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama Kategori Baru',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (tc.text.trim().isNotEmpty) {
                ref.read(financeProvider.notifier).editCategory(oldCategory, tc.text.trim(), isIncome);
                if (_category == oldCategory) {
                  setState(() => _category = tc.text.trim());
                }
              }
              Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String category, bool isIncome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kategori?'),
        content: Text('Transaksi dalam kategori "$category" akan dipindahkan. Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(financeProvider.notifier).deleteCategory(category, isIncome);
              if (_category == category) {
                final state = ref.read(financeProvider);
                final categories = isIncome ? state.incomeCategories : state.expenseCategories;
                final newCats = categories.where((c) => c != category).toList();
                if (newCats.isNotEmpty) setState(() => _category = newCats.first);
              }
              Navigator.pop(context);
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? color : Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
