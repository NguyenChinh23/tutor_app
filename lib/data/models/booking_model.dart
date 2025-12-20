import 'package:cloud_firestore/cloud_firestore.dart';

class BookingStatus {
  static const String accepted = 'accepted';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}

class BookingModel {
  final String id;
  final String tutorId;
  final String studentId;

  final String tutorName;
  final String studentName;
  final String subject;

  final double pricePerHour;
  final double hours;
  final double price;

  final String note;

  final DateTime startAt;
  final DateTime endAt;

  /// accepted | cancelled | completed
  final String status;

  final bool paid;
  final String? paymentMethod;
  final String? cancelReason;

  final DateTime createdAt;
  final DateTime? updatedAt;

  /// online | offline_at_student | offline_at_tutor
  final String mode;

  // ===== ĐÁNH GIÁ =====
  final double? rating;
  final String? review;
  final DateTime? ratedAt;

  // ===== GÓI HỌC =====
  /// single | 1m | 3m | 6m
  final String packageType;

  /// null nếu book lẻ
  final String? packageId;

  /// book lẻ = 1
  final int totalSessions;

  /// số buổi đã hoàn thành
  final int completedSessions;

  bool get isPackage => packageType != 'single';

  BookingModel({
    required this.id,
    required this.tutorId,
    required this.studentId,
    required this.tutorName,
    required this.studentName,
    required this.subject,
    required this.pricePerHour,
    required this.hours,
    required this.price,
    required this.note,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.paid,
    required this.paymentMethod,
    required this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    required this.mode,
    required this.rating,
    required this.review,
    required this.ratedAt,
    required this.packageType,
    required this.packageId,
    required this.totalSessions,
    required this.completedSessions,
  });

  factory BookingModel.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return BookingModel(
      id: doc.id,
      tutorId: data['tutorId'] ?? '',
      studentId: data['studentId'] ?? '',
      tutorName: data['tutorName'] ?? '',
      studentName: data['studentName'] ?? '',
      subject: data['subject'] ?? '',
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0,
      hours: (data['hours'] as num?)?.toDouble() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      note: data['note'] ?? '',
      startAt: _toDate(data['startAt']),
      endAt: _toDate(data['endAt']),
      status: data['status'] ?? BookingStatus.accepted,
      paid: data['paid'] ?? false,
      paymentMethod: data['paymentMethod'],
      cancelReason: data['cancelReason'],
      createdAt: _toDate(data['createdAt']),
      updatedAt:
      data['updatedAt'] == null ? null : _toDate(data['updatedAt']),
      mode: data['mode'] ?? 'online',
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'],
      ratedAt:
      data['ratedAt'] == null ? null : _toDate(data['ratedAt']),
      packageType: data['packageType'] ?? 'single',
      packageId: data['packageId'],
      totalSessions: data['totalSessions'] ?? 1,
      completedSessions: data['completedSessions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'studentId': studentId,
      'tutorName': tutorName,
      'studentName': studentName,
      'subject': subject,
      'pricePerHour': pricePerHour,
      'hours': hours,
      'price': price,
      'note': note,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status, // luôn là accepted khi tạo
      'paid': paid,
      'paymentMethod': paymentMethod,
      'cancelReason': cancelReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
      updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'mode': mode,
      'rating': rating,
      'review': review,
      'ratedAt': ratedAt == null ? null : Timestamp.fromDate(ratedAt!),
      'packageType': packageType,
      'packageId': packageId,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
    };
  }
}
