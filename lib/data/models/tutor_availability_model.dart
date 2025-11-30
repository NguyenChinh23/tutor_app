import 'package:cloud_firestore/cloud_firestore.dart';

/// Một khung giờ rảnh trong tuần
class AvailabilitySlot {
  /// Thứ trong tuần: 1 = Monday, ... 7 = Sunday
  final int weekday;
  /// "HH:mm"
  final String start;
  /// "HH:mm"
  final String end;

  AvailabilitySlot({
    required this.weekday,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekday': weekday,
      'start': start,
      'end': end,
    };
  }

  factory AvailabilitySlot.fromMap(Map<String, dynamic> data) {
    return AvailabilitySlot(
      weekday: (data['weekday'] ?? 1) as int,
      start: (data['start'] ?? '00:00').toString(),
      end: (data['end'] ?? '00:00').toString(),
    );
  }
}

/// Availability của một gia sư
class TutorAvailability {
  final String tutorId;
  final List<AvailabilitySlot> slots;
  final DateTime? updatedAt;

  TutorAvailability({
    required this.tutorId,
    required this.slots,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'slots': slots.map((s) => s.toMap()).toList(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory TutorAvailability.fromDoc(
      String tutorId, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawSlots = (data['slots'] as List<dynamic>? ?? []);
    final slots = rawSlots
        .map((e) => AvailabilitySlot.fromMap(
        (e as Map<String, dynamic>)))
        .toList();

    DateTime? _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return TutorAvailability(
      tutorId: tutorId,
      slots: slots,
      updatedAt: _toDate(data['updatedAt']),
    );
  }
}
