import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Histori setiap kali user menabung
class SavingsTransaction {
  final String id;
  final double amount;
  final DateTime createdAt;

  SavingsTransaction({
    required this.id,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsTransaction.fromJson(Map<String, dynamic> json) =>
      SavingsTransaction(
        id: json['id'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class SavingsModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String category;
  final String? imagePath;
  final String? imageUrl;
  final String? note;
  final DateTime createdAt;
  final DateTime? achievedAt;

  // Rencana pengisian
  final String savingFrequency; // 'harian' | 'mingguan' | 'bulanan'
  final double savingAmountPerPeriod;

  // Notifikasi
  final bool notificationEnabled;
  final int notificationHour;
  final int notificationMinute;
  final List<int> notificationDays; // 0=Minggu..6=Sabtu
  final int notificationDate; // 1-31 untuk bulanan

  // Pin ke dashboard
  final bool isPinned;

  // Histori simpanan
  final List<SavingsTransaction> transactions;

  SavingsModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
    this.imagePath,
    this.imageUrl,
    this.note,
    required this.createdAt,
    this.achievedAt,
    this.savingFrequency = 'mingguan',
    this.savingAmountPerPeriod = 0,
    this.notificationEnabled = false,
    this.notificationHour = 12,
    this.notificationMinute = 0,
    this.notificationDays = const [],
    this.notificationDate = 1,
    this.isPinned = false,
    this.transactions = const [],
  });

  // ── Computed Getters ────────────────────────────────────────
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final p = currentAmount / targetAmount;
    return p > 1.0 ? 1.0 : p;
  }

  double get remainingAmount {
    final diff = targetAmount - currentAmount;
    return diff < 0 ? 0 : diff;
  }

  bool get isAchieved => currentAmount >= targetAmount;

  String get countdownText {
    if (isAchieved) return 'Tercapai! 🎉';
    if (savingAmountPerPeriod <= 0) return '-';
    final periods = (remainingAmount / savingAmountPerPeriod).ceil();
    switch (savingFrequency) {
      case 'harian':
        return '$periods Hari Lagi';
      case 'mingguan':
        return '$periods Minggu Lagi';
      case 'bulanan':
        return '$periods Bulan Lagi';
      default:
        return '-';
    }
  }

  String get savingPlanLabel {
    if (savingAmountPerPeriod <= 0) return '';
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    switch (savingFrequency) {
      case 'harian':
        return '${fmt.format(savingAmountPerPeriod)} Perhari';
      case 'mingguan':
        return '${fmt.format(savingAmountPerPeriod)} Perminggu';
      case 'bulanan':
        return '${fmt.format(savingAmountPerPeriod)} Perbulan';
      default:
        return '';
    }
  }

  // ── CopyWith ────────────────────────────────────────────────
  SavingsModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? category,
    String? imagePath,
    String? imageUrl,
    String? note,
    DateTime? createdAt,
    DateTime? achievedAt,
    String? savingFrequency,
    double? savingAmountPerPeriod,
    bool? notificationEnabled,
    int? notificationHour,
    int? notificationMinute,
    List<int>? notificationDays,
    int? notificationDate,
    bool? isPinned,
    List<SavingsTransaction>? transactions,
  }) {
    return SavingsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAt ?? this.achievedAt,
      savingFrequency: savingFrequency ?? this.savingFrequency,
      savingAmountPerPeriod:
          savingAmountPerPeriod ?? this.savingAmountPerPeriod,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      notificationDays: notificationDays ?? this.notificationDays,
      notificationDate: notificationDate ?? this.notificationDate,
      isPinned: isPinned ?? this.isPinned,
      transactions: transactions ?? this.transactions,
    );
  }

  // ── Serialization ───────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'category': category,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'achievedAt': achievedAt?.toIso8601String(),
      'savingFrequency': savingFrequency,
      'savingAmountPerPeriod': savingAmountPerPeriod,
      'notificationEnabled': notificationEnabled,
      'notificationHour': notificationHour,
      'notificationMinute': notificationMinute,
      'notificationDays': notificationDays,
      'notificationDate': notificationDate,
      'isPinned': isPinned,
      'transactions':
          transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory SavingsModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    final rawTx = json['transactions'];
    final List<SavingsTransaction> txList = (rawTx is List)
        ? rawTx
            .map((e) =>
                SavingsTransaction.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    final rawDays = json['notificationDays'];
    final List<int> daysList = (rawDays is List)
        ? rawDays.map((e) => (e as num).toInt()).toList()
        : [];

    return SavingsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Umum',
      imagePath: json['imagePath'],
      imageUrl: json['imageUrl'],
      note: json['note'],
      createdAt: parseDate(json['createdAt']),
      achievedAt: parseOptionalDate(json['achievedAt']),
      savingFrequency: json['savingFrequency'] ?? 'mingguan',
      savingAmountPerPeriod:
          (json['savingAmountPerPeriod'] as num?)?.toDouble() ?? 0.0,
      notificationEnabled: json['notificationEnabled'] ?? false,
      notificationHour: (json['notificationHour'] as num?)?.toInt() ?? 12,
      notificationMinute:
          (json['notificationMinute'] as num?)?.toInt() ?? 0,
      notificationDays: daysList,
      notificationDate: (json['notificationDate'] as num?)?.toInt() ?? 1,
      isPinned: json['isPinned'] ?? false,
      transactions: txList,
    );
  }
}
