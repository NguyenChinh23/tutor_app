import 'package:cloud_firestore/cloud_firestore.dart';

class BookingStatus {
  static const String requested = 'requested';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
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

  final String status;

  final bool paid;
  final String? paymentMethod;

  final String? cancelReason;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final String mode; // online / offline_at_student / offline_at_tutor

  // Đánh giá
  final double? rating;
  final String? review;
  final DateTime? ratedAt;

  // Thông tin gói
  final String? packageType;   // 'single' | '1m' | '3m' | '6m'
  final String? packageId;     // id chung cho cả gói
  final int? sessionIndex;     // buổi thứ mấy trong gói
  final int? totalSessions;    // tổng số buổi trong gói

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
    required this.sessionIndex,
    required this.totalSessions,
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
      tutorId: (data['tutorId'] ?? '') as String,
      studentId: (data['studentId'] ?? '') as String,
      tutorName: (data['tutorName'] ?? '') as String,
      studentName: (data['studentName'] ?? '') as String,
      subject: (data['subject'] ?? '') as String,
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0,
      hours: (data['hours'] as num?)?.toDouble() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      note: (data['note'] ?? '') as String,
      startAt: _toDate(data['startAt']),
      endAt: _toDate(data['endAt']),
      status: (data['status'] ?? BookingStatus.requested) as String,
      paid: (data['paid'] ?? false) as bool,
      paymentMethod: data['paymentMethod'] as String?,
      cancelReason: data['cancelReason'] as String?,
      createdAt: _toDate(data['createdAt']),
      updatedAt:
      data['updatedAt'] == null ? null : _toDate(data['updatedAt']),
      mode: (data['mode'] ?? 'online') as String,
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'] as String?,
      ratedAt:
      data['ratedAt'] == null ? null : _toDate(data['ratedAt']),
      packageType: data['packageType'] as String?,
      packageId: data['packageId'] as String?,
      sessionIndex: data['sessionIndex'] as int?,
      totalSessions: data['totalSessions'] as int?,
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
      'status': status,
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
      'sessionIndex': sessionIndex,
      'totalSessions': totalSessions,
    };
  }
}