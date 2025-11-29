import 'package:tutor_app/data/models/tutor_dashboard_model.dart';
import 'package:tutor_app/data/services/tutor_dashboard_service.dart';

class TutorDashboardRepository {
  final TutorDashboardService _service;

  TutorDashboardRepository(this._service);

  Future<TutorStats> getStats(String tutorId) =>
      _service.fetchStats(tutorId);

  Future<List<TutorRequest>> getPendingRequests(String tutorId) =>
      _service.fetchPendingRequests(tutorId);

  Future<List<TutorLesson>> getTodayLessons(String tutorId) =>
      _service.fetchTodayLessons(tutorId);

  Future<List<ChatPreview>> getRecentChats(String tutorId) =>
      _service.fetchRecentChats(tutorId);

  Future<List<TutorNotificationItem>> getNotifications(String tutorId) =>
      _service.fetchNotifications(tutorId);

  Future<void> setAvailability(String tutorId, bool isAvailable) =>
      _service.updateAvailability(tutorId, isAvailable);

  Future<void> acceptRequest(String tutorId, String requestId) =>
      _service.acceptRequest(tutorId, requestId);

  Future<void> rejectRequest(String tutorId, String requestId) =>
      _service.rejectRequest(tutorId, requestId);
}
