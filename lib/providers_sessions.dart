import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/sleep_session.dart';

final authStateProvider = StreamProvider<User?>(
      (ref) => FirebaseAuth.instance.authStateChanges(),
);

final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

/// Stream the user’s sessions newest->oldest
final sessionsStreamProviderFamily =
StreamProvider.family<List<SleepSession>, String>((ref, uid) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('users')
      .doc(uid)
      .collection('sleepSessions')
      .orderBy('startAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
    final m = d.data();
    return SleepSession(
      id: d.id,
      start: (m['startAt'] as Timestamp).toDate(),
      end: (m['endAt'] as Timestamp).toDate(),
      comfortRating: (m['comfortRating'] ?? 3) as int,
      noiseLevel: (m['noiseLevel'] ?? 3) as int,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      notes: (m['notes'] ?? '') as String,
      preset: m['preset'],
    );
  }).toList());
});

/// Simple write helpers
class FirestoreRepo {
  FirestoreRepo(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection('users').doc(uid).collection('sleepSessions');

  Future<void> add(String uid, SleepSession s) => _col(uid).add({
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

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();

  Future<void> savePreset(String uid, Map<String, dynamic> preset) =>
      db.collection('users').doc(uid).collection('presets').doc('default').set(preset);

  Stream<Map<String, dynamic>?> presetStream(String uid) =>
      db.collection('users').doc(uid).collection('presets').doc('default').snapshots().map((d) => d.data());
}
final firestoreRepoProvider = Provider((ref) => FirestoreRepo(ref.watch(firestoreProvider)));
