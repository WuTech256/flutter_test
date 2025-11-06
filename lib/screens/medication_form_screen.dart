// lib/screens/medication_form_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bạn chưa đăng nhập')));
      }
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
      final notifId = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      await _service.addMedication(med, user.uid, notifId);
      await NotificationService.scheduleDailyMedication(
        id: notifId,
        title: 'Nhắc uống thuốc: ${med.name}',
        body: 'Liều: ${med.dosage} • ${med.quantity} viên',
        hour: med.time.hour,
        minute: med.time.minute,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
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
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên thuốc'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập tên' : null,
              ),
              TextFormField(
                controller: _dosage,
                decoration: const InputDecoration(labelText: 'Liều dùng'),
              ),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số lượng'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _time == null
                        ? 'Chưa chọn giờ'
                        : 'Giờ: ${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final now = TimeOfDay.now();
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: now,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                    child: const Text('Chọn giờ'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
