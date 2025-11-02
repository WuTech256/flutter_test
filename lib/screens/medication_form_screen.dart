// lib/screens/medication_form_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';
import '../services/medication_service.dart';
// nếu bạn đã có NotificationService, import nó; nếu không, comment dòng kia
import '../services/notification_service.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  TimeOfDay? _time;
  final _service = MedicationService();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _time == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chưa đăng nhập')));
      return;
    }

    setState(() => _saving = true);

    final med = Medication(
      id: '',
      name: _name.text.trim(),
      dosage: _dosage.text.trim(),
      quantity: int.tryParse(_quantity.text) ?? 1,
      time: _time!,
    );

    try {
      await _service.addMedication(med, user.uid);

      // optional: schedule local notification if you have NotificationService
      try {
        final now = DateTime.now();
        final notifTime = DateTime(now.year, now.month, now.day, _time!.hour, _time!.minute);
        final tzDate = tz.TZDateTime.from(notifTime, tz.local);
        await NotificationService.scheduleNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: 'Đến giờ uống thuốc',
          body: '${med.name} • ${med.dosage}',
          scheduledDate: tzDate,
        );
      } catch (_) { /* nếu không có NotificationService thì bỏ qua */ }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thuốc')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Tên thuốc'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên thuốc' : null,
                ),
                TextFormField(
                  controller: _dosage,
                  decoration: const InputDecoration(labelText: 'Liều lượng (ví dụ 500mg)'),
                ),
                TextFormField(
                  controller: _quantity,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_time == null ? 'Chọn giờ uống' : 'Uống lúc ${_time!.format(context)}'),
                ),
              ]),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
