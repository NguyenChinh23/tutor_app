import 'package:cloud_firestore/cloud_firestore.dart';

class TutorRequestModel {
  final String id;
  final String tutorId;
  final String studentId;
  final String studentName;
  final String subject;
  final String level;
  final String preferredTime;
  final String pricePerSession;
  final String note;
  final String status; // pending / accepted / rejected
  final DateTime createdAt;

  TutorRequestModel({
    required this.id,
    required this.tutorId,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.level,
    required this.preferredTime,
    required this.pricePerSession,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory TutorRequestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TutorRequestModel(
      id: doc.id,
      tutorId: (data['tutorId'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      studentName: (data['studentName'] ?? 'Học viên').toString(),
      subject: (data['subject'] ?? 'Môn học').toString(),
      level: (data['level'] ?? '').toString(),
      preferredTime: (data['preferredTime'] ?? '').toString(),
      pricePerSession: (data['pricePerSession'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'studentId': studentId,
      'studentName': studentName,
      'subject': subject,
      'level': level,
      'preferredTime': preferredTime,
      'pricePerSession': pricePerSession,
      'note': note,
      'status': status,
      'createdAt': createdAt,
    };
  }

  TutorRequestModel copyWith({
    String? status,
  }) {
    return TutorRequestModel(
      id: id,
      tutorId: tutorId,
      studentId: studentId,
      studentName: studentName,
      subject: subject,
      level: level,
      preferredTime: preferredTime,
      pricePerSession: pricePerSession,
      note: note,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
