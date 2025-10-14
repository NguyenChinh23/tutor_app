import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutor_app/data/models/user_model.dart';
import 'package:tutor_app/data/services/auth_service.dart';

class AuthRepository {
  final _fs = FirebaseFirestore.instance;
  final _auth = AuthService();

  CollectionReference<Map<String, dynamic>> get _users => _fs.collection('users');
  CollectionReference<Map<String, dynamic>> get _tutorApps => _fs.collection('tutorApplications');

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

  // 🔹 Reset password
  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // 🔹 Đăng xuất
  Future<void> logout() => _auth.signOut();

  // 🔹 Stream user Firestore realtime
  Stream<UserModel?> userDocStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data()!);
    });
  }

  // 🔹 Apply làm gia sư
  Future<void> applyTutor({
    required String uid,
    required String email,
    required String fullName,
    required String subject,
    required String experience,
    String? certificateUrl,
    String? description,
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
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
    });

    await _users.doc(uid).set({
      'role': 'tutor',
      'isTutorVerified': false,
    }, SetOptions(merge: true));
  }

  // ✅ Admin: duyệt hồ sơ tutor
  Future<void> approveTutor({
    required String uid,
    required String appId,
    required String reviewerUid,
  }) async {
    final batch = _fs.batch();

    final appRef = _tutorApps.doc(appId);
    batch.update(appRef, {
      'status': 'approved',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    final userRef = _users.doc(uid);
    batch.update(userRef, {
      'role': 'tutor',
      'isTutorVerified': true,
    });

    await batch.commit();
  }

  // ✅ Admin: từ chối hồ sơ tutor
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

  // 🔹 Nếu chưa có user → tạo mới mặc định student
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

  // 🔹 Firebase listeners
  Stream<User?> get authChanges => _auth.authChanges;
  User? get currentUser => _auth.currentUser;
}
