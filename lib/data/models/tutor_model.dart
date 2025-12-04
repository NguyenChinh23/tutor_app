// lib/data/models/tutor_model.dart
class TutorModel {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final String subject;
  final String bio;
  final double price;
  final double rating;
  final String experience;
  final bool isTutorVerified;
  final String availabilityNote;
  final int totalLessons;   // tổng số buổi dạy đã hoàn thành
  final int totalStudents;  // tổng số học viên đã dạy

  TutorModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.subject,
    required this.bio,
    required this.price,
    required this.rating,
    required this.experience,
    this.isTutorVerified = false,
    this.availabilityNote = '',
    this.totalLessons = 0,
    this.totalStudents = 0,
  });

  factory TutorModel.fromMap(String id, Map<String, dynamic> data) {
    double _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return TutorModel(
      uid: id,
      name: (data['displayName'] ??
          data['fullName'] ??
          data['name'] ??
          'Unknown Tutor')
          .toString(),
      email: (data['email'] ?? '').toString(),
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      subject: (data['subject'] ?? 'General').toString(),
      bio: (data['bio'] ?? 'No bio available.').toString(),
      price: _toDouble(data['price'] ?? 0),
      rating: _toDouble(data['rating'] ?? 0),
      experience: (data['experience'] ?? '').toString(),

      /// đọc field mới, nếu chưa có thì rỗng / 0
      availabilityNote: (data['availabilityNote'] ?? '').toString(),
      isTutorVerified: data['isTutorVerified'] == true,

      // 🔹 đọc từ Firestore, nếu chưa có thì = 0
      totalLessons: _toInt(data['totalLessons']),
      totalStudents: _toInt(data['totalStudents']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'subject': subject,
      'bio': bio,
      'price': price,
      'rating': rating,
      'experience': experience,
      'isTutorVerified': isTutorVerified,
      'availabilityNote': availabilityNote,
      // 🔹 ghi thêm 2 field mới
      'totalLessons': totalLessons,
      'totalStudents': totalStudents,
    };
  }
}
