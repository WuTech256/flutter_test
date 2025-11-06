// lib/models/medication.dart
import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final int quantity;
  final TimeOfDay time;
  final int? notificationId; // ✅ Thêm field

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.time,
    this.notificationId,
  });
}
