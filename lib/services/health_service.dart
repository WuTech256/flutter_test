import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_status.dart';

class HealthService {
  final _db = FirebaseFirestore.instance;

  Stream<HealthStatus?> streamLatest(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('health')
        .doc('latest')
        .snapshots()
        .map((doc) => doc.exists ? HealthStatus.fromMap(doc.data()!) : null);
  }

  Future<void> saveHealth(String uid, HealthStatus h) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('health')
        .doc('latest')
        .set(h.toMap());
  }
}
