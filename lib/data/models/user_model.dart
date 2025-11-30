import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'student' | 'tutor' | 'admin'
  final bool isTutorVerified;

  final String? displayName;
  final String? avatarUrl;
  final String? goal;

  // field dành cho tutor
  final String? subject;
  final String? bio;
  final double? price;
  final String? experience;
  final String? availabilityNote; // 🆕 lịch rảnh

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.isTutorVerified = false,
    this.displayName,
    this.avatarUrl,
    this.goal,
    this.subject,
    this.bio,
    this.price,
    this.experience,
    this.availabilityNote,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return UserModel(
      uid: doc.id,
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'student').toString(),
      isTutorVerified: data['isTutorVerified'] == true,
      displayName: data['displayName']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      goal: data['goal']?.toString(),
      subject: data['subject']?.toString(),
      bio: data['bio']?.toString(),
      price: _toDouble(data['price']),
      experience: data['experience']?.toString(),
      availabilityNote: data['availabilityNote']?.toString(), // 🆕
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'isTutorVerified': isTutorVerified,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'goal': goal,
      'subject': subject,
      'bio': bio,
      'price': price,
      'experience': experience,
      'availabilityNote': availabilityNote, // 🆕
    };
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? goal,
    String? subject,
    String? bio,
    double? price,
    String? experience,
    bool? isTutorVerified,
    String? availabilityNote,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      role: role,
      isTutorVerified: isTutorVerified ?? this.isTutorVerified,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      goal: goal ?? this.goal,
      subject: subject ?? this.subject,
      bio: bio ?? this.bio,
      price: price ?? this.price,
      experience: experience ?? this.experience,
      availabilityNote: availabilityNote ?? this.availabilityNote,
    );
  }
}
