import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/data/repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository repository;

  BookingProvider({BookingRepository? repository})
      : repository = repository ?? BookingRepository();

  // ================= LIST =================
  List<BookingModel> _studentBookings = [];
  List<BookingModel> get studentBookings => _studentBookings;

  List<BookingModel> _tutorBookings = [];
  List<BookingModel> get tutorBookings => _tutorBookings;

  List<BookingModel> _adminBookings = [];
  List<BookingModel> get adminBookings => _adminBookings;

  // ================= LOADING =================
  bool _loadingStudent = false;
  bool get loadingStudent => _loadingStudent;

  bool _loadingTutor = false;
  bool get loadingTutor => _loadingTutor;

  bool _loadingAdmin = false;
  bool get loadingAdmin => _loadingAdmin;

  // ================= STREAM =================
  StreamSubscription<List<BookingModel>>? _studentSub;
  StreamSubscription<List<BookingModel>>? _tutorSub;
  StreamSubscription<List<BookingModel>>? _adminSub;

  // ================= LISTEN =================
  void listenForStudent(String studentId) {
    _studentSub?.cancel();
    _loadingStudent = true;
    notifyListeners();

    repository.streamForStudent(studentId).listen((list) {
      _studentBookings = _filterValid(list);
      _loadingStudent = false;
      notifyListeners();
    });
  }

  void listenForTutor(String tutorId) {
    _tutorSub?.cancel();
    _loadingTutor = true;
    notifyListeners();

    repository.streamForTutor(tutorId).listen((list) {
      _tutorBookings = _filterValid(list);
      _loadingTutor = false;
      notifyListeners();
    });
  }

  void listenForAdmin() {
    _adminSub?.cancel();
    _loadingAdmin = true;
    notifyListeners();

    repository.streamAllBookings().listen((list) {
      _adminBookings = _filterValid(list);
      _loadingAdmin = false;
      notifyListeners();
    });
  }

  List<BookingModel> _filterValid(List<BookingModel> list) {
    return list.where((b) => b.status != 'deleted_by_admin').toList();
  }

  // ================= CREATE =================
  /// BOOK LẺ hoặc BOOK GÓI → AUTO ACCEPT
  Future<void> createBooking({
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
    required String packageType, // single | 1m | 3m | 6m
    required int totalSessions,
  }) async {
    final booking = BookingModel(
      id: '',
      tutorId: tutorId,
      tutorName: tutorName,
      studentId: studentId,
      studentName: studentName,
      subject: subject,
      pricePerHour: pricePerHour,
      hours: hours,
      price: pricePerHour * hours * totalSessions,
      note: note,
      startAt: startAt,
      endAt: endAt,
      status: BookingStatus.accepted, // ✅ AUTO NHẬN
      paid: false,
      paymentMethod: null,
      cancelReason: null,
      createdAt: DateTime.now(),
      updatedAt: null,
      mode: mode,
      rating: null,
      review: null,
      ratedAt: null,
      packageType: packageType,
      packageId:
      packageType == 'single' ? null : 'pkg_${DateTime.now().millisecondsSinceEpoch}',
      totalSessions: totalSessions,
      completedSessions: 0,
    );

    await repository.createBooking(booking);
  }

  // ================= TUTOR =================

  /// Gia sư hoàn thành 1 buổi (tăng tiến độ)
  Future<void> tutorCompleteSession(BookingModel booking) async {
    final nextCompleted = booking.completedSessions + 1;

    if (nextCompleted >= booking.totalSessions) {
      // Hoàn thành toàn bộ gói
      await repository.updateStatus(
        bookingId: booking.id,
        status: BookingStatus.completed,
      );
    } else {
      await repository.updateProgress(
        bookingId: booking.id,
        completedSessions: nextCompleted,
      );
    }

    await repository.increaseTutorStats(
      tutorId: booking.tutorId,
      studentId: booking.studentId,
    );
  }

  /// Gia sư hủy booking
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

  // ================= RATING =================
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

  @override
  void dispose() {
    _studentSub?.cancel();
    _tutorSub?.cancel();
    _adminSub?.cancel();
    super.dispose();
  }
}
