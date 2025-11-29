import 'package:tutor_app/data/models/booking_model.dart';
import 'package:tutor_app/data/services/booking_service.dart';

class BookingRepository {
  final BookingService service;

  BookingRepository(this.service);

  Future<String> createBooking(BookingModel booking) =>
      service.createBooking(booking);

  Future<void> updateStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) =>
      service.updateStatus(
        bookingId: bookingId,
        status: status,
        cancelReason: cancelReason,
      );

  Stream<List<BookingModel>> listenStudent(String studentId) =>
      service.listenBookingsForStudent(studentId);

  Stream<List<BookingModel>> listenTutor(String tutorId) =>
      service.listenBookingsForTutor(tutorId);
}
