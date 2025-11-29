import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/data/repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository repository;

  BookingProvider({required this.repository});

  List<BookingModel> studentBookings = [];
  List<BookingModel> tutorBookings = [];

  StreamSubscription? _studentSub;
  StreamSubscription? _tutorSub;

  /// Lắng nghe booking cho HỌC VIÊN
  void listenForStudent(String studentId) {
    _studentSub?.cancel();
    _studentSub = repository.listenStudent(studentId).listen((list) {
      studentBookings = list;
      notifyListeners();
    });
  }

  /// Lắng nghe booking cho GIA SƯ
  void listenForTutor(String tutorId) {
    _tutorSub?.cancel();
    _tutorSub = repository.listenTutor(tutorId).listen((list) {
      tutorBookings = list;
      notifyListeners();
    });
  }

  /// Tạo booking mới
  Future<void> createBooking(BookingModel booking) async {
    await repository.createBooking(booking);
    // stream Firestore sẽ tự đẩy data mới về -> notifyListeners đã có ở listen*
  }

  /// Cập nhật trạng thái booking (accepted / rejected / cancelled / completed)
  Future<void> updateStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) async {
    // Update trên Firestore
    await repository.updateStatus(
      bookingId: bookingId,
      status: status,
      cancelReason: cancelReason,
    );


    BookingModel _update(BookingModel b) {
      if (b.id != bookingId) return b;
      return b.copyWith(
        status: status,
        cancelReason: cancelReason,
        updatedAt: DateTime.now(),
      );
    }

    studentBookings = studentBookings.map(_update).toList();
    tutorBookings = tutorBookings.map(_update).toList();

    notifyListeners();
  }

  @override
  void dispose() {
    _studentSub?.cancel();
    _tutorSub?.cancel();
    super.dispose();
  }
}
