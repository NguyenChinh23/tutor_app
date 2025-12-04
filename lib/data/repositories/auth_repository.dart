import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tutor_app/data/models/user_model.dart';
import 'package:tutor_app/data/services/auth_service.dart';

class AuthRepository {
  final _fs = FirebaseFirestore.instance;
  final _auth = AuthService();

  CollectionReference<Map<String, dynamic>> get _users =>
      _fs.collection('users');
  CollectionReference<Map<String, dynamic>> get _tutorApps =>
      _fs.collection('tutorApplications');

  // 🔹 Đăng ký email → mặc định role student
  Future<UserModel?> register(String email, String password) async {
    final user = await _auth.signUp(email, password);
    if (user == null) return null;

    final newUser = UserModel(
      uid: user.uid,
      email: user.email ?? email,
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      role: 'student',
      isTutorVerified: false,
    );

    await _users.doc(user.uid).set(newUser.toMap(), SetOptions(merge: true));
    return newUser;
  }

  // 🔹 Đăng nhập Email
  Future<UserModel?> login(String email, String password) async {
    final user = await _auth.signIn(email, password);
    if (user == null) return null;
    return _fetchOrCreateStudent(user);
  }

  // 🔹 Đăng nhập Google
  Future<UserModel?> loginWithGoogle() async {
    final user = await _auth.signInWithGoogle();
    if (user == null) return null;
    return _fetchOrCreateStudent(user);
  }

  // 🔹 Reset password (dùng logic trong AuthService: check method password)
  Future<void> resetPassword(String email) async {
    await _auth.resetPassword(email);
  }

  Future<void> logout() => _auth.signOut();

  // 🔹 Stream user realtime từ Firestore
  Stream<UserModel?> userDocStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromDoc(snap);
    });
  }

  // ===============================
  //  APPLY → APPROVE / REJECT TUTOR
  // ===============================

  Future<void> applyTutor({
    required String uid,
    required String email,
    required String fullName,
    required String subject,
    required String experience,
    required String description,
    required double price,
    String? certificateUrl,
    String? avatarUrl,
  }) async {
    final appId = _tutorApps.doc().id;

    await _tutorApps.doc(appId).set({
      'id': appId,
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'subject': subject,
      'experience': experience,
      'description': description,
      'price': price,
      'certificateUrl': certificateUrl ?? '',
      'avatarUrl': avatarUrl ?? '',
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });

    await _users.doc(uid).set(
      {
        'role': 'tutor',
        'isTutorVerified': false,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> approveTutor({
    required String uid,
    required String appId,
    required String reviewerUid,
  }) async {
    final appRef = _tutorApps.doc(appId);
    final userRef = _users.doc(uid);

    final appSnap = await appRef.get();
    if (!appSnap.exists) throw Exception("Tutor application does not exist");

    final appData = appSnap.data()!;

    final batch = _fs.batch();

    batch.update(appRef, {
      'status': 'approved',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'role': 'tutor',
      'isTutorVerified': true,
      'displayName': appData['fullName'],
      'subject': appData['subject'],
      'price': (appData['price'] ?? 0).toDouble(),
      'experience': appData['experience'],
      'bio': appData['description'],
      'avatarUrl': appData['avatarUrl'],
    });

    await batch.commit();
  }

  Future<void> rejectTutor({
    required String appId,
    required String reviewerUid,
  }) async {
    await _tutorApps.doc(appId).update({
      'status': 'rejected',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ====================================================
  //  TẠO HOẶC LẤY USER (login lần đầu)
  // ====================================================

  Future<UserModel?> _fetchOrCreateStudent(User user) async {
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return UserModel.fromDoc(doc);

    final newUser = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      role: 'student',
      isTutorVerified: false,
    );

    await _users.doc(user.uid).set(newUser.toMap(), SetOptions(merge: true));
    return newUser;
  }

  // 🔹 Cập nhật hồ sơ người dùng
  Future<void> updateUserProfile(
      String uid,
      String name,
      String goal, {
        String? avatarUrl,
        String? subject,
        String? bio,
        double? price,
        String? experience,
        String? availabilityNote,
      }) async {
    final data = <String, dynamic>{
      'displayName': name,
      'goal': goal,
    };

    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (subject != null) data['subject'] = subject;
    if (bio != null) data['bio'] = bio;
    if (price != null) data['price'] = price;
    if (experience != null) data['experience'] = experience;
    if (availabilityNote != null) data['availabilityNote'] = availabilityNote;

    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  // 🔹 Auth stream & current user từ FirebaseAuth
  Stream<User?> get authChanges => _auth.authChanges;
  User? get currentUser => _auth.currentUser;
}
