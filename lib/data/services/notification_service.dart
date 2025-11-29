import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/notification_model.dart';

class NotificationService {
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notif =>
      _fs.collection('notifications');

  Future<void> createNotification(NotificationModel n) async {
    await _notif.add(n.toMap());
  }

  Stream<List<NotificationModel>> listenUserNotifications(String userId) {
    return _notif
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((d) => NotificationModel.fromDoc(d)).toList(),
    );
  }

  Future<void> markAsRead(String id) async {
    await _notif.doc(id).update({'read': true});
  }
}
