import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/notification_service.dart';
import '../services/fall_detection_background_service.dart';

class FallStatusScreen extends StatefulWidget {
  final String username; // ví dụ: "toanvd25062001"

  const FallStatusScreen({super.key, required this.username});

  @override
  State<FallStatusScreen> createState() => _FallStatusScreenState();
}

class _FallStatusScreenState extends State<FallStatusScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  late final String _userPath;
  String _status = 'Đang tải...';
  bool _isFalling = false;
  Timer? _alertTimer;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _userPath = 'locations/${widget.username}/Status';
    _listenToStatus();

    // Khởi động background service
    FallDetectionBackgroundService.initialize(widget.username);
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    // Không stop service ở đây nếu muốn tiếp tục chạy ngầm
    super.dispose();
  }

  /// 🔄 Lắng nghe thay đổi status trong Realtime Database
  void _listenToStatus() {
    _ref.child(_userPath).onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final newStatus = data.toString().trim().toLowerCase();

      setState(() {
        _status = newStatus == 'fall' ? 'Ngã' : 'Bình thường';
      });

      if (newStatus == 'fall' && !_isFalling) {
        _isFalling = true;
        _startFallAlert();
      } else if (newStatus != 'fall' && _isFalling) {
        _isFalling = false;
        _stopFallAlert();
      }
    });
  }

  /// 🚨 Khi phát hiện ngã, gửi thông báo 5 lần cách nhau 30s
  void _startFallAlert() async {
    _alertCount = 0;

    // Gửi thông báo ngay lập tức
    await NotificationService.showInstantNotification(
      title: '⚠️ Cảnh báo ngã!',
      body: '${widget.username} vừa bị ngã!',
    );

    // Lặp lại 30s/lần, tối đa 5 lần
    _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      _alertCount++;
      if (_alertCount >= 5 || !_isFalling) {
        timer.cancel();
        return;
      }

      await NotificationService.showInstantNotification(
        title: '⚠️ Cảnh báo ngã lần ${_alertCount + 1}',
        body: '${widget.username} vẫn đang trong trạng thái ngã!',
      );
    });
  }

  /// ✅ Khi hết ngã thì dừng gửi thông báo
  void _stopFallAlert() {
    _alertTimer?.cancel();
    _alertTimer = null;
    _alertCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFall = _status.toLowerCase() == 'ngã';

    return Scaffold(
      appBar: AppBar(
        title: Text('Theo dõi ngã - ${widget.username}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isFall
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFall ? Colors.red : Colors.green,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFall ? Icons.warning_amber_rounded : Icons.check_circle,
                color: isFall ? Colors.red : Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                _status.toUpperCase(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isFall ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isFall
                    ? '⚠️ Thiết bị phát hiện người đeo đang NGÃ ⚠️'
                    : '✅ Trạng thái bình thường',
                style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới trạng thái'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
