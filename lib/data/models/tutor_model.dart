class TutorModel {
  final String uid;
  final String name;
  final String subject;
  final String bio;
  final double price;
  final double rating;
  final String? avatarUrl;
  final bool isTutorVerified;

  TutorModel({
    required this.uid,
    required this.name,
    required this.subject,
    required this.bio,
    required this.price,
    required this.rating,
    this.avatarUrl,
    this.isTutorVerified = false,
  });

  factory TutorModel.fromMap(String id, Map<String, dynamic> data) {
    return TutorModel(
      uid: id,
      name: data['displayName'] ?? data['name'] ?? 'Unknown Tutor',
      subject: data['subject'] ?? 'General',
      bio: data['bio'] ?? 'No bio available.',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] is int)
          ? (data['rating'] as int).toDouble()
          : (data['rating'] ?? 0.0).toDouble(),
      avatarUrl: data['avatarUrl'] ?? '',
      isTutorVerified: data['isTutorVerified'] ?? false,
    );
  }

}
