import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

Future<void> initializeFallBackgroundService() async {
  // -------------------------------------------------------------
  // 1) KHỞI TẠO notification channel — BẮT BUỘC CHO FOREGROUND SERVICE
  // -------------------------------------------------------------
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await _localNotif.initialize(initSettings);

  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'falls', // MUST MATCH notificationChannelId
      'Fall Detection Service',
      description: 'Service theo dõi phát hiện ngã',
      importance: Importance.low, // foreground service nên để low
    );

    final android = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(channel);
  }

  // -------------------------------------------------------------
  // 2) CẤU HÌNH BACKGROUND SERVICE
  // -------------------------------------------------------------
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'falls', // TRÙNG CHANNEL
      initialNotificationTitle: 'Giám sát ngã',
      initialNotificationContent: 'Khởi tạo...',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(),
  );

  // -------------------------------------------------------------
  // 3) KHỞI ĐỘNG SERVICE
  // -------------------------------------------------------------
  service.startService();
}

// ------------------------------------------------------------------
// 4) SERVICE ENTRY POINT — CHẠY TRONG ISOLATE RIÊNG
// ------------------------------------------------------------------
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  // BẮT BUỘC: setForegroundNotificationInfo trong 5 giây đầu
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Giám sát ngã',
      content: 'Đang hoạt động nền',
    );
  }

  // Load Firebase trong isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // ------------------------------------------------------------------
  // NHIỆM VỤ LẶP LẠI (logic phát hiện ngã của bạn thêm vào đây)
  // ------------------------------------------------------------------
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Giám sát ngã',
        content:
            'Cập nhật lúc: ${DateTime.now().toIso8601String().substring(11, 19)}',
      );
    }

    // TODO: Thêm logic phát hiện ngã ↓↓↓↓↓
    // detectFall();
    // updateDatabase();
  });
}
