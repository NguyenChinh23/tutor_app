import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/data/models/notification_model.dart';
import 'package:tutor_app/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository;

  NotificationProvider({required this.repository});

  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  String? lastError;

  StreamSubscription? _sub;

  // Lắng nghe notif của user
  void listenForUser(String userId) {
    _sub?.cancel();

    _sub = repository.listenUserNotifications(userId).listen(
          (list) {
        notifications = list;
        unreadCount = list.where((n) => !n.read).length;
        lastError = null;
        notifyListeners();
      },
      onError: (e, st) {
        lastError = e.toString();
        notifyListeners();
      },
    );
  }

  // tHÔNG BÁO KHI GIA SƯ CHẤP NHẬN
  // Buổi lẻ: isPackage = false (default)
  // Gói: isPackage = true, truyền thêm packageId + totalSessions
  Future<void> createBookingAcceptedNotification({
    required String studentId,
    required String tutorName,
    required String subject,
    required DateTime startAt,
    String? bookingId,
    String? packageId,
    bool isPackage = false,
    int? totalSessions,
  }) async {
    final df = DateFormat('dd/MM HH:mm');
    final timeText = df.format(startAt);

    final title = isPackage
        ? 'Gói học được gia sư chấp nhận'
        : 'Gia sư đã chấp nhận lịch học';

    final body = isPackage
        ? '$tutorName đã chấp nhận gói học $subject (~${totalSessions ?? 0} buổi), bắt đầu từ $timeText.'
        : '$tutorName đã chấp nhận buổi học $subject lúc $timeText.';

    final notif = NotificationModel(
      id: '',
      userId: studentId,
      type: 'booking_accepted',
      title: title,
      body: body,
      read: false,
      createdAt: DateTime.now(),
      bookingId: bookingId,
      packageId: packageId,
    );

    await repository.createNotification(notif);
  }

  //  THÔNG BÁO KHI BUỔI HỌC BỊ HUỶ
  Future<void> createLessonCancelledNotification({
    required BookingModel booking,
    String? reason,
  }) async {
    final df = DateFormat('dd/MM HH:mm');
    final timeText = df.format(booking.startAt);

    final base =
        'Buổi học ${booking.subject.isEmpty ? '' : booking.subject + ' '}lúc $timeText đã bị gia sư huỷ.';
    final body = (reason != null && reason.isNotEmpty)
        ? '$base Lý do: $reason'
        : base;

    final notif = NotificationModel(
      id: '',
      userId: booking.studentId,
      type: 'lesson_cancelled',
      title: 'Buổi học bị huỷ',
      body: body,
      read: false,
      createdAt: DateTime.now(),
      bookingId: booking.id,
      packageId: booking.packageId,
    );

    await repository.createNotification(notif);
  }

  //  THÔNG BÁO KHI BUỔI HỌC HOÀN THÀNH
  Future<void> createLessonCompletedNotification({
    required BookingModel booking,
  }) async {
    final df = DateFormat('dd/MM HH:mm');
    final timeText = df.format(booking.startAt);

    final body =
        'Buổi học ${booking.subject.isEmpty ? '' : booking.subject + ' '}lúc $timeText đã hoàn thành. Hãy vào ứng dụng để đánh giá gia sư nhé!';

    final notif = NotificationModel(
      id: '',
      userId: booking.studentId,
      type: 'lesson_completed',
      title: 'Buổi học đã hoàn thành',
      body: body,
      read: false,
      createdAt: DateTime.now(),
      bookingId: booking.id,
      packageId: booking.packageId,
    );

    await repository.createNotification(notif);
  }

  //  Đánh dấu đã đọc
  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id);
    } catch (e) {
      debugPrint('[NotificationProvider] markAsRead error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
