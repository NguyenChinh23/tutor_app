import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/data/repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository repository;

  BookingProvider({BookingRepository? repository})
      : repository = repository ?? BookingRepository();

  // STATE LIST
  List<BookingModel> _studentBookings = [];
  List<BookingModel> get studentBookings => _studentBookings;

  List<BookingModel> _tutorBookings = [];
  List<BookingModel> get tutorBookings => _tutorBookings;

  bool _loadingStudent = false;
  bool get loadingStudent => _loadingStudent;

  bool _loadingTutor = false;
  bool get loadingTutor => _loadingTutor;
  // STREAM HỌC VIÊN
  void listenForStudent(String studentId) {
    _loadingStudent = true;
    notifyListeners();
    repository.streamForStudent(studentId).listen((list) {
      _studentBookings = list;
      _loadingStudent = false;
      notifyListeners();
    });
  }
  // STREAM GIA SƯ
  void listenForTutor(String tutorId) {
    _loadingTutor = true;
    notifyListeners();
    repository.streamForTutor(tutorId).listen((list) {
      _tutorBookings = list;
      _loadingTutor = false;
      notifyListeners();
    });
  }
  // HELPER GỘP NGÀY + GIỜ
  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  // TẠO 1 BOOKING TỪ NGOÀI
  Future<void> createBooking(BookingModel booking) {
    return repository.createBooking(booking);
  }

  // ĐẶT 1 BUỔI LẺ
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
    String note = '',
    String mode = 'online',
  }) async {
    if (!endAt.isAfter(startAt)) {
      throw Exception('Thời lượng không hợp lệ');
    }

    final booking = BookingModel(
      id: '',
      tutorId: tutorId,
      studentId: studentId,
      tutorName: tutorName,
      studentName: studentName,
      subject: subject,
      pricePerHour: pricePerHour,
      hours: hours,
      price: pricePerHour * hours,
      note: note,
      startAt: startAt,
      endAt: endAt,
      status: BookingStatus.requested,
      paid: false,
      paymentMethod: null,
      cancelReason: null,
      createdAt: DateTime.now(),
      updatedAt: null,
      mode: mode,
      rating: null,
      review: null,
      ratedAt: null,
      packageId: null,
      packageType: 'single',
      sessionIndex: 1,
      totalSessions: 1,
    );

    await repository.createBooking(booking);
  }
  // ĐẶT THEO GÓI
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
    required int sessionsPerWeek,
    String note = '',
    String mode = 'online',
  }) async {
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
        weeks = 0;
    }

    final totalSessions = weeks * sessionsPerWeek;
    if (totalSessions <= 0) return;

    final firstStart = _combine(startDate, timeStart);
    final firstEnd = _combine(startDate, timeEnd);

    if (!firstEnd.isAfter(firstStart)) {
      throw Exception('Thời gian bắt đầu / kết thúc không hợp lệ');
    }

    int created = 0;
    final now = DateTime.now();

    // Đơn giản: mỗi tuần s buổi, cách nhau 1 ngày, bắt đầu từ startDate
    for (int week = 0; week < weeks; week++) {
      for (int s = 0; s < sessionsPerWeek; s++) {
        if (created >= totalSessions) break;

        final date = startDate.add(Duration(days: week * 7 + s));
        final startAt = _combine(date, timeStart);
        final endAt = _combine(date, timeEnd);

        final booking = BookingModel(
          id: '',
          tutorId: tutorId,
          studentId: studentId,
          tutorName: tutorName,
          studentName: studentName,
          subject: subject,
          pricePerHour: pricePerHour,
          hours: hours,
          price: pricePerHour * hours,
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
          packageId: null, // nếu sau này cần group theo gói thì thêm logic
          packageType: packageType,
          sessionIndex: created + 1,
          totalSessions: totalSessions,
        );

        await repository.createBooking(booking);
        created++;
      }
    }
  }

  // THAY ĐỔI TRẠNG THÁI CHUNG
  Future<void> updateStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) {
    return repository.updateStatus(
      bookingId: bookingId,
      status: status,
      cancelReason: cancelReason,
    );
  }

  // GIA SƯ ĐÁNH DẤU HOÀN THÀNH
  Future<void> tutorCompleteBooking(BookingModel booking) async {
    await repository.updateStatus(
      bookingId: booking.id,
      status: BookingStatus.completed,
    );
  }

  // GIA SƯ HUỶ BUỔI HỌC
  Future<void> tutorCancelBooking(
      BookingModel booking, {
        String? reason,
      }) async {
    await repository.updateStatus(
      bookingId: booking.id,
      status: BookingStatus.cancelled,
      cancelReason: reason,
    );
  }

  // GỬI ĐÁNH GIÁ
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