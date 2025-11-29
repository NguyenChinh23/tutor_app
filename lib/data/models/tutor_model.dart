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
  });

  factory TutorModel.fromMap(String id, Map<String, dynamic> data) {
    double _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
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

      /// đọc field mới, nếu chưa có thì rỗng
      availabilityNote: (data['availabilityNote'] ?? '').toString(),
      isTutorVerified: data['isTutorVerified'] == true,
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
    };
  }
}
