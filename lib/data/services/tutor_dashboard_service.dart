import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/tutor_dashboard_model.dart';

class TutorDashboardService {
  final FirebaseFirestore _db;

  TutorDashboardService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Thống kê nhanh: lấy trực tiếp từ users/{tutorId}
  Future<TutorStats> fetchStats(String tutorId) async {
    final doc = await _db.collection('users').doc(tutorId).get();
    final data = doc.data() ?? {};

    final pending = (data['pendingRequests'] as num?)?.toInt() ?? 0;
    final upcoming = (data['upcomingLessons'] as num?)?.toInt() ?? 0;
    final earnings = (data['monthlyEarnings'] as num?)?.toDouble() ?? 0;
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;

    return TutorStats(
      pendingRequests: pending,
      upcomingLessons: upcoming,
      monthlyEarnings: earnings,
      avgRating: rating,
    );
  }

  /// Chưa có booking thật → tạm trả rỗng
  Future<List<TutorRequest>> fetchPendingRequests(String tutorId) async {
    return [];
  }

  Future<List<TutorLesson>> fetchTodayLessons(String tutorId) async {
    return [];
  }

  Future<List<ChatPreview>> fetchRecentChats(String tutorId) async {
    return [];
  }

  Future<List<TutorNotificationItem>> fetchNotifications(String tutorId) async {
    // Có thể mock 1-2 thông báo cơ bản
    return const [
      TutorNotificationItem(
        id: 'noti1',
        title: 'Hoàn thiện hồ sơ',
        description:
        'Hãy cập nhật đầy đủ avatar, bio và môn dạy để tăng độ tin cậy.',
        icon: Icons.person_outline,
        isImportant: true,
      ),
    ];
  }

  /// Toggle nhận yêu cầu: lưu lên users/{uid}
  Future<void> updateAvailability(String tutorId, bool isAvailable) async {
    await _db.collection('users').doc(tutorId).set(
      {'availableForBooking': isAvailable},
      SetOptions(merge: true),
    );
  }

  Future<void> acceptRequest(String tutorId, String requestId) async {
    // TODO: implement sau khi có collection bookings
  }

  Future<void> rejectRequest(String tutorId, String requestId) async {
    // TODO: implement sau khi có collection bookings
  }
}
