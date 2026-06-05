import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/models/savings_model.dart';

class SavingsState {
  final List<SavingsModel> goals;
  final bool isLoading;
  final String? error;

  const SavingsState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  SavingsState copyWith({
    List<SavingsModel>? goals,
    bool? isLoading,
    String? error,
  }) {
    return SavingsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<SavingsModel> get ongoing => goals.where((g) => !g.isAchieved).toList();
  List<SavingsModel> get achieved => goals.where((g) => g.isAchieved).toList();
  SavingsModel? get pinnedGoal {
    final pinned = goals.where((g) => g.isPinned).toList();
    return pinned.isNotEmpty ? pinned.first : null;
  }
}

class SavingsNotifier extends Notifier<SavingsState> {
  static const _collectionName = 'savings_goals';
  final _uuid = const Uuid();

  @override
  SavingsState build() {
    ref.watch(databaseProvider);
    Future.microtask(() => loadSavings());
    return const SavingsState(isLoading: true);
  }

  Future<void> loadSavings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(databaseProvider);
      final rawData = await db.readAll(_collectionName);
      final loaded = rawData
          .map((json) => SavingsModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = SavingsState(goals: loaded, isLoading: false);
      _rescheduleNotifications();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Gagal memuat data tabungan: $e');
    }
  }

  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required String category,
    required String savingFrequency,
    required double savingAmountPerPeriod,
    bool notificationEnabled = false,
    int notificationHour = 12,
    int notificationMinute = 0,
    List<int> notificationDays = const [],
    int notificationDate = 1,
    String? imagePath,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(databaseProvider);
      final id = _uuid.v4();

      final newGoal = SavingsModel(
        id: id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        category: category,
        imagePath: imagePath,
        note: note,
        createdAt: DateTime.now(),
        savingFrequency: savingFrequency,
        savingAmountPerPeriod: savingAmountPerPeriod,
        notificationEnabled: notificationEnabled,
        notificationHour: notificationHour,
        notificationMinute: notificationMinute,
        notificationDays: notificationDays,
        notificationDate: notificationDate,
        transactions: const [],
      );

      await db.create(_collectionName, id, newGoal.toJson());
      state = state.copyWith(
        goals: [newGoal, ...state.goals],
        isLoading: false,
      );
      _rescheduleNotifications();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Gagal menambah tabungan: $e');
    }
  }

  /// Deposit uang ke tabungan — mencatat transaksi & otomatis set achievedAt
  Future<void> deposit({
    required String id,
    required double amount,
  }) async {
    try {
      final db = ref.read(databaseProvider);
      final idx = state.goals.indexWhere((g) => g.id == id);
      if (idx == -1) return;

      final old = state.goals[idx];
      final newTotal = old.currentAmount + amount;
      final newTx = SavingsTransaction(
        id: _uuid.v4(),
        amount: amount,
        createdAt: DateTime.now(),
      );

      final updatedGoal = old.copyWith(
        currentAmount: newTotal,
        achievedAt:
            newTotal >= old.targetAmount ? DateTime.now() : old.achievedAt,
        transactions: [newTx, ...old.transactions],
      );

      await db.update(_collectionName, id, updatedGoal.toJson());

      final updated = [...state.goals];
      updated[idx] = updatedGoal;
      state = state.copyWith(goals: updated);
      _rescheduleNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Gagal menyimpan: $e');
    }
  }

  Future<void> editGoal({
    required String id,
    required String title,
    required double targetAmount,
    required String category,
    required String savingFrequency,
    required double savingAmountPerPeriod,
    bool notificationEnabled = false,
    int notificationHour = 12,
    int notificationMinute = 0,
    List<int> notificationDays = const [],
    int notificationDate = 1,
    String? imagePath,
    String? note,
  }) async {
    try {
      final db = ref.read(databaseProvider);
      final idx = state.goals.indexWhere((g) => g.id == id);
      if (idx == -1) return;

      final updatedGoal = state.goals[idx].copyWith(
        title: title,
        targetAmount: targetAmount,
        category: category,
        imagePath: imagePath,
        note: note,
        savingFrequency: savingFrequency,
        savingAmountPerPeriod: savingAmountPerPeriod,
        notificationEnabled: notificationEnabled,
        notificationHour: notificationHour,
        notificationMinute: notificationMinute,
        notificationDays: notificationDays,
        notificationDate: notificationDate,
      );

      await db.update(_collectionName, id, updatedGoal.toJson());

      final updated = [...state.goals];
      updated[idx] = updatedGoal;
      state = state.copyWith(goals: updated);
      _rescheduleNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengedit tabungan: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final db = ref.read(databaseProvider);
      await db.delete(_collectionName, id);
      state = state.copyWith(
        goals: state.goals.where((g) => g.id != id).toList(),
      );
      _rescheduleNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus tabungan: $e');
    }
  }

  /// Toggle pin — hanya 1 goal yang bisa di-pin sekaligus
  Future<void> togglePin(String id) async {
    try {
      final db = ref.read(databaseProvider);
      final updated = <SavingsModel>[];

      for (final g in state.goals) {
        if (g.id == id) {
          // Toggle pin untuk goal yang ditekan
          final toggled = g.copyWith(isPinned: !g.isPinned);
          await db.update(_collectionName, g.id, toggled.toJson());
          updated.add(toggled);
        } else if (g.isPinned) {
          // Un-pin semua goal lain
          final unpinned = g.copyWith(isPinned: false);
          await db.update(_collectionName, g.id, unpinned.toJson());
          updated.add(unpinned);
        } else {
          updated.add(g);
        }
      }

      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengubah pin: $e');
    }
  }

  void _rescheduleNotifications() {
    for (final goal in state.goals) {
      if (goal.isAchieved || !goal.notificationEnabled) {
        _cancelGoalNotifications(goal);
        continue;
      }
      _scheduleGoalNotification(goal);
    }
  }

  void _cancelGoalNotifications(SavingsModel goal) {
    final notificationService = NotificationService();
    // Daily/Monthly uses 1 ID
    notificationService.cancelNotification(goal.id.hashCode);
    // Weekly uses up to 7 IDs
    for (int i=0; i<7; i++) {
      notificationService.cancelNotification('${goal.id}_$i'.hashCode);
    }
  }

  void _scheduleGoalNotification(SavingsModel goal) {
    final notificationService = NotificationService();
    _cancelGoalNotifications(goal); // Cancel old ones first

    if (goal.savingFrequency == 'harian') {
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day, goal.notificationHour, goal.notificationMinute);
      notificationService.scheduleRecurringNotification(
        id: goal.id.hashCode,
        title: 'Tabungan - ${goal.title}',
        body: 'Waktunya menabung Harian!',
        firstScheduledDate: scheduledDate,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else if (goal.savingFrequency == 'mingguan' && goal.notificationDays.isNotEmpty) {
      final now = DateTime.now();
      for (final day in goal.notificationDays) {
        // day: 0=Minggu, 1=Senin.. tapi DateTime.weekday: 1=Senin, 7=Minggu
        int targetWeekday = day == 0 ? 7 : day;
        int daysUntil = targetWeekday - now.weekday;
        if (daysUntil < 0) daysUntil += 7;
        
        final scheduledDate = DateTime(now.year, now.month, now.day + daysUntil, goal.notificationHour, goal.notificationMinute);
        
        notificationService.scheduleRecurringNotification(
          id: '${goal.id}_$day'.hashCode,
          title: 'Tabungan - ${goal.title}',
          body: 'Waktunya menabung Mingguan!',
          firstScheduledDate: scheduledDate,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else if (goal.savingFrequency == 'bulanan') {
      final now = DateTime.now();
      int targetDay = goal.notificationDate;
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      if (targetDay > daysInMonth) targetDay = daysInMonth;
      
      final scheduledDate = DateTime(now.year, now.month, targetDay, goal.notificationHour, goal.notificationMinute);
      
      notificationService.scheduleRecurringNotification(
        id: goal.id.hashCode,
        title: 'Tabungan - ${goal.title}',
        body: 'Waktunya menabung Bulanan!',
        firstScheduledDate: scheduledDate,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }
  }
}

final savingsProvider =
    NotifierProvider<SavingsNotifier, SavingsState>(() => SavingsNotifier());
