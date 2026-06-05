import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Unit waktu untuk pengingat relatif sebelum acara
enum ReminderUnit { menit, jam, hari, minggu }

extension ReminderUnitExtension on ReminderUnit {
  String get label {
    switch (this) {
      case ReminderUnit.menit:
        return 'Menit';
      case ReminderUnit.jam:
        return 'Jam';
      case ReminderUnit.hari:
        return 'Hari';
      case ReminderUnit.minggu:
        return 'Minggu';
    }
  }

  String get value {
    return name; // 'menit', 'jam', 'hari', 'minggu'
  }

  /// Konversi ke Duration untuk kalkulasi jadwal
  Duration toDuration(int amount) {
    switch (this) {
      case ReminderUnit.menit:
        return Duration(minutes: amount);
      case ReminderUnit.jam:
        return Duration(hours: amount);
      case ReminderUnit.hari:
        return Duration(days: amount);
      case ReminderUnit.minggu:
        return Duration(days: amount * 7);
    }
  }

  static ReminderUnit fromString(String s) {
    switch (s) {
      case 'jam':
        return ReminderUnit.jam;
      case 'hari':
        return ReminderUnit.hari;
      case 'minggu':
        return ReminderUnit.minggu;
      default:
        return ReminderUnit.menit;
    }
  }
}

class NoteModel {
  final String id;
  final String title;
  final DateTime? date;
  final String category;
  final String type; // 'deadline', 'holiday'
  final bool isCompleted;

  // Fitur Pengingat
  final bool hasReminder;
  final String? reminderTime; // Jam notif muncul, Format "HH:mm"
  final int reminderValue;    // Angka offset sebelumnya (misal: 15)
  final ReminderUnit reminderUnit; // Unit offset (menit/jam/hari/minggu)

  NoteModel({
    String? id,
    required this.title,
    this.date,
    required this.category,
    this.type = 'deadline',
    this.isCompleted = false,
    this.hasReminder = false,
    this.reminderTime,
    this.reminderValue = 0,
    this.reminderUnit = ReminderUnit.menit,
  }) : id = id ?? uuid.v4();

  /// Hitung DateTime absolut kapan notifikasi harus muncul
  DateTime? get scheduledReminderDateTime {
    if (!hasReminder || date == null || reminderTime == null) return null;

    final timeParts = reminderTime!.split(':');
    if (timeParts.length != 2) return null;

    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    // Jika reminderValue == 0, notif tepat di jam yang dipilih pada hari H
    final baseDateTime = DateTime(
      date!.year,
      date!.month,
      date!.day,
      hour,
      minute,
    );

    if (reminderValue == 0) return baseDateTime;

    return baseDateTime.subtract(reminderUnit.toDuration(reminderValue));
  }

  /// Label ringkas untuk ditampilkan di UI
  String get reminderLabel {
    if (!hasReminder || reminderTime == null) return '';
    final timeStr = reminderTime!;
    if (reminderValue == 0) {
      return 'Jam $timeStr (tepat waktu)';
    }
    return '${reminderValue} ${reminderUnit.label} sebelumnya, jam $timeStr';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date?.toIso8601String(),
      'category': category,
      'type': type,
      'isCompleted': isCompleted,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime,
      'reminderValue': reminderValue,
      'reminderUnit': reminderUnit.value,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      category: json['category'] ?? 'Lainnya',
      type: json['type'] ?? 'deadline',
      isCompleted: json['isCompleted'] ?? false,
      hasReminder: json['hasReminder'] ?? false,
      reminderTime: json['reminderTime'],
      reminderValue: json['reminderValue'] ?? 0,
      reminderUnit: ReminderUnitExtension.fromString(json['reminderUnit'] ?? 'menit'),
    );
  }

  NoteModel copyWith({
    String? title,
    DateTime? date,
    String? category,
    String? type,
    bool? isCompleted,
    bool? hasReminder,
    String? reminderTime,
    int? reminderValue,
    ReminderUnit? reminderUnit,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderValue: reminderValue ?? this.reminderValue,
      reminderUnit: reminderUnit ?? this.reminderUnit,
    );
  }
}
