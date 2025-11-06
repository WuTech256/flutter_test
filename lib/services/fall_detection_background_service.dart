import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // để chắc plugin load
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';
import 'dart:async';

class FallDetectionBackgroundService {
  static bool _configured = false;
  static StreamSubscription<DatabaseEvent>? _statusSub;

  static Future<void> initialize(String username) async {
    debugPrint('[FallService] initialize called for $username');
    if (_configured) {
      FlutterBackgroundService().invoke('setUsername', {'username': username});
      return;
    }
    _configured = true;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'fall_detection_channel',
        initialNotificationTitle: 'Theo dõi ngã',
        initialNotificationContent: 'Trạng thái bình thường',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    final started = await service.startService();
    debugPrint('[FallService] startService result: $started');
    service.invoke('setUsername', {'username': username});
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    // Đăng ký plugin trong isolate nền
    DartPluginRegistrant.ensureInitialized();

    debugPrint('[FallService] onStart isolate running');

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[FallService] Firebase initialized');
    } catch (e) {
      debugPrint('[FallService] Firebase init error: $e');
    }

    await NotificationService.init();
    debugPrint('[FallService] NotificationService.init done');

    String? username;

    service.on('setUsername').listen((event) {
      final data = event;
      debugPrint('[FallService] setUsername event: $data');
      if (data != null) {
        final newUser = data['username'] as String;
        if (newUser != username) {
          username = newUser;
          _listenStatus(service, username!);
        }
      }
    });

    service.on('update').listen((event) {
      final title = event?['title'] ?? 'Theo dõi ngã';
      final content = event?['content'] ?? 'Trạng thái bình thường';
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(title: title, content: content);
      }
    });

    service.on('stopService').listen((_) {
      debugPrint('[FallService] stopService received');
      _statusSub?.cancel();
      service.stopSelf();
    });
  }

  static void _listenStatus(ServiceInstance service, String username) {
    _statusSub?.cancel();
    final ref = FirebaseDatabase.instance.ref('locations/$username/Status');
    debugPrint('[FallService] Listening path: locations/$username/Status');

    bool falling = false;

    _statusSub = ref.onValue.listen(
      (event) async {
        final raw = event.snapshot.value;
        debugPrint('[FallService] Firebase value: $raw');
        if (raw == null) return;
        final status = raw.toString().trim().toLowerCase();

        if (status == 'fall' && !falling) {
          falling = true;
          debugPrint('[FallService] Detected FALL -> notify');
          await NotificationService.showInstantNotification(
            title: '⚠️ Ngã!',
            body: '$username vừa bị ngã',
            id: 100,
          );
          service.invoke('update', {
            'title': '⚠️ CẢNH BÁO NGÃ',
            'content': '$username đang ngã',
          });
        } else if (status != 'fall' && falling) {
          falling = false;
          debugPrint('[FallService] Status back to normal');
          service.invoke('update', {
            'title': 'Theo dõi ngã',
            'content': 'Trạng thái bình thường',
          });
        }
      },
      onError: (e) {
        debugPrint('[FallService] Firebase listen error: $e');
      },
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    // iOS background handler
    return true;
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
