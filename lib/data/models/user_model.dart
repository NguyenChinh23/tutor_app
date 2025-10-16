class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final bool isTutorVerified;
  final String? goal;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.isTutorVerified,
    this.goal,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'],
      avatarUrl: data['avatarUrl'],
      role: data['role'] ?? 'student',
      isTutorVerified: data['isTutorVerified'] ?? false,
      goal: data['goal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role,
      'isTutorVerified': isTutorVerified,
      'goal': goal,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? goal,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      isTutorVerified: isTutorVerified,
      goal: goal ?? this.goal,
    );
  }
}
