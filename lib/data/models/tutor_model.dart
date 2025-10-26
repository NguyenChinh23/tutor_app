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
  });

  factory TutorModel.fromMap(String id, Map<String, dynamic> data) {
    return TutorModel(
      uid: id,
      // đồng bộ name từ displayName / fullName / name
      name: (data['displayName'] ?? data['fullName'] ?? data['name'] ?? 'Unknown Tutor').toString(),
      email: (data['email'] ?? '').toString(),
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      subject: (data['subject'] ?? 'General').toString(),
      bio: (data['bio'] ?? 'No bio available.').toString(),
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] is int)
          ? (data['rating'] as int).toDouble()
          : (data['rating'] ?? 0.0).toDouble(),
      experience: (data['experience'] ?? 'Chưa cập nhật').toString(),
      isTutorVerified: data['isTutorVerified'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'subject': subject,
      'bio': bio,
      'price': price,
      'rating': rating,
      'experience': experience,
      'isTutorVerified': isTutorVerified,
    };
  }
}
