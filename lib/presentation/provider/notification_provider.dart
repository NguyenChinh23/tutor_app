import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tutor_app/data/models/notification_model.dart';
import 'package:tutor_app/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository;

  NotificationProvider({required this.repository});

  List<NotificationModel> notifications = [];
  int unreadCount = 0;

  String? lastError;

  StreamSubscription? _sub;

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

  Future<void> createBookingAcceptedNotification({
    required String studentId,
    required String tutorName,
    required String bookingId,
    required String subject,
    required DateTime startAt,
  }) async {
    final df = DateFormat('dd/MM HH:mm');

    final notif = NotificationModel(
      id: '',
      userId: studentId,
      type: 'booking_accepted',
      title: 'Gia sư đã chấp nhận lịch học',
      body:
      '$tutorName đã chấp nhận buổi học $subject lúc ${df.format(startAt)}.',
      read: false,
      createdAt: DateTime.now(),
      bookingId: bookingId,
      packageId: null,
    );

    await repository.createNotification(notif);
  }

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
