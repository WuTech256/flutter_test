// lib/services/medication_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationService {
  final _db = FirebaseFirestore.instance;

  DatabaseReference _userRef(String uid) =>
      FirebaseDatabase.instance.ref('medications/$uid');

  /// Thêm thuốc cho userId (UID)
  Future<void> addMedication(Medication med, String uid, int notifId) async {
    final ref = _userRef(uid).push();
    await ref.set(med.copyWith(notificationId: notifId).toMap());
  }

  /// Lấy stream danh sách thuốc theo userId
  Stream<List<Medication>> streamMedications(String userId) {
    return _userRef(userId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        return data.entries
            .map(
              (e) => Medication.fromMap(
                e.key,
                Map<dynamic, dynamic>.from(e.value),
              ),
            )
            .toList();
      }
      return <Medication>[];
    });
  }

  Future<List<Medication>> fetchAll(String uid) async {
    final snap = await _userRef(uid).get();
    final data = snap.value;
    if (data is Map) {
      return data.entries
          .map(
            (e) =>
                Medication.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)),
          )
          .toList();
    }
    return [];
  }

  Future<void> deleteMedication(String uid, Medication med) async {
    await _userRef(uid).child(med.id).remove();
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
