import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return TransactionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: json['category'] ?? 'Lainnya',
      note: json['note'],
      date: parseDate(json['date']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
