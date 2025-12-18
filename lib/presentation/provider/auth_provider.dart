import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutor_app/data/models/user_model.dart';
import 'package:tutor_app/data/repositories/auth_repository.dart';
import 'package:tutor_app/config/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum AuthStatus { guest, authenticated }

class AppAuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  UserModel? _user;
  UserModel? get user => _user;

  AuthStatus _status = AuthStatus.guest;
  AuthStatus get status => _status;

  bool _loading = false;
  bool get isLoading => _loading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  StreamSubscription? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  // ===============================
  // BOOTSTRAP (GUEST + AUTO LOGIN)
  // ===============================
  void bootstrap() {
    _authSub?.cancel();
    _authSub = _repo.authChanges.listen((fbUser) {
      _userSub?.cancel();

      if (fbUser == null) {
        _user = null;
        _status = AuthStatus.guest;
        notifyListeners();
        return;
      }

      _userSub = _repo.userDocStream(fbUser.uid).listen((u) async {
        if (u == null) return;

        if (u.isBlocked) {
          await logout();
          return;
        }

        _user = u;
        _status = AuthStatus.authenticated;
        notifyListeners();
        _navigateAfterLogin(u);
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  void _navigateAfterLogin(UserModel u) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      final role = u.role.trim().toLowerCase();
      final target =
      (role == 'tutor' && u.isTutorVerified)
          ? AppRouter.tutorHome
          : AppRouter.studentHome;

      Navigator.pushNamedAndRemoveUntil(ctx, target, (_) => false);
    });
  }

  // ===============================
  // REQUIRE LOGIN (BOOK DÙNG)
  // ===============================
  bool requireLogin(BuildContext context) {
    if (_status == AuthStatus.guest) {
      Navigator.pushNamed(context, AppRouter.login);
      return false;
    }
    return true;
  }

  // ===============================
  // LOGIN
  // ===============================
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.login(email, password);
      if (user == null) throw Exception("Không thể đăng nhập");

      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      _navigateAfterLogin(user);
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // LOGIN WITH GOOGLE (UPDATED)
  // ===============================
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final userModel = await _repo.loginWithGoogle();
      if (userModel == null) {
        throw Exception("Đăng nhập Google thất bại");
      }

      if (userModel.isBlocked) {
        await logout();
        return;
      }

      _user = userModel;
      _status = AuthStatus.authenticated;
      notifyListeners();
      _navigateAfterLogin(userModel);
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // REGISTER
  // ===============================
  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.register(email, password);
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // RESET PASSWORD
  // ===============================
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // LOGOUT → BACK TO GUEST
  // ===============================
  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _status = AuthStatus.guest;
    notifyListeners();

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.pushNamedAndRemoveUntil(
        ctx,
        AppRouter.studentHome,
            (_) => false,
      );
    }
  }

  // ===============================
  // UPDATE PROFILE
  // ===============================
  Future<void> updateProfile(
      String name,
      String goal, {
        String? avatarUrl,
        String? subject,
        String? bio,
        double? price,
        String? experience,
        String? availabilityNote,
      }) async {
    if (_user == null) return;

    await _repo.updateUserProfile(
      _user!.uid,
      name,
      goal,
      avatarUrl: avatarUrl,
      subject: subject,
      bio: bio,
      price: price,
      experience: experience,
      availabilityNote: availabilityNote,
    );

    _user = _user!.copyWith(
      displayName: name,
      goal: goal,
      avatarUrl: avatarUrl ?? _user!.avatarUrl,
      subject: subject ?? _user!.subject,
      bio: bio ?? _user!.bio,
      price: price ?? _user!.price,
      experience: experience ?? _user!.experience,
      availabilityNote:
      availabilityNote ?? _user!.availabilityNote,
    );

    notifyListeners();
  }

  // ===============================
  // CHANGE PASSWORD
  // ===============================
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    _setLoading(true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null || fbUser.email == null) {
        throw Exception('Không tìm thấy tài khoản hiện tại');
      }

      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );

      await fbUser.reauthenticateWithCredential(cred);
      await fbUser.updatePassword(newPassword);
    } finally {
      _setLoading(false);
    }
  }
}
