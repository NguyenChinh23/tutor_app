import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutor_app/data/models/user_model.dart';
import 'package:tutor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final _fs = FirebaseFirestore.instance;
  final _auth = AuthService();

  CollectionReference<Map<String, dynamic>> get _users => _fs.collection('users');
  CollectionReference<Map<String, dynamic>> get _tutorApps => _fs.collection('tutorApplications');

  //  Đăng ký email → mặc định role student
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

  //  Đăng nhập Email
  Future<UserModel?> login(String email, String password) async {
    final user = await _auth.signIn(email, password);
    if (user == null) return null;
    return _fetchOrCreateStudent(user);
  }

  //  Đăng nhập Google
  Future<UserModel?> loginWithGoogle() async {
    final user = await _auth.signInWithGoogle();
    if (user == null) return null;
    return _fetchOrCreateStudent(user);
  }

  //  Reset password
  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  //  Đăng xuất
  Future<void> logout() => _auth.signOut();

  //  Stream user Firestore realtime
  Stream<UserModel?> userDocStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data()!);
    });
  }

  //  Apply làm gia sư
  Future<void> applyTutor({
    required String uid,
    required String email,
    required String fullName,
    required String subject,
    required String experience,
    String? certificateUrl,
    String? description,
    double? price,
  }) async {
    final appId = _tutorApps.doc().id;
    await _tutorApps.doc(appId).set({
      'id': appId,
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'subject': subject,
      'experience': experience,
      'certificateUrl': certificateUrl,
      'description': description,
      'price': price ?? 0,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
    });

    // Cập nhật trạng thái user tạm thời
    await _users.doc(uid).set({
      'role': 'tutor',
      'isTutorVerified': false,
    }, SetOptions(merge: true));
  }

  //  Admin: duyệt hồ sơ tutor → đồng bộ dữ liệu sang users
  Future<void> approveTutor({
    required String uid,
    required String appId,
    required String reviewerUid,
  }) async {
    final appRef = _tutorApps.doc(appId);
    final userRef = _users.doc(uid);

    final appSnap = await appRef.get();
    if (!appSnap.exists) throw Exception("Hồ sơ ứng tuyển không tồn tại");
    final appData = appSnap.data()!;

    final batch = _fs.batch();

    // Cập nhật hồ sơ ứng tuyển
    batch.update(appRef, {
      'status': 'approved',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    //  Đồng bộ dữ liệu sang users
    batch.update(userRef, {
      'role': 'tutor',
      'isTutorVerified': true,
      'fullName': appData['fullName'] ?? '',
      'subject': appData['subject'] ?? '',
      'price': (appData['price'] ?? 0).toDouble(),
      'experience': appData['experience'] ?? '',
      'bio': appData['description'] ?? '',
      'certificateUrl': appData['certificateUrl'] ?? '',
      'rating': appData['rating'] ?? 0.0,
    });

    await batch.commit();
    debugPrint(" Hồ sơ tutor của $uid đã được duyệt và đồng bộ sang users");
  }

  //  Admin: từ chối hồ sơ tutor
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

  //  Nếu chưa có user → tạo mới mặc định student
  Future<UserModel?> _fetchOrCreateStudent(User user) async {
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);

    final newUser = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      role: 'student',
      isTutorVerified: false,
    );

    await _users.doc(user.uid).set(newUser.toMap());
    return newUser;
  }
  // Cập nhật thông tin hồ sơ người dùng (Firestore)
  Future<void> updateUserProfile(String uid, String? name, String? goal) async {
    await _users.doc(uid).set({
      'displayName': name,
      'goal': goal,
    }, SetOptions(merge: true));
  }


  // Firebase listeners
  Stream<User?> get authChanges => _auth.authChanges;
  User? get currentUser => _auth.currentUser;
}
