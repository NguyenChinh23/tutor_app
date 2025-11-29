import 'package:cloud_firestore/cloud_firestore.dart';

class BookingStatus {
  static const requested = 'requested';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
}

class BookingModel {
  final String id;
  final String tutorId;
  final String studentId;

  /// Lưu thêm tên để hiển thị nhanh, tránh phải join.
  final String tutorName;
  final String studentName;

  final String subject;

  /// Giá / giờ tại thời điểm booking
  final double pricePerHour;

  /// Số giờ của buổi học (ví dụ: 1.0, 1.5, 2.0)
  final double hours;

  /// Tổng tiền của buổi học (totalPrice)
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

  /// Hình thức học: online / offline_at_student / offline_at_tutor
  final String mode;

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
    this.paymentMethod,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
    this.mode = 'online',
  });

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    double _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    // Đọc dữ liệu cũ vẫn OK
    final price = _toDouble(data['totalPrice'] ?? data['price'] ?? 0);
    final hours = _toDouble(data['hours'] ?? 1);
    final pricePerHour = _toDouble(
      data['pricePerHour'] ?? (hours > 0 ? price / hours : 0),
    );

    return BookingModel(
      id: doc.id,
      tutorId: (data['tutorId'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      tutorName: (data['tutorName'] ?? '').toString(),
      studentName: (data['studentName'] ?? '').toString(),
      subject: (data['subject'] ?? '').toString(),
      pricePerHour: pricePerHour,
      hours: hours,
      price: price,
      note: (data['note'] ?? '').toString(),
      startAt: _toDate(data['startAt']),
      endAt: _toDate(data['endAt']),
      status: (data['status'] ?? BookingStatus.requested).toString(),
      paid: data['paid'] == true,
      paymentMethod: data['paymentMethod']?.toString(),
      cancelReason: data['cancelReason']?.toString(),
      createdAt: _toDate(data['createdAt']),
      updatedAt:
      data['updatedAt'] != null ? _toDate(data['updatedAt']) : null,
      mode: (data['mode'] ?? 'online').toString(),
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
      'totalPrice': price,
      'note': note,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status,
      'paid': paid,
      'paymentMethod': paymentMethod,
      'cancelReason': cancelReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
      updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'mode': mode,
    };
  }

  BookingModel copyWith({
    String? status,
    bool? paid,
    String? paymentMethod,
    String? cancelReason,
    DateTime? updatedAt,
    String? mode,
  }) {
    return BookingModel(
      id: id,
      tutorId: tutorId,
      studentId: studentId,
      tutorName: tutorName,
      studentName: studentName,
      subject: subject,
      pricePerHour: pricePerHour,
      hours: hours,
      price: price,
      note: note,
      startAt: startAt,
      endAt: endAt,
      status: status ?? this.status,
      paid: paid ?? this.paid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mode: mode ?? this.mode,
    );
  }
}
