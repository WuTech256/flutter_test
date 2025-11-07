import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FallStatusScreen extends StatefulWidget {
  final String username;
  const FallStatusScreen({super.key, required this.username});

  @override
  State<FallStatusScreen> createState() => _FallStatusScreenState();
}

class _FallStatusScreenState extends State<FallStatusScreen> {
  late DatabaseReference _ref;
  String _status = 'Đang tải...';
  final FlutterLocalNotificationsPlugin _flutterLocalNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _ref = FirebaseDatabase.instance.ref('locations/${widget.username}/Status');

    // Cấp quyền và subscribe topic FCM
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.subscribeToTopic(widget.username);

    // Lắng nghe thay đổi DB
    _ref.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (!mounted) return;
      if (raw == null) {
        setState(() => _status = 'Không có dữ liệu');
        return;
      }
      final s = raw.toString().trim().toLowerCase();
      final isFallRaw =
          (raw is bool && raw == false) || s == 'fall' || s == 'false';
      setState(() => _status = isFallRaw ? '⚠️ NGÃ' : '✅ Bình thường');
    });

    // Lắng nghe thông báo từ Firebase Cloud Messaging
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        _flutterLocalNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          n.title,
          n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'falls',
              'Fall Alerts',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFall = _status.startsWith('⚠️');
    final color = isFall ? Colors.redAccent : Colors.green;
    final bgColor = isFall ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Giám sát trạng thái ngã'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      isFall ? Icons.warning_amber_rounded : Icons.health_and_safety_rounded,
                      size: 120,
                      color: color,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFall
                          ? "Phát hiện ngã! Hãy kiểm tra ngay."
                          : "Mọi thứ đang ổn định.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Nút test giá trị (ẩn khi triển khai thật)
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     ElevatedButton.icon(
              //       onPressed: () => _ref.set(false),
              //       icon: const Icon(Icons.warning_amber_rounded),
              //       label: const Text('Giả lập NGÃ'),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.redAccent,
              //         foregroundColor: Colors.white,
              //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(16),
              //         ),
              //       ),
              //     ),
              //     const SizedBox(width: 20),
              //     ElevatedButton.icon(
              //       onPressed: () => _ref.set(true),
              //       icon: const Icon(Icons.check_circle_outline),
              //       label: const Text('Bình thường'),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.green,
              //         foregroundColor: Colors.white,
              //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(16),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
