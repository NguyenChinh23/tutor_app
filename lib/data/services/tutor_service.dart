import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutor_model.dart';

class TutorService {
  final _fs = FirebaseFirestore.instance;

  // Chỉ lấy tutor đã được duyệt từ collection 'users'
  Stream<List<TutorModel>> getApprovedTutor() {
    return _fs
        .collection('users')
        .where('role', isEqualTo: 'tutor')
        .where('isTutorVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TutorModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<TutorModel?> getTutorById(String uid) async {
    final doc = await _fs.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return TutorModel.fromMap(doc.id, doc.data()!);
  }

  //  Admin duyệt tutor → cập nhật users và tutorApplications
  Future<void> approveTutor(String appId, String uid) async {
    final batch = _fs.batch();

    // Cập nhật user → đã duyệt
    final userRef = _fs.collection('users').doc(uid);
    batch.update(userRef, {'isTutorVerified': true});

    // Cập nhật trạng thái trong đơn ứng tuyển
    final appRef = _fs.collection('tutorApplications').doc(appId);
    batch.update(appRef, {'status': 'approved'});

    await batch.commit();
  }
}
