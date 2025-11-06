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

    // Xin quyền & subscribe topic một lần
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.subscribeToTopic(widget.username);

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
      setState(() => _status = isFallRaw ? '⚠️ NGÃ' : 'Bình thường');
    });

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
    final color = isFall ? Colors.red : Colors.green;
    return Scaffold(
      appBar: AppBar(title: const Text('Trạng thái ngã')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFall ? Icons.warning : Icons.health_and_safety,
              size: 100,
              color: color,
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 40),
            // Nút test viết giá trị lên DB
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _ref.set(false), // giả lập ngã
                  child: const Text('Giả lập NGÃ'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _ref.set(true), // trở lại bình thường
                  child: const Text('Bình thường'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
