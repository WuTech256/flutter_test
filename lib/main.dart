// (Không đổi nội dung trừ khi cần: đảm bảo đã gọi NotificationService.init trước dùng)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/fall_detection_background_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:toanvuthinh/screens/splash.dart';
import 'package:toanvuthinh/screens/home_screen.dart';
import 'package:toanvuthinh/screens/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FallDetectionBackgroundService.initialize(username);
            });
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
