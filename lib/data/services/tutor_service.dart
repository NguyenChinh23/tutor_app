import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutor_model.dart';

class TutorService {
  final _fs = FirebaseFirestore.instance;

  /// 🔥 Lấy tất cả tutor đã được duyệt từ collection `users`
  Stream<List<TutorModel>> getApprovedTutor() {
    return _fs
        .collection('users')
        .where('role', isEqualTo: 'tutor')
        .where('isTutorVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      print('🔥 Firestore fetched ${snapshot.docs.length} tutors');
      for (var doc in snapshot.docs) {
        print('Tutor Data: ${doc.data()}');
      }

      return snapshot.docs
          .map((doc) => TutorModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// 🔹 Lấy thông tin tutor theo UID
  Future<TutorModel?> getTutorById(String uid) async {
    final doc = await _fs.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return TutorModel.fromMap(doc.id, doc.data()!);
  }

  /// 🔹 Admin duyệt tutor (cập nhật 2 collection)
  Future<void> approveTutor(String appId, String uid) async {
    final batch = _fs.batch();
    final userRef = _fs.collection('users').doc(uid);
    final appRef = _fs.collection('tutorApplications').doc(appId);

    batch.update(userRef, {'isTutorVerified': true});
    batch.update(appRef, {'status': 'approved'});

    await batch.commit();
  }
}
