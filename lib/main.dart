// (Không đổi nội dung trừ khi cần: đảm bảo đã gọi NotificationService.init trước dùng)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/fall_detection_background_service.dart';
import 'services/medication_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'screens/splash.dart';
import 'screens/home_screen.dart';
import 'screens/auth.dart';

// Background FCM handler
@pragma('vm:entry-point')
Future<void> _fcmBackground(RemoteMessage message) async {
  // Đảm bảo Firebase & notification init trong isolate background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  final n = message.notification;
  if (n != null) {
    await NotificationService.showInstantNotification(
      title: n.title ?? 'Thông báo',
      body: n.body ?? '',
      id: 999,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  await NotificationService.init();

  // FCM setup
  FirebaseMessaging.onBackgroundMessage(_fcmBackground);
  final messaging = FirebaseMessaging.instance;

  // Android 13+ permission & iOS permission
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Đăng ký listener foreground FCM
    FirebaseMessaging.onMessage.listen((msg) async {
      final n = msg.notification;
      if (n != null) {
        await NotificationService.showInstantNotification(
          title: n.title ?? 'Thông báo',
          body: n.body ?? '',
          id: 1000,
        );
      }
    });
    return MaterialApp(
      title: 'FlutterChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF37015C)),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            final username = user.email?.split('@').first ?? user.uid;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              FallDetectionBackgroundService.initialize(username);
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                await FirebaseDatabase.instance.ref('users/${user.uid}').update(
                  {'fcmToken': token, 'username': username},
                );
              }
              // FIX: dùng instance.onTokenRefresh
              FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
                await FirebaseDatabase.instance.ref('users/${user.uid}').update(
                  {'fcmToken': t},
                );
              });
              final meds = await MedicationService().fetchAll(user.uid);
              for (final m in meds) {
                if (m.notificationId != null) {
                  await NotificationService.scheduleDailyMedication(
                    id: m.notificationId!,
                    title: 'Nhắc uống thuốc: ${m.name}',
                    body: 'Liều: ${m.dosage} • ${m.quantity} viên',
                    hour: m.time.hour,
                    minute: m.time.minute,
                  );
                }
              }
            });
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
