import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sleep_session.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> sessionsCol(String uid) =>
      _db.collection('users').doc(uid).collection('sleepSessions');

  Stream<List<SleepSession>> streamSessions(String uid) {
    return sessionsCol(uid)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = d.data();
      return SleepSession(
        id: d.id,
        start: (data['startAt'] as Timestamp).toDate(),
        end: (data['endAt'] as Timestamp).toDate(),
        comfortRating: data['comfortRating'] ?? 3,
        noiseLevel: data['noiseLevel'] ?? 3,
        lat: (data['lat'] as num?)?.toDouble(),
        lng: (data['lng'] as num?)?.toDouble(),
        notes: data['notes'] ?? '',
        preset: data['preset'],
      );
    }).toList());
  }

  Future<void> addSession(String uid, SleepSession s) {
    return sessionsCol(uid).add({
      'startAt': Timestamp.fromDate(s.start),
      'endAt': Timestamp.fromDate(s.end),
      'comfortRating': s.comfortRating,
      'noiseLevel': s.noiseLevel,
      'lat': s.lat,
      'lng': s.lng,
      'notes': s.notes,
      'preset': s.preset,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSession(String uid, String id) {
    return sessionsCol(uid).doc(id).delete();
  }
}
// FirestoreService

