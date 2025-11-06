import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notif.initialize(initSettings);

    // 🔔 Tạo các notification channel (Android 8+ bắt buộc)
    const AndroidNotificationChannel medChannel = AndroidNotificationChannel(
      'med_channel',
      'Medication Reminders',
      description: 'Nhắc nhở uống thuốc hàng ngày',
      importance: Importance.max,
    );

    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Channel',
      description: 'Test single notification',
      importance: Importance.max,
    );

    final androidPlugin =
        _notif.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(medChannel);
    await androidPlugin?.createNotificationChannel(testChannel);

    // 🔐 Xin quyền thông báo cho Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    print('✅ Notification channels created');
  }

  /// 🕒 Lịch hàng ngày (ví dụ nhắc uống thuốc)
  static Future<void> scheduleDailyMedication({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('📅 Schedule for: $scheduledDate');

    const androidDetails = AndroidNotificationDetails(
      'med_channel',
      'Medication Reminders',
      channelDescription: 'Nhắc nhở uống thuốc hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _notif.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp hàng ngày
    );
  }

  /// ❌ Hủy 1 notification
  static Future<void> cancelNotification(int id) async {
    await _notif.cancel(id);
  }

  /// ❌ Hủy tất cả notification
  static Future<void> cancelAllNotifications() async {
    await _notif.cancelAll();
  }

  /// 🚨 Test alarm sau 10 giây
  static Future<void> testAlarm() async {
  final now = tz.TZDateTime.now(tz.local);
  final scheduled = now.add(const Duration(seconds: 10));

  print('🕓 Now (tz): $now');
  print('⏰ Scheduled for: $scheduled (${scheduled.timeZoneName})');

  const androidDetails = AndroidNotificationDetails(
    'test_channel',
    'Test Channel',
    channelDescription: 'Test single notification',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  await _notif.zonedSchedule(
    999,
    'Test Alarm',
    'This is a 10s test alarm',
    scheduled,
    const NotificationDetails(android: androidDetails),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}


  /// 🧪 Hiển thị thông báo ngay lập tức (test)
  static Future<void> showImmediateTest() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      channelDescription: 'Immediate test notification',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    await _notif.show(
      111,
      'Immediate Test',
      'If you see this, notifications are working!',
      const NotificationDetails(android: androidDetails),
    );

    print('✅ Immediate notification shown');
  }

    /// 🚨 Gửi thông báo cảnh báo ngã ngay lập tức
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fall_alert_channel',
      'Fall Alerts',
      channelDescription: 'Thông báo khi phát hiện ngã',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _notif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );

    print('🚨 Fall alert notification shown: $title - $body');
  }
}
