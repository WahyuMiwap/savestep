import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../features/planner/data/planner_provider.dart';
import '../../../features/planner/domain/models/note_model.dart';

class AddNoteBottomSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final NoteModel? noteToEdit;

  const AddNoteBottomSheet({
    super.key,
    this.initialDate,
    this.noteToEdit,
  });

  @override
  ConsumerState<AddNoteBottomSheet> createState() => _AddNoteBottomSheetState();
}

class _AddNoteBottomSheetState extends ConsumerState<AddNoteBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _reminderValueController = TextEditingController(text: '0');

  bool _hasDeadline = false;
  DateTime? _selectedDate;
  String? _selectedCategory;

  // Reminder state
  bool _hasReminder = false;
  TimeOfDay? _reminderTime;
  ReminderUnit _reminderUnit = ReminderUnit.menit;

  @override
  void initState() {
    super.initState();

    final note = widget.noteToEdit;
    if (note != null) {
      _titleController.text = note.title;
      _hasDeadline = note.date != null;
      _selectedDate = note.date;
      _selectedCategory = note.category;
      _hasReminder = note.hasReminder;
      if (note.hasReminder && note.reminderTime != null) {
        final parts = note.reminderTime!.split(':');
        if (parts.length == 2) {
          _reminderTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 12,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
        // We set simple values for advanced reminder as it requires deeper mapping, but for now we set the text.
        _reminderValueController.text = note.reminderValue?.toString() ?? '0';
        // Unit would require finding from note's time diff, but we can default to unit if available, though NoteModel doesn't store the exact unit natively. We will leave default unit.
      }
    } else if (widget.initialDate != null) {
      _hasDeadline = true;
      _selectedDate = widget.initialDate;
    }

    Future.microtask(() {
      final categories = ref.read(plannerProvider).categories;
      if (categories.isNotEmpty && _selectedCategory == null) {
        setState(() {
          // Default ke kategori pertama yang bukan 'Semua'
          _selectedCategory = categories.firstWhere(
            (c) => c != 'Semua',
            orElse: () => categories.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newCategoryController.dispose();
    _reminderValueController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kategori Baru'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(hintText: 'Nama Kategori'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final cat = _newCategoryController.text.trim();
                if (cat.isNotEmpty) {
                  ref.read(plannerProvider.notifier).addCategory(cat);
                  setState(() => _selectedCategory = cat);
                }
                _newCategoryController.clear();
                Navigator.pop(context);
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  /// Meminta izin notifikasi jika belum diberikan
  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    if (result.isGranted) return true;

    // Jika ditolak, tampilkan pesan
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Izin notifikasi diperlukan untuk mengaktifkan pengingat.',
          ),
          action: SnackBarAction(
            label: 'Pengaturan',
            onPressed: openAppSettings,
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return false;
  }

  void _onReminderToggled(bool val) async {
    if (val) {
      // Minta izin dulu sebelum mengaktifkan
      final granted = await _requestNotificationPermission();
      if (!granted) return; // Batalkan jika ditolak

      setState(() {
        _hasReminder = true;
        _reminderTime ??= TimeOfDay.now();
      });
    } else {
      setState(() => _hasReminder = false);
    }
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    if (_selectedCategory == null) return;

    final rawValue = int.tryParse(_reminderValueController.text.trim()) ?? 0;

    final note = NoteModel(
      id: widget.noteToEdit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      date: _hasDeadline ? (_selectedDate ?? DateTime.now()) : null,
      category: _selectedCategory!,
      type: 'deadline', // selalu ungu, tidak ada pilihan lagi
      hasReminder: _hasReminder && _hasDeadline,
      reminderTime: _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null,
      reminderValue: rawValue,
      reminderUnit: _reminderUnit,
    );

    if (widget.noteToEdit != null) {
      ref.read(plannerProvider.notifier).updateNote(note);
    } else {
      ref.read(plannerProvider.notifier).addNote(note);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Input Judul
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Apa rencana hari ini?',
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryPurple),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Toggle: Tambah Batas Waktu ──────────────────────────────
            _buildSectionToggle(
              label: 'Tambah batas waktu?',
              value: _hasDeadline,
              onChanged: (val) {
                setState(() {
                  _hasDeadline = val;
                  if (val && _selectedDate == null) {
                    _selectedDate = DateTime.now();
                  }
                  // Nonaktifkan reminder jika deadline dimatikan
                  if (!val) _hasReminder = false;
                });
              },
            ),

            // ── Date Picker (muncul jika deadline aktif) ────────────────
            if (_hasDeadline) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryPurple,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                icon: Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Pilih Tanggal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  side: const BorderSide(color: AppColors.primaryPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Toggle: Aktifkan Pengingat ───────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _hasDeadline ? 1.0 : 0.35,
              child: IgnorePointer(
                ignoring: !_hasDeadline,
                child: _buildSectionToggle(
                  label: 'Aktifkan pengingat?',
                  value: _hasReminder,
                  onChanged: _onReminderToggled,
                  subtitle: _hasDeadline
                      ? null
                      : 'Aktifkan batas waktu terlebih dahulu',
                ),
              ),
            ),

            // ── Reminder Detail UI ───────────────────────────────────────
            if (_hasReminder && _hasDeadline) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris 1: Pilih jam notifikasi
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Jam notifikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _reminderTime ?? TimeOfDay.now(),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primaryPurple,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (time != null) {
                              setState(() => _reminderTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _reminderTime != null
                                  ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Pilih Jam',
                              style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0x1A7B2D8B)),
                    const SizedBox(height: 14),

                    // Baris 2: Input angka + Dropdown unit + "sebelumnya"
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ingatkan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),

                        // Input angka
                        SizedBox(
                          width: 52,
                          height: 38,
                          child: TextField(
                            controller: _reminderValueController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primaryPurple,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryPurple,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPurple.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        // Dropdown unit
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ReminderUnit>(
                              value: _reminderUnit,
                              isDense: true,
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                              items: ReminderUnit.values.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.label),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _reminderUnit = val);
                                }
                              },
                            ),
                          ),
                        ),

                        Text(
                          'sebelumnya',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // Preview hasil kalkulasi
                    if (_selectedDate != null && _reminderTime != null) ...[
                      const SizedBox(height: 12),
                      _buildReminderPreview(),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Kategori ─────────────────────────────────────────────────
            Text(
              'Kategori',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...plannerState.categories.where((c) => c != 'Semua').map((
                  cat,
                ) {
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primaryPurple,
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected
                                ? Colors.transparent
                                : AppColors.primaryPurple,
                      ),
                    ),
                  );
                }),
                ActionChip(
                  label: Text('+ Tambah'),
                  backgroundColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.primaryPurple),
                  ),
                  onPressed: _showAddCategoryDialog,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Tombol Simpan ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  'Tambahkan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget toggle baris (label + switch)
  Widget _buildSectionToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.primaryPurple,
          activeTrackColor: AppColors.primaryPurple.withValues(alpha: 0.35),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Preview "Notifikasi akan muncul pada: ..."
  Widget _buildReminderPreview() {
    final rawValue = int.tryParse(_reminderValueController.text.trim()) ?? 0;

    // Hitung waktu notif
    final baseDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _reminderTime!.hour,
      _reminderTime!.minute,
    );

    final notifDateTime =
        rawValue == 0
            ? baseDateTime
            : baseDateTime.subtract(_reminderUnit.toDuration(rawValue));

    final now = DateTime.now();
    final isPast = notifDateTime.isBefore(now);

    final dayStr =
        '${notifDateTime.day.toString().padLeft(2, '0')}/'
        '${notifDateTime.month.toString().padLeft(2, '0')}/'
        '${notifDateTime.year}';
    final timeStr =
        '${notifDateTime.hour.toString().padLeft(2, '0')}:'
        '${notifDateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            isPast
                ? Colors.red.withValues(alpha: 0.08)
                : AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: isPast ? Colors.red : AppColors.primaryPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPast
                  ? 'Waktu pengingat sudah terlewat!'
                  : 'Notifikasi: $dayStr pukul $timeStr',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPast ? Colors.red : AppColors.primaryPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
