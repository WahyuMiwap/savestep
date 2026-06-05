import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../auth/data/auth_provider.dart';
import '../domain/models/note_model.dart';
import 'holiday_service.dart';

// State untuk menyimpan daftar notes dan kategori yang tersedia
class PlannerState {
  final List<NoteModel> notes;
  final List<String> categories;
  final List<NoteModel> holidays;

  const PlannerState({
    required this.notes,
    required this.categories,
    this.holidays = const [],
  });

  PlannerState copyWith({
    List<NoteModel>? notes,
    List<String>? categories,
    List<NoteModel>? holidays,
  }) {
    return PlannerState(
      notes: notes ?? this.notes,
      categories: categories ?? this.categories,
      holidays: holidays ?? this.holidays,
    );
  }

  // Getter pembantu yang menggabungkan notes pengguna dan tanggal merah
  List<NoteModel> get allNotes => [...notes, ...holidays];
}

class PlannerNotifier extends Notifier<PlannerState> {
  static const _notesKey = 'planner_notes';
  static const _categoriesKey = 'planner_categories';
  static const _defaultCategories = ['Semua', 'Kampus', 'Hutang', 'Wishlist'];

  @override
  PlannerState build() {
    ref.watch(databaseProvider);
    Future.microtask(() => _loadData());
    return const PlannerState(notes: [], categories: _defaultCategories);
  }

  String _getNotesKey() {
    final user = ref.read(authStateProvider).value;
    return 'planner_${user?.uid ?? 'guest'}_notes';
  }

  String _getCategoriesKey() {
    final user = ref.read(authStateProvider).value;
    return 'planner_${user?.uid ?? 'guest'}_categories';
  }

  Future<void> _loadData() async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    // Load Categories
    List<String> loadedCategories = _defaultCategories;
    final catString = prefs.getString(_getCategoriesKey());
    if (catString != null) {
      final List<dynamic> decoded = jsonDecode(catString);
      loadedCategories = decoded.cast<String>();
    }

    // Load Notes
    List<NoteModel> loadedNotes = [];
    final notesString = prefs.getString(_getNotesKey());
    if (notesString != null) {
      final List<dynamic> decoded = jsonDecode(notesString);
      loadedNotes = decoded.map((e) => NoteModel.fromJson(e)).toList();
    }

    state = PlannerState(notes: loadedNotes, categories: loadedCategories);

    // Load Holidays secara asynchronous tanpa blocking UI awal
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    try {
      final currentYear = DateTime.now().year;
      final holidayService = HolidayService();
      final fetchedHolidays = await holidayService.fetchIndonesianHolidays(currentYear);
      
      if (fetchedHolidays.isNotEmpty) {
         state = state.copyWith(holidays: fetchedHolidays);
      }
    } catch (e) {
      // Abaikan jika error internet dll.
    }
  }

  Future<void> _saveData() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_getCategoriesKey(), jsonEncode(state.categories));
    final notesJson = state.notes.map((e) => e.toJson()).toList();
    await prefs.setString(_getNotesKey(), jsonEncode(notesJson));
    _rescheduleNotifications();
  }

  void _rescheduleNotifications() {
    final notificationService = NotificationService();
    notificationService.cancelAllNotifications();

    int idCounter = 0;
    for (final note in state.notes) {
      if (!note.hasReminder || note.isCompleted) continue;

      final scheduledDate = note.scheduledReminderDateTime;
      if (scheduledDate == null) continue;

      // Buat deskripsi offset yang human-readable
      final offsetDesc = note.reminderValue == 0
          ? 'Tepat pada waktunya'
          : '${note.reminderValue} ${note.reminderUnit.label} sebelum acara';

      notificationService.scheduleNotification(
        id: idCounter++,
        title: 'Catatan - ${note.title}',
        body: '$offsetDesc — kategori ${note.category}',
        scheduledDate: scheduledDate,
      );
    }
  }

  Future<void> addCategory(String category) async {
    if (state.categories.contains(category) || category.trim().isEmpty) return;
    final newCategories = [...state.categories, category.trim()];
    state = state.copyWith(categories: newCategories);
    await _saveData();
  }

  Future<void> editCategory(String oldCat, String newCat) async {
    if (newCat.trim().isEmpty || state.categories.contains(newCat)) return;
    
    // Update daftar kategori
    final newCategories = state.categories.map((c) => c == oldCat ? newCat.trim() : c).toList();
    
    // Pindahkan semua catatan yang menggunakan kategori lama ke kategori baru
    final newNotes = state.notes.map((n) {
      if (n.category == oldCat) return n.copyWith(category: newCat.trim());
      return n;
    }).toList();
    
    state = state.copyWith(categories: newCategories, notes: newNotes);
    await _saveData();
  }

  Future<void> deleteCategory(String category) async {
    // Sisakan setidaknya satu kategori (Umum/Semua)
    if (state.categories.length <= 1) return;

    final newCategories = state.categories.where((c) => c != category).toList();
    // Default fallback kategori jika kategori ini dihapus
    final fallbackCat = newCategories.firstWhere((c) => c == 'Semua', orElse: () => newCategories.first);
    
    final newNotes = state.notes.map((n) {
      if (n.category == category) return n.copyWith(category: fallbackCat);
      return n;
    }).toList();

    state = state.copyWith(categories: newCategories, notes: newNotes);
    await _saveData();
  }

  Future<void> addNote(NoteModel note) async {
    final newNotes = [...state.notes, note];
    state = state.copyWith(notes: newNotes);
    await _saveData();
  }

  Future<void> updateNote(NoteModel note) async {
    final newNotes = state.notes.map((e) => e.id == note.id ? note : e).toList();
    state = state.copyWith(notes: newNotes);
    await _saveData();
  }

  Future<void> toggleNoteStatus(String id) async {
    // Abaikan jika id tersebut adalah holiday yang di-generate otomatis
    if (state.holidays.any((h) => h.id == id)) return;

    final newNotes = state.notes.map((e) {
      if (e.id == id) {
        return e.copyWith(isCompleted: !e.isCompleted);
      }
      return e;
    }).toList();
    state = state.copyWith(notes: newNotes);
    await _saveData();
  }
  
  Future<void> deleteNote(String id) async {
    final newNotes = state.notes.where((e) => e.id != id).toList();
    state = state.copyWith(notes: newNotes);
    await _saveData();
  }
}

final plannerProvider = NotifierProvider<PlannerNotifier, PlannerState>(() {
  return PlannerNotifier();
});
