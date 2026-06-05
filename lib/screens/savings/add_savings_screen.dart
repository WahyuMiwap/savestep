import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/constants/app_colors.dart';

import '../../features/savings/data/savings_provider.dart';
import '../../features/savings/domain/models/savings_model.dart';

class AddSavingsScreen extends ConsumerStatefulWidget {
  final SavingsModel? goalToEdit;
  const AddSavingsScreen({super.key, this.goalToEdit});

  @override
  ConsumerState<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends ConsumerState<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _savingAmtCtrl;

  String _frequency = 'mingguan';
  String? _imagePath;
  bool _notifEnabled = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 12, minute: 0);
  List<int> _notifDays = [];
  int _notifDate = 1;
  bool _isLoading = false;

  static const _days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  static const _freqs = ['harian', 'mingguan', 'bulanan'];
  static const _freqLabels = ['Harian', 'Mingguan', 'Bulanan'];

  @override
  void initState() {
    super.initState();
    final e = widget.goalToEdit;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    final formatter = NumberFormat.decimalPattern('id_ID');
    
    _targetCtrl = TextEditingController(
        text: e != null ? formatter.format(e.targetAmount) : '');
    _savingAmtCtrl = TextEditingController(
        text: e != null && e.savingAmountPerPeriod > 0
            ? formatter.format(e.savingAmountPerPeriod)
            : '');
    if (e != null) {
      _frequency = e.savingFrequency;
      _imagePath = e.imagePath;
      _notifEnabled = e.notificationEnabled;
      _notifTime = TimeOfDay(hour: e.notificationHour, minute: e.notificationMinute);
      _notifDays = List.from(e.notificationDays);
      _notifDate = e.notificationDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _savingAmtCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, maxWidth: 1200, imageQuality: 85);
        
      if (picked != null) {
      final cropper = ImageCropper();
      final croppedFile = await cropper.cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Gambar Sampul',
            toolbarColor: AppColors.primaryPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Potong Gambar Sampul',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
          ),
        ],
      );
      
      if (croppedFile != null) {
        setState(() => _imagePath = croppedFile.path);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Gambar Sampul',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: AppColors.primaryPurple),
              title: Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: AppColors.primaryPurple),
              title: Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final savingAmt = double.tryParse(_savingAmtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    try {
      // Simpan path gambar secara lokal saja (Offline-First, tanpa Firebase Storage)
      String? finalImagePath = _imagePath;
      if (widget.goalToEdit != null) {
        await ref.read(savingsProvider.notifier).editGoal(
              id: widget.goalToEdit!.id,
              title: title,
              targetAmount: target,
              category: 'Umum',
              savingFrequency: _frequency,
              savingAmountPerPeriod: savingAmt,
              notificationEnabled: _notifEnabled,
              notificationHour: _notifTime.hour,
              notificationMinute: _notifTime.minute,
              notificationDays: _notifDays,
              notificationDate: _notifDate,
              imagePath: finalImagePath,
            );
      } else {
        await ref.read(savingsProvider.notifier).addGoal(
              title: title,
              targetAmount: target,
              category: 'Umum',
              savingFrequency: _frequency,
              savingAmountPerPeriod: savingAmt,
              notificationEnabled: _notifEnabled,
              notificationHour: _notifTime.hour,
              notificationMinute: _notifTime.minute,
              notificationDays: _notifDays,
              notificationDate: _notifDate,
              imagePath: finalImagePath,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCalculatorDialog() async {
    final targetController = TextEditingController(text: _targetCtrl.text);
    DateTime? selectedDate;
    bool isCalculated = false;
    double dailyAmount = 0;
    double weeklyAmount = 0;
    double monthlyAmount = 0;
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final formatter = NumberFormat.decimalPattern('id_ID');

            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isCalculated ? 'Pilih Rencana' : 'Kalkulator Target', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: isCalculated
                    ? [
                        // Hasil perhitungan
                        const Text('Pilih salah satu rencana pengisian berikut:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 16),
                        _buildCalculationOption(
                          context,
                          title: 'Harian',
                          amount: dailyAmount,
                          formatter: formatter,
                          onTap: () {
                            setState(() {
                              _targetCtrl.text = targetController.text;
                              _frequency = 'harian';
                              _savingAmtCtrl.text = formatter.format(dailyAmount.ceil());
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCalculationOption(
                          context,
                          title: 'Mingguan',
                          amount: weeklyAmount,
                          formatter: formatter,
                          onTap: () {
                            setState(() {
                              _targetCtrl.text = targetController.text;
                              _frequency = 'mingguan';
                              _savingAmtCtrl.text = formatter.format(weeklyAmount.ceil());
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCalculationOption(
                          context,
                          title: 'Bulanan',
                          amount: monthlyAmount,
                          formatter: formatter,
                          onTap: () {
                            setState(() {
                              _targetCtrl.text = targetController.text;
                              _frequency = 'bulanan';
                              _savingAmtCtrl.text = formatter.format(monthlyAmount.ceil());
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      ]
                    : [
                        TextField(
                          controller: targetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: _lightInput(context, 'Target Tabungan', Icons.monetization_on_outlined),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (date != null) {
                              setStateDialog(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, color: AppColors.primaryPurple.withOpacity(0.6), size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  selectedDate == null 
                                    ? 'Target Tercapai Kapan?' 
                                    : DateFormat('dd MMM yyyy').format(selectedDate!),
                                  style: TextStyle(color: selectedDate == null ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
              ),
              actions: [
                if (isCalculated)
                  TextButton(
                    onPressed: () => setStateDialog(() => isCalculated = false),
                    child: const Text('Hitung Ulang', style: TextStyle(color: Colors.grey)),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                if (!isCalculated)
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                    onPressed: () {
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pilih tanggal target tercapai!'), backgroundColor: Colors.orange)
                        );
                        return;
                      }
                      final target = double.tryParse(targetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      if (target <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Masukkan target tabungan yang valid!'), backgroundColor: Colors.orange)
                        );
                        return;
                      }
                      
                      final now = DateTime.now();
                      final targetDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
                      final today = DateTime(now.year, now.month, now.day);
                      final days = targetDate.difference(today).inDays;
                      
                      if (days <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tanggal target harus lebih dari hari ini!'), backgroundColor: Colors.orange)
                        );
                        return;
                      }
                      
                      setStateDialog(() {
                        dailyAmount = target / days;
                        weeklyAmount = target / (days / 7);
                        monthlyAmount = target / (days / 30);
                        isCalculated = true;
                      });
                    },
                    child: const Text('Hitung'),
                  ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildCalculationOption(BuildContext context, {required String title, required double amount, required NumberFormat formatter, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Rp ${formatter.format(amount.ceil())}', style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    final bool hasImage = _imagePath != null && 
                          _imagePath!.isNotEmpty && 
                          (kIsWeb || _imagePath!.startsWith('http') || io.File(_imagePath!).existsSync());
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 180,
          width: double.infinity,
          color: Theme.of(context).cardColor,
          child: hasImage
              ? Stack(fit: StackFit.expand, children: [
                  (kIsWeb || _imagePath!.startsWith('http'))
                      ? Image.network(_imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                      : Image.file(io.File(_imagePath!), fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: Theme.of(context).cardColor, size: 16),
                      ),
                    ),
                  )
                ])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.grey.shade400, size: 40),
                    const SizedBox(height: 8),
                    Text('Ketuk untuk tambah foto',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
        ),
      ),
    );
  }

  InputDecoration _lightInput(BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: AppColors.primaryPurple.withOpacity(0.6), size: 20),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryPurple, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      width: 16, height: 16,
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
            // Cover image
            _buildImageArea(),
            const SizedBox(height: 20),

            // Nama Tabungan
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: _lightInput(context, 'Nama Tabungan', Icons.savings_outlined),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Target
            TextFormField(
              controller: _targetCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: _lightInput(context, 'Target Tabungan', Icons.monetization_on_outlined),
              validator: (v) {
                final n = double.tryParse(v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                if (n == null || n <= 0) return 'Masukkan nominal yang valid';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Rencana Pengisian
            Text('Rencana Pengisian',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),

            // Frequency tabs
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Row(
                children: List.generate(_freqs.length, (i) {
                  final selected = _frequency == _freqs[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _frequency = _freqs[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _freqLabels[i],
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.primaryPurple,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Nominal pengisian
            TextFormField(
              controller: _savingAmtCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: _lightInput(context, 'Nominal Pengisian', Icons.edit_rounded),
            ),
            const SizedBox(height: 8),

            // Kalkulator hint
            GestureDetector(
              onTap: _showCalculatorDialog,
              child: Text(
                'Masih bingung? Hitung Dengan Kalkulator Target',
                style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),

            // Notifikasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifikasi',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Switch(
                  value: _notifEnabled,
                  activeColor: AppColors.primaryPurple,
                  onChanged: (v) => setState(() => _notifEnabled = v),
                ),
              ],
            ),
            
            if (_notifEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _notifTime,
                        builder: (ctx, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: AppColors.primaryPurple),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _notifTime = picked);
                    },
                    child: Text(
                      _notifTime.format(context),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded,
                      color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 12),

              // Opsi tambahan sesuai frekuensi
              if (_frequency == 'mingguan') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final sel = _notifDays.contains(i);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (sel) {
                            _notifDays.remove(i);
                          } else {
                            _notifDays.add(i);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primaryPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : AppColors.primaryPurple,
                          ),
                        ),
                        child: Text(
                          _days[i],
                          style: TextStyle(
                            color: sel ? Colors.white : AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ] else if (_frequency == 'bulanan') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Setiap Tanggal:', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: _notifDate,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                        items: List.generate(31, (index) {
                          final day = index + 1;
                          return DropdownMenuItem(
                            value: day,
                            child: Text(day.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _notifDate = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
