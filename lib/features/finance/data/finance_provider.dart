import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';
import '../domain/models/transaction_model.dart';

class FinanceState {
  final List<TransactionModel> transactions;
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final bool isLoading;
  final String? error;

  const FinanceState({
    this.transactions = const [],
    this.incomeCategories = const ['Gaji', 'Bisnis', 'Investasi', 'Bonus'],
    this.expenseCategories = const ['Makanan', 'Transportasi', 'Belanja', 'Kesehatan', 'Hiburan', 'Tagihan', 'Pendidikan'],
    this.isLoading = false,
    this.error,
  });

  FinanceState copyWith({
    List<TransactionModel>? transactions,
    List<String>? incomeCategories,
    List<String>? expenseCategories,
    bool? isLoading,
    String? error,
  }) =>
      FinanceState(
        transactions: transactions ?? this.transactions,
        incomeCategories: incomeCategories ?? this.incomeCategories,
        expenseCategories: expenseCategories ?? this.expenseCategories,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );

  List<TransactionModel> get incomes =>
      transactions.where((t) => t.isIncome).toList();

  List<TransactionModel> get expenses =>
      transactions.where((t) => !t.isIncome).toList();

  double get totalIncome =>
      incomes.fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      expenses.fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;
}

class FinanceNotifier extends Notifier<FinanceState> {
  static const _collection = 'transactions';
  final _uuid = const Uuid();

  static const _incCatKey = 'finance_inc_categories';
  static const _expCatKey = 'finance_exp_categories';

  @override
  FinanceState build() {
    ref.watch(databaseProvider);
    Future.microtask(() => loadTransactions());
    return const FinanceState(isLoading: true);
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(databaseProvider);
      final raw = await db.readAll(_collection);
      final list = raw
          .map((j) => TransactionModel.fromJson(j))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      // Load Categories from SharedPreferences
      final prefs = ref.read(sharedPreferencesProvider);
      List<String> loadedInc = const ['Gaji', 'Bisnis', 'Investasi', 'Bonus'];
      List<String> loadedExp = const ['Makanan', 'Transportasi', 'Belanja', 'Kesehatan', 'Hiburan', 'Tagihan', 'Pendidikan'];

      final incStr = prefs.getString(_incCatKey);
      if (incStr != null) loadedInc = List<String>.from(jsonDecode(incStr));

      final expStr = prefs.getString(_expCatKey);
      if (expStr != null) loadedExp = List<String>.from(jsonDecode(expStr));

      state = FinanceState(
        transactions: list, 
        incomeCategories: loadedInc,
        expenseCategories: loadedExp,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat: $e');
    }
  }

  Future<void> addCategory(String category, bool isIncome) async {
    category = category.trim();
    if (category.isEmpty) return;
    
    final currentList = isIncome ? state.incomeCategories : state.expenseCategories;
    if (currentList.contains(category)) return;

    final newList = [...currentList, category];
    
    final prefs = ref.read(sharedPreferencesProvider);
    if (isIncome) {
      state = state.copyWith(incomeCategories: newList);
      await prefs.setString(_incCatKey, jsonEncode(newList));
    } else {
      state = state.copyWith(expenseCategories: newList);
      await prefs.setString(_expCatKey, jsonEncode(newList));
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    String? note,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(databaseProvider);
      final id = _uuid.v4();
      final now = DateTime.now();
      final tx = TransactionModel(
        id: id,
        title: title,
        amount: amount,
        type: type,
        category: category,
        note: note,
        date: date,
        createdAt: now,
      );
      await db.create(_collection, id, tx.toJson());
      state = state.copyWith(
        transactions: [tx, ...state.transactions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal menyimpan: $e');
    }
  }

  Future<void> editCategory(String oldCat, String newCat, bool isIncome) async {
    newCat = newCat.trim();
    final currentList = isIncome ? state.incomeCategories : state.expenseCategories;
    if (newCat.isEmpty || currentList.contains(newCat)) return;
    
    final prefs = ref.read(sharedPreferencesProvider);
    if (isIncome) {
      final newList = state.incomeCategories.map((c) => c == oldCat ? newCat : c).toList();
      state = state.copyWith(incomeCategories: newList);
      await prefs.setString(_incCatKey, jsonEncode(newList));
    } else {
      final newList = state.expenseCategories.map((c) => c == oldCat ? newCat : c).toList();
      state = state.copyWith(expenseCategories: newList);
      await prefs.setString(_expCatKey, jsonEncode(newList));
    }

    // Update transactions with new category
    final db = ref.read(databaseProvider);
    final txList = state.transactions.map((tx) {
      if (tx.isIncome == isIncome && tx.category == oldCat) {
        final updatedTx = tx.copyWith(category: newCat);
        db.update(_collection, tx.id, updatedTx.toJson()); // async in background
        return updatedTx;
      }
      return tx;
    }).toList();
    state = state.copyWith(transactions: txList);
  }

  Future<void> deleteCategory(String category, bool isIncome) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String fallbackCat;

    if (isIncome) {
      if (state.incomeCategories.length <= 1) return;
      final newList = state.incomeCategories.where((c) => c != category).toList();
      fallbackCat = newList.first;
      state = state.copyWith(incomeCategories: newList);
      await prefs.setString(_incCatKey, jsonEncode(newList));
    } else {
      if (state.expenseCategories.length <= 1) return;
      final newList = state.expenseCategories.where((c) => c != category).toList();
      fallbackCat = newList.first;
      state = state.copyWith(expenseCategories: newList);
      await prefs.setString(_expCatKey, jsonEncode(newList));
    }

    // Update transactions with fallback category
    final db = ref.read(databaseProvider);
    final txList = state.transactions.map((tx) {
      if (tx.isIncome == isIncome && tx.category == category) {
        final updatedTx = tx.copyWith(category: fallbackCat);
        db.update(_collection, tx.id, updatedTx.toJson()); // async update
        return updatedTx;
      }
      return tx;
    }).toList();
    state = state.copyWith(transactions: txList);
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final db = ref.read(databaseProvider);
      await db.delete(_collection, id);
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus: $e');
    }
  }
}

final financeProvider =
    NotifierProvider<FinanceNotifier, FinanceState>(() => FinanceNotifier());
