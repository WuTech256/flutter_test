import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/medication.dart';

class MedicationService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _userMedRef(String uid) =>
      _db.ref('users/$uid/medications');

  /// Thêm thuốc
  Future<void> addMedication(Medication med, String uid, int notifId) async {
    final ref = _userMedRef(uid).push(); // Tạo ID Firebase

    await ref.set({
      'id': ref.key,                       // 🔥 LƯU ID VÀO DATABASE
      'name': med.name,
      'dosage': med.dosage,
      'quantity': med.quantity,
      'hour': med.time.hour,
      'minute': med.time.minute,
      'notificationId': notifId,
    });
  }

  /// Stream danh sách thuốc
  Stream<List<Medication>> streamMedications(String uid) {
    return _userMedRef(uid).onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists) return [];

      final List<Medication> list = [];

      for (final child in snap.children) {
        final data = child.value;
        if (data is Map) {
          list.add(Medication.fromMap(child.key!, data));
        }
      }

      // Sắp xếp theo giờ
      list.sort((a, b) {
        final ta = a.time.hour * 60 + a.time.minute;
        final tb = b.time.hour * 60 + b.time.minute;
        return ta.compareTo(tb);
      });

      return list;
    });
  }

  /// Xóa thuốc
  Future<void> deleteMedication(String uid, Medication med) async {
    await _userMedRef(uid).child(med.id).remove();
  }
}
