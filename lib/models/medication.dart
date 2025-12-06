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
    return Medication(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      quantity: data['quantity'] ?? 1,
      time: TimeOfDay(
        hour: data['hour'] ?? 0,
        minute: data['minute'] ?? 0,
      ),
      notificationId: data['notificationId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'hour': time.hour,
      'minute': time.minute,
      'notificationId': notificationId,
    };
  }
}
