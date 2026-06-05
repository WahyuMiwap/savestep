import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../features/planner/data/planner_provider.dart';
import '../../features/planner/domain/models/note_model.dart';
import 'widgets/add_note_bottom_sheet.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool _showCalendar = false;
  String _selectedCategory = 'Semua';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  void _showAddCategoryDialog() {
    final TextEditingController newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kategori Baru'),
          content: TextField(
            controller: newCategoryController,
            decoration: const InputDecoration(
              hintText: 'Nama Kategori',
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
                final cat = newCategoryController.text.trim();
                if (cat.isNotEmpty) {
                  ref.read(plannerProvider.notifier).addCategory(cat);
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showMonthYearPicker() {
    int tempYear = _focusedDay.year;
    int tempMonth = _focusedDay.month;

    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final years = List.generate(11, (i) => 2020 + i); // 2020-2030

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pilih Bulan & Tahun', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year picker
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: AppColors.primaryPurple),
                    onPressed: tempYear > 2020
                        ? () => setDialogState(() => tempYear--)
                        : null,
                  ),
                  Text(
                    '$tempYear',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPurple,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: AppColors.primaryPurple),
                    onPressed: tempYear < 2030
                        ? () => setDialogState(() => tempYear++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final isSelected = i + 1 == tempMonth;
                  return GestureDetector(
                    onTap: () => setDialogState(() => tempMonth = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPurple
                            : AppColors.primaryPurple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        months[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(tempYear, tempMonth);
                  _selectedDay = DateTime(tempYear, tempMonth);
                });
                Navigator.pop(ctx);
              },
              child: Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Custom Toggle Button (Catatan / Kalender)
            _buildToggle(),
            const SizedBox(height: 24),
            
            // Konten Utama
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _showCalendar 
                    ? _buildCalendarView(plannerState.allNotes)
                    : _buildNotesView(plannerState),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddNoteBottomSheet(),
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

  Widget _buildToggle() {
    return Container(
      width: 240,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _showCalendar ? 120 : 4,
            top: 4,
            bottom: 4,
            width: 116,
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
                  onTap: () => setState(() => _showCalendar = false),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: !_showCalendar ? Colors.white : AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                      child: Text('Catatan'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showCalendar = true),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: _showCalendar ? Colors.white : AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                      child: Text('Kalender'),
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

  Widget _buildNotesView(PlannerState state) {
    // Filter by Category
    var filteredNotes = state.notes; // Hanya catatan pengguna, abaikan holiday
    if (_selectedCategory != 'Semua') {
      filteredNotes = filteredNotes.where((n) => n.category == _selectedCategory).toList();
    }

    // Grouping
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final overdueNotes = <NoteModel>[];
    final todayNotes = <NoteModel>[];
    final upcomingNotes = <NoteModel>[];
    final otherNotes = <NoteModel>[];
    final completedNotes = <NoteModel>[];

    for (var note in filteredNotes) {
      if (note.isCompleted) {
        completedNotes.add(note);
        continue;
      }

      if (note.date == null) {
        otherNotes.add(note);
      } else {
        final noteDate = DateTime(note.date!.year, note.date!.month, note.date!.day);
        if (noteDate.isBefore(today)) {
          overdueNotes.add(note);
        } else if (noteDate.isAtSameMomentAs(today)) {
          todayNotes.add(note);
        } else {
          upcomingNotes.add(note);
        }
      }
    }

    // Sort upcoming by closest date
    upcomingNotes.sort((a, b) => a.date!.compareTo(b.date!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              ...state.categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () {
                      if (cat == 'Semua') return;
                      _showCategoryActionDialog(cat);
                    },
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppColors.primaryPurple,
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Add Category Chip
              ActionChip(
                label: Text('+ Tambah'),
                backgroundColor: Colors.transparent,
                labelStyle: const TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.primaryPurple),
                ),
                onPressed: _showAddCategoryDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // List View
        Expanded(
          child: ListView(
            key: const ValueKey('NotesList'),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              if (overdueNotes.isNotEmpty) 
                _buildExpandableSection('Sudah Terlewat', overdueNotes, color: Colors.red),
              if (todayNotes.isNotEmpty) 
                _buildExpandableSection('Hari ini', todayNotes),
              if (upcomingNotes.isNotEmpty) 
                _buildExpandableSection('Mendatang', upcomingNotes),
              if (otherNotes.isNotEmpty) 
                _buildExpandableSection('Lainnya', otherNotes),
              if (completedNotes.isNotEmpty) 
                _buildExpandableSection('Selesai', completedNotes, color: AppColors.primaryPurple, initExpanded: false),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView(List<NoteModel> notes) {
    // Filter catatan berdasarkan tanggal yang dipilih (_selectedDay)
    final selectedNotes = notes.where((note) {
      if (note.date == null) return false;
      return isSameDay(note.date, _selectedDay);
    }).toList();

    // Format tanggal terpilih untuk judul
    String formattedSelectedDate = 'Pilih Tanggal';
    if (_selectedDay != null) {
      const hariIndo = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const bulanIndo = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final dayName = hariIndo[_selectedDay!.weekday % 7];
      final monthName = bulanIndo[_selectedDay!.month - 1];
      formattedSelectedDate = '$dayName, ${_selectedDay!.day} $monthName ${_selectedDay!.year}';
    }

    return ListView(
      key: const ValueKey('CalendarList'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Kalender Card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            locale: 'id_ID',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            holidayPredicate: (day) {
              return notes.any((note) => 
                 note.type == 'holiday' &&
                 note.date?.year == day.year &&
                 note.date?.month == day.month &&
                 note.date?.day == day.day
              );
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primaryPurple),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primaryPurple),
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) {
                final months = [
                  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                ];
                return GestureDetector(
                  onTap: _showMonthYearPicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${months[day.month - 1]} ${day.year}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                
                bool hasTask = false;
                bool hasHoliday = false;

                for (var event in events) {
                  if (event is NoteModel) {
                    if (event.type == 'holiday') {
                      hasHoliday = true;
                    } else {
                      hasTask = true;
                    }
                  }
                }
                
                if (!hasTask && !hasHoliday) return const SizedBox();

                return Positioned(
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasHoliday)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      if (hasTask)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                    ],
                  ),
                );
              },
              selectedBuilder: (context, date, focusedDay) {
                bool isHoliday = date.weekday == DateTime.sunday || notes.any((note) => note.type == 'holiday' && note.date?.year == date.year && note.date?.month == date.month && note.date?.day == date.day);
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryPurple, width: 1.5),
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isHoliday ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              weekendTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.redAccent),
              holidayTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
              holidayDecoration: BoxDecoration(), // Menghilangkan default border/lingkaran
            ),
            eventLoader: (day) {
              return notes.where((note) {
                if (note.date == null || note.isCompleted) return false;
                return note.date!.year == day.year && 
                       note.date!.month == day.month && 
                       note.date!.day == day.day;
              }).toList();
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Keterangan / Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: AppColors.primaryPurple, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Tugas Aktif', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Inter')),
            const SizedBox(width: 20),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Libur', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Inter')),
          ],
        ),
        const SizedBox(height: 28),
        
        // Judul Bagian Catatan Harian Terpilih
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Harian',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedSelectedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Daftar Catatan untuk tanggal terpilih
        if (selectedNotes.isNotEmpty) ...[
          ...selectedNotes.map((n) => _buildNoteCard(n)),
        ] else ...[
          // Tampilan kosong yang cantik dan estetik
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 40,
                  color: AppColors.primaryPurple.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak Ada Catatan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buat catatan atau agenda baru untuk hari ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddNoteBottomSheet(initialDate: _selectedDay),
                    );
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Tambah Catatan'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
          ),
        ],
        const SizedBox(height: 80), // Jarak untuk FAB
      ],
    );
  }

  Widget _buildExpandableSection(String title, List<NoteModel> notes, {Color color = Colors.grey, bool initExpanded = true}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initExpanded,
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
        iconColor: color,
        collapsedIconColor: color,
        children: notes.map((n) => _buildNoteCard(n)).toList(),
      ),
    );
  }

  void _showNoteDetailModal(NoteModel note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note.type == 'holiday' ? 'Libur' : note.category,
                    style: const TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (note.type != 'holiday') ...[
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.primaryPurple),
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddNoteBottomSheet(noteToEdit: note),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      ref.read(plannerProvider.notifier).deleteNote(note.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              note.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (note.date != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(note.date!),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ],
              ),
            if (note.hasReminder && note.reminderLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.reminderLabel,
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            if (note.type != 'holiday')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: note.isCompleted ? Colors.orange : AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(plannerProvider.notifier).toggleNoteStatus(note.id);
                    Navigator.pop(context);
                  },
                  child: Text(note.isCompleted ? 'Tandai Belum Selesai' : 'Tandai Selesai', style: const TextStyle(fontSize: 16)),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    String dateStr = '';
    if (note.date != null) {
      dateStr = DateFormat('MM-dd').format(note.date!);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: note.isCompleted ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showNoteDetailModal(note),
          child: Row(
            children: [
              if (note.type == 'holiday')
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: Icon(Icons.star, size: 14, color: Colors.white),
                )
              else
                GestureDetector(
                  onTap: () => ref.read(plannerProvider.notifier).toggleNoteStatus(note.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: note.isCompleted ? AppColors.primaryPurple : Colors.transparent,
                      border: Border.all(
                        color: note.isCompleted ? AppColors.primaryPurple : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5) ?? Colors.grey,
                        width: 2,
                      ),
                    ),
                    width: 24,
                    height: 24,
                    child: note.isCompleted 
                        ? Icon(Icons.check, size: 16, color: Colors.white) 
                        : null,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: note.type == 'holiday' ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      child: Text(note.title),
                    ),
                    if (dateStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          note.type == 'holiday' ? 'Libur Nasional' : dateStr,
                          style: TextStyle(
                            fontSize: 12, 
                            color: note.type == 'holiday' ? Colors.red.withValues(alpha: 0.7) : Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (note.type != 'holiday')
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => ref.read(plannerProvider.notifier).deleteNote(note.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryActionDialog(String category) {
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
                  _showEditCategoryDialog(category);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.red),
                title: Text('Hapus Kategori'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCategory(category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(String oldCategory) {
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
                ref.read(plannerProvider.notifier).editCategory(oldCategory, tc.text.trim());
                if (_selectedCategory == oldCategory) {
                  setState(() => _selectedCategory = tc.text.trim());
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

  void _confirmDeleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kategori?'),
        content: Text('Catatan dalam kategori "$category" akan dipindahkan ke "Semua". Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(plannerProvider.notifier).deleteCategory(category);
              if (_selectedCategory == category) {
                setState(() => _selectedCategory = 'Semua');
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
