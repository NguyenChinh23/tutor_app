import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/tutor_request_model.dart';

class TutorRequestService {
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _fs.collection('tutorRequests');

  /// Stream tất cả request của 1 tutor
  Stream<List<TutorRequestModel>> streamRequestsForTutor(String tutorId) {
    return _requests
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((d) => TutorRequestModel.fromDoc(d))
          .toList(),
    );
  }

  Future<void> updateStatus({
    required String requestId,
    required String status, // accepted / rejected
  }) {
    return _requests.doc(requestId).update({'status': status});
  }
}
