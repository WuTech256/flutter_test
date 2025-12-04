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

  double? _weight;
  double? _height;
  double _bmi = 0;
  String _note = "";

  double calcBMI(double w, double h) {
    double m = h / 100;
    return w / (m * m);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tình trạng sức khỏe", style: TextStyle(fontSize: 15)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: StreamBuilder<HealthStatus?>(
        stream: _service.streamLatest(user.uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final h = snap.data;

          if (!_isEditing) {
            // VIEW MODE
            if (h == null) {
              return const Center(child: Text("Chưa có dữ liệu sức khỏe"));
            }
            return _buildView(h);
          }

          // EDIT MODE → load dữ liệu vào form 1 lần
          if (h != null && _weight == null && _height == null && _note.isEmpty) {
            _weight = h.weight;
            _height = h.height;
            _bmi = h.bmi;
            _note = h.note;
          }

          return _buildForm(user.uid);
        },
      ),
    );
  }

  // ---------------------- VIEW MODE -------------------
  Widget _buildView(HealthStatus h) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text("Cân nặng: ${h.weight} kg", style: viewStyle),
          Text("Chiều cao: ${h.height} cm", style: viewStyle),
          Text("BMI: ${h.bmi.toStringAsFixed(1)}", style: viewStyle),
          const SizedBox(height: 10),
          const Text("Ghi chú:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(h.note, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  final viewStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

  // ---------------------- EDIT MODE -------------------
  Widget _buildForm(String uid) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: _weight?.toString() ?? "",
              decoration: const InputDecoration(labelText: "Cân nặng (kg)"),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? "Nhập cân nặng" : null,
              onChanged: (v) {
                _weight = double.tryParse(v);
                if (_weight != null && _height != null) {
                  setState(() => _bmi = calcBMI(_weight!, _height!));
                }
              },
            ),
            TextFormField(
              initialValue: _height?.toString() ?? "",
              decoration: const InputDecoration(labelText: "Chiều cao (cm)"),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? "Nhập chiều cao" : null,
              onChanged: (v) {
                _height = double.tryParse(v);
                if (_weight != null && _height != null) {
                  setState(() => _bmi = calcBMI(_weight!, _height!));
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              "BMI: ${_bmi.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _note,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Lời khuyên bác sĩ"),
              onChanged: (v) => _note = v,
            ),
            const SizedBox(height: 30),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final h = HealthStatus(
                  weight: _weight!,
                  height: _height!,
                  bmi: _bmi,
                  note: _note,
                );

                await _service.saveHealth(uid, h);

                if (mounted) {
                  setState(() {
                    _isEditing = false;
                    _weight = null;
                    _height = null;
                    _bmi = 0;
                    _note = "";
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã lưu")),
                  );
                }
              },
              child: const Text("Lưu"),
            ),

            // CANCEL BUTTON
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _weight = null;
                  _height = null;
                  _bmi = 0;
                  _note = "";
                });
              },
              child: const Text("Hủy"),
            ),
          ],
        ),
      ),
    );
  }
}
