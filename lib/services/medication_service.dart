// lib/services/medication_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationService {
  final _db = FirebaseFirestore.instance;

  /// Thêm thuốc cho userId (UID)
  Future<void> addMedication(
    Medication med,
    String userId,
    int notificationId,
  ) async {
    final col = _db.collection('users').doc(userId).collection('medications');
    final docRef = col.doc();
    await docRef.set({
      'id': docRef.id,
      'name': med.name,
      'dosage': med.dosage,
      'quantity': med.quantity,
      'hour': med.time.hour,
      'minute': med.time.minute,
      'notificationId': notificationId, // ✅ Lưu notificationId để hủy sau
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy stream danh sách thuốc theo userId
  Stream<List<Medication>> streamMedications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            final hour = (d['hour'] is int)
                ? d['hour'] as int
                : (d['hour'] is num ? (d['hour'] as num).toInt() : 0);
            final minute = (d['minute'] is int)
                ? d['minute'] as int
                : (d['minute'] is num ? (d['minute'] as num).toInt() : 0);
            return Medication(
              id: d['id'] ?? doc.id,
              name: d['name'] ?? '',
              dosage: d['dosage'] ?? '',
              quantity: (d['quantity'] is int)
                  ? d['quantity'] as int
                  : (d['quantity'] is num ? (d['quantity'] as num).toInt() : 0),
              time: TimeOfDay(hour: hour, minute: minute),
              notificationId: d['notificationId'] as int?, // ✅ Thêm field
            );
          }).toList(),
        );
  }

  Future<void> deleteMedication(String userId, String medId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .delete();
  }
}
