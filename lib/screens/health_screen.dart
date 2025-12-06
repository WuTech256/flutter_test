import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_status.dart';
import '../services/health_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _service = HealthService();
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;

  // form controller (chỉ thay đổi trên UI, không đụng vào dữ liệu gốc)
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  double _bmiPreview = 0;

  double calcBMI(double w, double h) {
    double m = h / 100;
    return w / (m * m);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tình trạng sức khỏe", style: TextStyle(fontSize: 15)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
        ],
      ),
      body: StreamBuilder<HealthStatus?>(
        stream: _service.streamLatest(user!.uid),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: Text("Chưa có dữ liệu"));
          }

          final health = snap.data!;

          if (!_isEditing) return _buildView(health);

          // LOAD FORM 1 LẦN DUY NHẤT
          if (_weightCtrl.text.isEmpty) {
            _weightCtrl.text = health.weight.toString();
            _heightCtrl.text = health.height.toString();
            _noteCtrl.text = health.note;
            _bmiPreview = health.bmi;
          }

          return _buildForm(user.uid);
        },
      ),
    );
  }

  // ==================== VIEW MODE =====================
  Widget _buildView(HealthStatus h) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text("Cân nặng: ${h.weight} kg", style: viewStyle),
          Text("Chiều cao: ${h.height} cm", style: viewStyle),
          Text("BMI: ${h.bmi.toStringAsFixed(1)}", style: viewStyle),
          const SizedBox(height: 10),
          const Text("Ghi chú:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(h.note, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  final viewStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

  // ==================== EDIT MODE =====================
  Widget _buildForm(String uid) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _weightCtrl,
              decoration: const InputDecoration(labelText: "Cân nặng (kg)"),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? "Nhập cân nặng" : null,
              onChanged: (v) {
                final w = double.tryParse(_weightCtrl.text);
                final h = double.tryParse(_heightCtrl.text);
                if (w != null && h != null) {
                  setState(() => _bmiPreview = calcBMI(w, h));
                }
              },
            ),
            TextFormField(
              controller: _heightCtrl,
              decoration: const InputDecoration(labelText: "Chiều cao (cm)"),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? "Nhập chiều cao" : null,
              onChanged: (v) {
                final w = double.tryParse(_weightCtrl.text);
                final h = double.tryParse(_heightCtrl.text);
                if (w != null && h != null) {
                  setState(() => _bmiPreview = calcBMI(w, h));
                }
              },
            ),
            const SizedBox(height: 20),

            Text(
              "BMI: ${_bmiPreview.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _noteCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Lời khuyên bác sĩ"),
            ),

            const SizedBox(height: 30),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final w = double.parse(_weightCtrl.text);
                final h = double.parse(_heightCtrl.text);

                final newData = HealthStatus(
                  weight: w,
                  height: h,
                  bmi: calcBMI(w, h),
                  note: _noteCtrl.text,
                );

                await _service.saveHealth(uid, newData);

                if (mounted) {
                  setState(() {
                    _isEditing = false;

                    // Reset để lần sau không load lại dữ liệu cũ
                    _weightCtrl.clear();
                    _heightCtrl.clear();
                    _noteCtrl.clear();
                    _bmiPreview = 0;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã lưu thành công")),
                  );
                }
              },
              child: const Text("Lưu"),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _weightCtrl.clear();
                  _heightCtrl.clear();
                  _noteCtrl.clear();
                  _bmiPreview = 0;
                });
              },
              child: const Text("Hủy"),
            )
          ],
        ),
      ),
    );
  }
}
