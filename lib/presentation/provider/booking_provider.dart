import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/data/repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository repository;

  BookingProvider({BookingRepository? repository})
      : repository = repository ?? BookingRepository();

  // ================== STATE ==================
  List<BookingModel> _studentBookings = [];
  List<BookingModel> get studentBookings => _studentBookings;

  List<BookingModel> _tutorBookings = [];
  List<BookingModel> get tutorBookings => _tutorBookings;

  bool _loadingStudent = false;
  bool get loadingStudent => _loadingStudent;

  bool _loadingTutor = false;
  bool get loadingTutor => _loadingTutor;

  // ================== STREAM LISTENERS ==================
  void listenForStudent(String studentId) {
    _loadingStudent = true;
    notifyListeners();

    repository.streamForStudent(studentId).listen((list) {
      _studentBookings = list;
      _loadingStudent = false;
      notifyListeners();
    });
  }

  void listenForTutor(String tutorId) {
    _loadingTutor = true;
    notifyListeners();

    repository.streamForTutor(tutorId).listen((list) {
      _tutorBookings = list;
      _loadingTutor = false;
      notifyListeners();
    });
  }

  // ================== TẠO BOOKING ==================

  /// Tạo 1 buổi lẻ
  Future<void> createSingleBooking({
    required String tutorId,
    required String tutorName,
    required String studentId,
    required String studentName,
    required String subject,
    required double pricePerHour,
    required double hours,
    required DateTime startAt,
    required DateTime endAt,
    required String note,
    required String mode,
  }) async {
    final now = DateTime.now();
    final total = pricePerHour * hours;

    final booking = BookingModel(
      id: '',
      tutorId: tutorId,
      tutorName: tutorName,
      studentId: studentId,
      studentName: studentName,
      subject: subject,
      pricePerHour: pricePerHour,
      hours: hours,
      price: total,
      note: note,
      startAt: startAt,
      endAt: endAt,
      status: BookingStatus.requested,
      paid: false,
      paymentMethod: null,
      cancelReason: null,
      createdAt: now,
      updatedAt: null,
      mode: mode,
      rating: null,
      review: null,
      ratedAt: null,
      packageType: "single",
      packageId: null,
      sessionIndex: null,
      totalSessions: null,
    );

    await repository.createBooking(booking);
  }

  /// Tạo booking theo GÓI
  Future<void> createPackageBookings({
    required String tutorId,
    required String tutorName,
    required String studentId,
    required String studentName,
    required String subject,
    required double pricePerHour,
    required double hours,
    required DateTime startDate,
    required TimeOfDay timeStart,
    required TimeOfDay timeEnd,
    required String packageType, // '1m' | '3m' | '6m'
    required List<int> weekdays,
    String? packageId, // có thể truyền từ UI, nếu null sẽ tự sinh
    required String note,
    required String mode,
  }) async {
    // số tuần của gói
    int weeks;
    switch (packageType) {
      case '1m':
        weeks = 4;
        break;
      case '3m':
        weeks = 12;
        break;
      case '6m':
        weeks = 24;
        break;
      default:
        return;
    }

    if (weekdays.isEmpty) return;

    final now = DateTime.now();
    final pkgId = packageId ?? "pkg_${now.millisecondsSinceEpoch}";
    final totalOneSession = pricePerHour * hours;

    // gom tất cả ngày học thuộc gói
    final endDate = startDate.add(Duration(days: weeks * 7));
    DateTime cursor = startDate;
    final sessionDates = <DateTime>[];

    while (!cursor.isAfter(endDate)) {
      if (weekdays.contains(cursor.weekday)) {
        sessionDates.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (sessionDates.isEmpty) return;

    final totalSessions = sessionDates.length;
    final futures = <Future<void>>[];

    for (var i = 0; i < sessionDates.length; i++) {
      final d = sessionDates[i];

      final startAt = DateTime(
        d.year,
        d.month,
        d.day,
        timeStart.hour,
        timeStart.minute,
      );
      final endAt = DateTime(
        d.year,
        d.month,
        d.day,
        timeEnd.hour,
        timeEnd.minute,
      );

      final booking = BookingModel(
        id: '',
        tutorId: tutorId,
        tutorName: tutorName,
        studentId: studentId,
        studentName: studentName,
        subject: subject,
        pricePerHour: pricePerHour,
        hours: hours,
        price: totalOneSession,
        note: note,
        startAt: startAt,
        endAt: endAt,
        status: BookingStatus.requested,
        paid: false,
        paymentMethod: null,
        cancelReason: null,
        createdAt: now,
        updatedAt: null,
        mode: mode,
        rating: null,
        review: null,
        ratedAt: null,
        packageType: packageType,
        packageId: pkgId,
        sessionIndex: i + 1,
        totalSessions: totalSessions,
      );

      futures.add(repository.createBooking(booking));
    }

    await Future.wait(futures);
  }

  // ================== UPDATE TRẠNG THÁI ==================
  Future<void> updateBookingStatus(
      String bookingId,
      String status, {
        String? cancelReason,
      }) async {
    await repository.updateStatus(
      bookingId: bookingId,
      status: status,
      cancelReason: cancelReason,
    );
  }

  /// Cập nhật cả gói theo packageId
  Future<void> updateBookingStatusGroup(
      String packageId,
      String status, {
        String? cancelReason,
      }) async {
    final list =
    _tutorBookings.where((b) => b.packageId == packageId).toList();

    if (list.isEmpty) return;

    final futures = <Future<void>>[];
    for (final b in list) {
      futures.add(
        repository.updateStatus(
          bookingId: b.id,
          status: status,
          cancelReason: cancelReason,
        ),
      );
    }

    await Future.wait(futures);
  }

  // ================== GIA SƯ HOÀN THÀNH/HỦY BUỔI ==================

  Future<void> tutorCompleteBooking(BookingModel booking) async {
    await updateBookingStatus(booking.id, BookingStatus.completed);
  }

  Future<void> tutorCancelBooking(
      BookingModel booking, {
        String? reason,
      }) async {
    await updateBookingStatus(
      booking.id,
      BookingStatus.cancelled,
      cancelReason: reason,
    );
  }

  // ================== ĐÁNH GIÁ ==================
  Future<void> submitRating({
    required BookingModel booking,
    required double rating,
    required String review,
  }) {
    return repository.submitRating(
      bookingId: booking.id,
      tutorId: booking.tutorId,
      rating: rating,
      review: review,
    );
  }
}
