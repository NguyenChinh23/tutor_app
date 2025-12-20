import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _fs;

  BookingService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  // ================= STREAM =================

  Stream<List<BookingModel>> streamForStudent(String studentId) {
    return _fs
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .orderBy('startAt')
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((d) => BookingModel.fromDoc(d)).toList(),
    );
  }

  Stream<List<BookingModel>> streamForTutor(String tutorId) {
    return _fs
        .collection('bookings')
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('startAt')
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((d) => BookingModel.fromDoc(d)).toList(),
    );
  }

  Stream<List<BookingModel>> streamAll() {
    return _fs
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((d) => BookingModel.fromDoc(d)).toList(),
    );
  }

  // ================= CREATE =================

  Future<void> createBooking(BookingModel booking) async {
    await _fs.collection('bookings').add(booking.toMap());
  }

  // ===== BUỔI LẺ – AUTO ACCEPT =====
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

      // 🔥 AUTO ACCEPT
      status: BookingStatus.accepted,

      paid: false,
      paymentMethod: null,
      cancelReason: null,
      createdAt: DateTime.now(),
      updatedAt: null,
      mode: mode,
      rating: null,
      review: null,
      ratedAt: null,

      // GÓI
      packageType: 'single',
      packageId: null,
      totalSessions: 1,
      completedSessions: 0,
    );

    await createBooking(booking);
  }

  // ===== GÓI HỌC – AUTO ACCEPT =====
  Future<void> createPackageBookings({
    required String tutorId,
    required String tutorName,
    required String studentId,
    required String studentName,
    required String subject,
    required double pricePerHour,
    required double hours,
    required DateTime startDate,
    required DateTime endDate,
    required String packageType, // '1m' | '3m' | '6m'
    String note = '',
    String mode = 'online',
  }) async {
    int totalSessions;
    switch (packageType) {
      case '1m':
        totalSessions = 8;
        break;
      case '3m':
        totalSessions = 24;
        break;
      case '6m':
        totalSessions = 48;
        break;
      default:
        return;
    }

    final packageId =
        'pkg_${DateTime.now().millisecondsSinceEpoch}';

    final booking = BookingModel(
      id: '',
      tutorId: tutorId,
      studentId: studentId,
      tutorName: tutorName,
      studentName: studentName,
      subject: subject,
      pricePerHour: pricePerHour,
      hours: hours,
      price: pricePerHour * hours * totalSessions,
      note: note,
      startAt: startDate,
      endAt: endDate,
      status: BookingStatus.accepted,

      paid: false,
      paymentMethod: null,
      cancelReason: null,
      createdAt: DateTime.now(),
      updatedAt: null,
      mode: mode,
      rating: null,
      review: null,
      ratedAt: null,

      // GÓI
      packageType: packageType,
      packageId: packageId,
      totalSessions: totalSessions,
      completedSessions: 0,
    );

    await createBooking(booking);
  }

  // ================= UPDATE =================

  Future<void> updateStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (cancelReason != null && cancelReason.isNotEmpty) {
      data['cancelReason'] = cancelReason;
    }

    await _fs.collection('bookings').doc(bookingId).update(data);
  }

  Future<void> deleteBooking(String bookingId) async {
    await _fs.collection('bookings').doc(bookingId).delete();
  }

  Future<void> deletePackage(String packageId) async {
    final snap = await _fs
        .collection('bookings')
        .where('packageId', isEqualTo: packageId)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
