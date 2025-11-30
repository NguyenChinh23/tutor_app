import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _fs;

  BookingRepository({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  /// Stream các booking của HỌC VIÊN
  Stream<List<BookingModel>> streamForStudent(String studentId) {
    return _fs
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .orderBy('startAt')
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((doc) => BookingModel.fromDoc(doc)).toList(),
    );
  }

  /// Stream các booking của GIA SƯ
  Stream<List<BookingModel>> streamForTutor(String tutorId) {
    return _fs
        .collection('bookings')
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('startAt')
        .snapshots()
        .map(
          (snap) =>
          snap.docs.map((doc) => BookingModel.fromDoc(doc)).toList(),
    );
  }

  /// Tạo 1 booking
  Future<void> createBooking(BookingModel booking) async {
    await _fs.collection('bookings').add(booking.toMap());
  }

  /// Update status
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

  /// Lưu đánh giá + tính lại rating trung bình của tutor
  Future<void> submitRating({
    required String bookingId,
    required String tutorId,
    required double rating,
    required String review,
  }) async {
    final bookingRef = _fs.collection('bookings').doc(bookingId);

    await bookingRef.update({
      'rating': rating,
      'review': review,
      'status': BookingStatus.completed,
      'ratedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _recalculateTutorRating(tutorId);
  }

  Future<void> _recalculateTutorRating(String tutorId) async {
    final snap = await _fs
        .collection('bookings')
        .where('tutorId', isEqualTo: tutorId)
        .where('rating', isGreaterThan: 0)
        .get();

    if (snap.docs.isEmpty) {
      await _fs.collection('users').doc(tutorId).set(
        {
          'rating': 0.0,
          'ratingCount': 0,
        },
        SetOptions(merge: true),
      );
      return;
    }

    double sum = 0;
    final count = snap.docs.length;

    for (final doc in snap.docs) {
      final data = doc.data();
      final r = (data['rating'] as num?)?.toDouble() ?? 0;
      sum += r;
    }

    final avg = sum / count;

    await _fs.collection('users').doc(tutorId).set(
      {
        'rating': avg,
        'ratingCount': count,
      },
      SetOptions(merge: true),
    );
  }
}
