import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> initializeFallBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'falls',
      initialNotificationTitle: 'Giám sát ngã',
      initialNotificationContent: 'Khởi tạo...',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(),
  );
  // BẮT BUỘC: gọi startService
  service.startService();
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  // ĐẶT FOREGROUND NOTIFICATION NGAY
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Giám sát ngã',
      content: 'Đang hoạt động nền',
    );
  }

  // KHÔNG đặt await dài ở đây trước foreground
  // Khởi tạo Firebase (nhanh) sau đó
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // ignore nếu đã init
  }

  // Ví dụ timer định kỳ (thay thế vòng loop blocking)
  Timer.periodic(const Duration(seconds: 30), (t) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Giám sát ngã',
        content:
            'Cập nhật: ${DateTime.now().toIso8601String().substring(11, 19)}',
      );
    }
    // TODO: logic phát hiện ngã / cập nhật DB
  });

  // Lắng nghe yêu cầu cập nhật từ UI (tuỳ chọn)
  service.on('forceUpdate').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Giám sát ngã',
        content: 'Yêu cầu cập nhật thủ công',
      );
    }
  });
}
