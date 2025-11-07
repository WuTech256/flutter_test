// lib/models/medication.dart
import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final int quantity;
  final TimeOfDay time;
  final int? notificationId;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.time,
    this.notificationId,
  });

  factory Medication.fromMap(String id, Map<dynamic, dynamic> data) {
    final hour = (data['hour'] ?? 0) as int;
    final minute = (data['minute'] ?? 0) as int;
    return Medication(
      id: id,
      name: (data['name'] ?? '') as String,
      dosage: (data['dosage'] ?? '') as String,
      quantity: (data['quantity'] ?? 0) as int,
      time: TimeOfDay(hour: hour, minute: minute),
      notificationId: data['notificationId'] is int
          ? data['notificationId'] as int
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'hour': time.hour,
      'minute': time.minute,
      if (notificationId != null) 'notificationId': notificationId,
    };
  }
}
