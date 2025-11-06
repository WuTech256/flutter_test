import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class FallDetectionBackgroundService {
  static Future<void> initialize(String username) async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'fall_detection_channel',
        initialNotificationTitle: 'Đang theo dõi ngã',
        initialNotificationContent: 'Hệ thống đang hoạt động',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Truyền username vào service
    service.invoke('setUsername', {'username': username});
    service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    String? username;

    service.on('setUsername').listen((event) {
      username = event!['username'] as String;
      _startMonitoring(service, username!);
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static void _startMonitoring(ServiceInstance service, String username) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final String userPath = 'locations/$username/Status';
    bool isFalling = false;
    Timer? alertTimer;
    int alertCount = 0;

    ref.child(userPath).onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null) return;

      final newStatus = data.toString().trim().toLowerCase();

      if (newStatus == 'fall' && !isFalling) {
        isFalling = true;
        alertCount = 0;

        // Gửi thông báo ngay lập tức
        await _sendNotification(
          title: '⚠️ Cảnh báo ngã!',
          body: '$username vừa bị ngã!',
        );

        // Lặp lại 30s/lần, tối đa 5 lần
        alertTimer?.cancel();
        alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
          alertCount++;
          if (alertCount >= 5 || !isFalling) {
            timer.cancel();
            return;
          }

          await _sendNotification(
            title: '⚠️ Cảnh báo ngã lần ${alertCount + 1}',
            body: '$username vẫn đang trong trạng thái ngã!',
          );
        });

        // Update foreground notification
        service.invoke('update', {
          'title': '⚠️ CẢNH BÁO NGÃ',
          'content': '$username đang ngã!',
        });
      } else if (newStatus != 'fall' && isFalling) {
        isFalling = false;
        alertTimer?.cancel();
        alertCount = 0;

        service.invoke('update', {
          'title': 'Đang theo dõi ngã',
          'content': 'Trạng thái bình thường',
        });
      }
    });
  }

  static Future<void> _sendNotification({
    required String title,
    required String body,
  }) async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fall_alert_channel',
          'Fall Alerts',
          channelDescription: 'Thông báo khi phát hiện ngã',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(DateTime.now().millisecond, title, body, details);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
