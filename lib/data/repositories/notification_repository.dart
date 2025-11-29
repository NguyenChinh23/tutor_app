import 'package:tutor_app/data/models/notification_model.dart';
import 'package:tutor_app/data/services/notification_service.dart';

class NotificationRepository {
  final NotificationService service;

  NotificationRepository(this.service);

  Future<void> createNotification(NotificationModel n) =>
      service.createNotification(n);

  Stream<List<NotificationModel>> listenUserNotifications(String uid) =>
      service.listenUserNotifications(uid);

  Future<void> markAsRead(String id) => service.markAsRead(id);
}
