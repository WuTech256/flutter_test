// lib/services/medication_service.dart
import 'package:flutter/material.dart'; // thêm để dùng TimeOfDay
import 'package:firebase_database/firebase_database.dart';
import '../models/medication.dart';

class MedicationService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _userMedRef(String uid) =>
      _db.ref('users/$uid/medications');

  /// Thêm thuốc cho userId (UID)
  Future<void> addMedication(Medication med, String uid, int notifId) async {
    final ref = _userMedRef(uid).push();
    await ref.set({
      'name': med.name,
      'dosage': med.dosage,
      'quantity': med.quantity,
      'hour': med.time.hour,
      'minute': med.time.minute,
      'notificationId': notifId, // có thể bỏ nếu không dùng
    });
  }

  /// Lấy stream danh sách thuốc theo userId
  Stream<List<Medication>> streamMedications(String uid) {
    return _userMedRef(uid).onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists) return <Medication>[];
      final List<Medication> list = [];
      for (final child in snap.children) {
        final data = child.value;
        if (data is Map) {
          list.add(Medication.fromMap(child.key!, data));
        }
      }
      // Sort theo giờ
      list.sort((a, b) {
        final ta = a.time.hour * 60 + a.time.minute;
        final tb = b.time.hour * 60 + b.time.minute;
        return ta.compareTo(tb);
      });
      return list;
    });
  }

  Future<void> deleteMedication(String uid, Medication med) async {
    await _userMedRef(uid).child(med.id).remove();
  }
}

extension on Medication {
  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    int? quantity,
    TimeOfDay? time,
    int? notificationId,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}
