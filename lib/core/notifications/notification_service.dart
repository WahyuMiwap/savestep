import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // Atur timezone ke WIB (Asia/Jakarta) agar waktu notifikasi akurat
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    if (!kIsWeb) {
      // Minta izin POST_NOTIFICATIONS (Android 13+)
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('Izin notifikasi ditolak oleh pengguna.');
      }

      // Minta izin SCHEDULE_EXACT_ALARM (Android 12+ / API 31+)
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      if (!exactAlarmStatus.isGranted) {
        debugPrint('Izin alarm presisi ditolak. Notifikasi mungkin terlambat.');
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'savestep_channel_v2',
          'SaveStep Reminders',
          channelDescription: 'Notifikasi pengingat tugas dan tabungan SaveStep',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          ticker: 'SaveStep Reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required DateTime firstScheduledDate,
    required DateTimeComponents matchDateTimeComponents,
  }) async {
    // If the scheduled date is in the past, adjust it to the future based on recurrence
    tz.TZDateTime scheduled = tz.TZDateTime.from(firstScheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    while (scheduled.isBefore(now)) {
      if (matchDateTimeComponents == DateTimeComponents.time) {
        scheduled = scheduled.add(const Duration(days: 1));
      } else if (matchDateTimeComponents == DateTimeComponents.dayOfWeekAndTime) {
        scheduled = scheduled.add(const Duration(days: 7));
      } else if (matchDateTimeComponents == DateTimeComponents.dayOfMonthAndTime) {
        // approximate next month
        int nextMonth = scheduled.month + 1;
        int nextYear = scheduled.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int nextDay = scheduled.day;
        if (nextDay > daysInNextMonth) nextDay = daysInNextMonth;
        scheduled = tz.TZDateTime(tz.local, nextYear, nextMonth, nextDay, scheduled.hour, scheduled.minute);
      } else {
        break;
      }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      matchDateTimeComponents: matchDateTimeComponents,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'savestep_channel_v2',
          'SaveStep Reminders',
          channelDescription: 'Notifikasi pengingat tugas dan tabungan SaveStep',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          ticker: 'SaveStep Reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    // Di versi 21, cancel menggunakan named parameter id
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
