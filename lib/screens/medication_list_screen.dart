import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import 'medication_form_screen.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final MedicationService _service = MedicationService();
  final Set<String> _deleting = {}; // lưu id những item đang xóa

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Bạn chưa đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc uống thuốc')),
      body: StreamBuilder<List<Medication>>(
        stream: _service.streamMedications(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final meds = snap.data ?? [];
          if (meds.isEmpty) {
            return const Center(child: Text('Chưa có thuốc. Nhấn + để thêm.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: meds.length,
            itemBuilder: (context, i) {
              final m = meds[i];
              final isDeleting = _deleting.contains(m.id);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${m.dosage} • ${m.quantity} viên\nLúc: ${m.time.format(context)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: isDeleting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete, color: Colors.red),
                    onPressed: isDeleting
                        ? null
                        : () async {
                            // Lấy scaffold messenger trước khi await (không dùng context sau await trực tiếp)
                            final scaffold = ScaffoldMessenger.of(context);

                            // Bạn có thể hiện dialog confirm trước khi xóa nếu muốn:
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xác nhận'),
                                content: const Text('Bạn có chắc muốn xóa thuốc này?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa')),
                                ],
                              ),
                            );
                            if (confirm != true) return;

                            try {
                              setState(() => _deleting.add(m.id));
                              await _service.deleteMedication(user.uid, m.id);

                              // Sau await: kiểm tra mounted trước khi thao tác với context/UI
                              if (!mounted) return;
                              scaffold.showSnackBar(const SnackBar(content: Text('Đã xóa')));
                            } catch (e) {
                              if (!mounted) return;
                              scaffold.showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
                            } finally {
                              if (mounted) setState(() => _deleting.remove(m.id));
                            }
                          },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MedicationFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
