import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String? bookingId;
  final String? packageId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.bookingId,
    this.packageId,
  });

  factory NotificationModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      read: data['read'] == true,
      createdAt: _toDate(data['createdAt']),
      bookingId: data['bookingId']?.toString(),
      packageId: data['packageId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'bookingId': bookingId,
      'packageId': packageId,
    };
  }
}
