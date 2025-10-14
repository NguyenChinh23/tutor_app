class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final bool isTutorVerified;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.isTutorVerified,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'role': role,
    'isTutorVerified': isTutorVerified,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    displayName: map['displayName'],
    avatarUrl: map['avatarUrl'],
    role: map['role'] ?? 'student',
    isTutorVerified: map['isTutorVerified'] ?? false,
  );
}
