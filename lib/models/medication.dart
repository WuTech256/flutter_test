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

  Map<String, dynamic> toMap() => {
    'name': name,
    'dosage': dosage,
    'quantity': quantity,
    'hour': time.hour,
    'minute': time.minute,
    'notificationId': notificationId,
  };

  factory Medication.fromMap(String id, Map<dynamic, dynamic> map) {
    final hour = (map['hour'] ?? 8) as int;
    final minute = (map['minute'] ?? 0) as int;
    return Medication(
      id: id,
      name: (map['name'] ?? '') as String,
      dosage: (map['dosage'] ?? '') as String,
      quantity: (map['quantity'] ?? 1) as int,
      time: TimeOfDay(hour: hour, minute: minute),
      notificationId: map['notificationId'] == null
          ? null
          : (map['notificationId'] as int),
    );
  }
}
