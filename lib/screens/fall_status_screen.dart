import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FallStatusScreen extends StatefulWidget {
  final String username;
  const FallStatusScreen({super.key, required this.username});

  @override
  State<FallStatusScreen> createState() => _FallStatusScreenState();
}

class _FallStatusScreenState extends State<FallStatusScreen> {
  late DatabaseReference _ref;
  String _status = 'Đang tải...';

  @override
  void initState() {
    super.initState();
    _ref = FirebaseDatabase.instance.ref('locations/${widget.username}/Status');
    _ref.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (!mounted) return;
      if (raw == null) {
        setState(() => _status = 'Không có dữ liệu');
        return;
      }
      final s = raw.toString().trim().toLowerCase();
      setState(() => _status = s == 'fall' ? '⚠️ NGÃ' : 'Bình thường');
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
          ],
        ),
      ),
    );
  }
}
