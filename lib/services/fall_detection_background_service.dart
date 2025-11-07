import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeFallBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'falls',
      initialNotificationTitle: 'Giám sát ngã',
      initialNotificationContent: 'Đang chạy nền...',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  // Đặt notification foreground NGAY LẬP TỨC
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Giám sát ngã',
      content: 'Hoạt động nền đang theo dõi...',
    );
  }

  // Trì hoãn nhẹ nếu cần trước tác vụ nặng
  // await Future.delayed(const Duration(milliseconds: 200));

  // Sau đó mới khởi tạo Firebase / sensor / location
  // await Firebase.initializeApp();
  // startLocationStream();
  // startFallDetectionLoop();

  service.on('update').listen((event) {
    // cập nhật notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Giám sát ngã',
        content: 'Trạng thái: ${event?['status'] ?? 'đang chạy'}',
      );
    }
  });
}
