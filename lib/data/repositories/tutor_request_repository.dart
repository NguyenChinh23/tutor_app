import 'package:tutor_app/data/models/tutor_request_model.dart';
import 'package:tutor_app/data/services/tutor_request_service.dart';

class TutorRequestRepository {
  final TutorRequestService _service;

  TutorRequestRepository(this._service);

  Stream<List<TutorRequestModel>> streamRequests(String tutorId) {
    return _service.streamRequestsForTutor(tutorId);
  }

  Future<void> acceptRequest(TutorRequestModel request) {
    return _service.updateStatus(
      requestId: request.id,
      status: 'accepted',
    );
  }

  Future<void> rejectRequest(TutorRequestModel request) {
    return _service.updateStatus(
      requestId: request.id,
      status: 'rejected',
    );
  }
}
