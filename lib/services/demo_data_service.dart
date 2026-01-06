import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoDataService {
  final FirebaseFirestore db;
  DemoDataService(this.db);

  Future<void> seed(String uid) async {
    final col = db.collection('users').doc(uid).collection('sleepSessions');
    final now = DateTime.now();
    final rnd = Random(42);
    for (int i=0; i<7; i++) {
      final start = DateTime(now.year, now.month, now.day - i, 23, 0);
      final durH = 5.5 + rnd.nextDouble()*3.0;
      final end = start.add(Duration(minutes: (durH * 60).round()));
      final lat = 43.25 + rnd.nextDouble()*0.02;
      final lng = -79.85 + rnd.nextDouble()*0.02;
      await col.add({
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'comfortRating': 3 + rnd.nextInt(3),
        'noiseLevel': 2 + rnd.nextInt(3),
        'lat': lat, 'lng': lng, 'notes': 'demo', 'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
