import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

ElevatedButton(
  onPressed: () async {
    final now = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    await NotificationService.scheduleNotification(
      id: 123,
      title: "Test",
      body: "Thông báo sau 5 giây",
      scheduledDate: now,
    );
  },
  child: const Text("Test thông báo"),
),
