import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/tutor_dashboard_model.dart';
import 'package:tutor_app/data/repositories/tutor_dashboard_repository.dart';

class TutorDashboardProvider extends ChangeNotifier {
  final TutorDashboardRepository _repo;
  final String tutorId;

  TutorDashboardProvider({
    required TutorDashboardRepository repository,
    required this.tutorId,
  }) : _repo = repository;

  bool _isLoading = false;
  String? _error;

  TutorStats _stats = TutorStats.empty;
  TutorOnlineStatus _status = TutorOnlineStatus.online;
  bool _availableForBooking = true;

  List<TutorRequest> _pendingRequests = [];
  List<TutorLesson> _todayLessons = [];
  List<ChatPreview> _recentChats = [];
  List<TutorNotificationItem> _notifications = [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  TutorStats get stats => _stats;
  TutorOnlineStatus get status => _status;
  bool get availableForBooking => _availableForBooking;

  List<TutorRequest> get pendingRequests => _pendingRequests;
  List<TutorLesson> get todayLessons => _todayLessons;
  List<ChatPreview> get recentChats => _recentChats;
  List<TutorNotificationItem> get notifications => _notifications;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getStats(tutorId),
        _repo.getPendingRequests(tutorId),
        _repo.getTodayLessons(tutorId),
        _repo.getRecentChats(tutorId),
        _repo.getNotifications(tutorId),
      ]);

      _stats = results[0] as TutorStats;
      _pendingRequests = results[1] as List<TutorRequest>;
      _todayLessons = results[2] as List<TutorLesson>;
      _recentChats = results[3] as List<ChatPreview>;
      _notifications = results[4] as List<TutorNotificationItem>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<void> toggleAvailability(bool value) async {
    _availableForBooking = value;
    notifyListeners();
    try {
      await _repo.setAvailability(tutorId, value);
    } catch (_) {
      _availableForBooking = !value;
      notifyListeners();
    }
  }

  void changeStatus(TutorOnlineStatus s) {
    _status = s;
    notifyListeners();
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _repo.acceptRequest(tutorId, requestId);
      _pendingRequests =
          _pendingRequests.where((r) => r.id != requestId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _repo.rejectRequest(tutorId, requestId);
      _pendingRequests =
          _pendingRequests.where((r) => r.id != requestId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
