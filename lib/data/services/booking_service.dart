import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/booking_model.dart';

class BookingService {
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _fs.collection('bookings');

  Future<String> createBooking(BookingModel booking) async {
    final doc = await _bookings.add(booking.toMap());
    return doc.id;
  }

  Future<void> updateStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) async {
    await _bookings.doc(bookingId).update({
      'status': status,
      'cancelReason': cancelReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BookingModel>> listenBookingsForStudent(String studentId) {
    return _bookings
        .where('studentId', isEqualTo: studentId)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList(),
    );
  }

  Stream<List<BookingModel>> listenBookingsForTutor(String tutorId) {
    return _bookings
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList(),
    );
  }
}
