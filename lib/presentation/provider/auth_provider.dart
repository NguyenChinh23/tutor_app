import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/data/models/user_model.dart';
import 'package:tutor_app/data/repositories/auth_repository.dart';
import 'package:tutor_app/config/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppAuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get isLoading => _loading;

  StreamSubscription? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // init auth listener
  void bootstrap() {
    _authSub?.cancel();
    _authSub = _repo.authChanges.listen((fbUser) {
      _userSub?.cancel();
      if (fbUser == null) {
        _user = null;
        notifyListeners();
        _navigateToLogin();
        return;
      }

      _userSub = _repo.userDocStream(fbUser.uid).listen((u) async {
        _user = u;
        notifyListeners();
        if (u == null) return;

        final ctx = navigatorKey.currentContext;
        if (ctx == null) return;
        final currentRoute =
            ModalRoute.of(ctx)?.settings.name ?? AppRouter.splash;

        if (u.isBlocked) {
          await _handleBlockedUser();
        } else if (currentRoute == AppRouter.login ||
            currentRoute == AppRouter.splash) {
          _navigateAfterLogin(u);
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  // navigation helper
  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      if (!Navigator.of(ctx).mounted) return;
      final currentRoute = ModalRoute.of(ctx)?.settings.name;
      if (currentRoute == AppRouter.login) return;
      _safeNavigate(ctx, AppRouter.login);
    });
  }

  void _navigateAfterLogin(UserModel u) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      if (!Navigator.of(ctx).mounted) return;
      final role = u.role.trim().toLowerCase();
      final target = (role == 'tutor' && u.isTutorVerified)
          ? AppRouter.tutorHome
          : AppRouter.studentHome;
      final currentRoute = ModalRoute.of(ctx)?.settings.name;
      if (currentRoute == target) return;
      _safeNavigate(ctx, target);
    });
  }

  void _safeNavigate(BuildContext ctx, String route) {
    try {
      if (!Navigator.of(ctx).canPop()) {
        Navigator.pushReplacementNamed(ctx, route);
      } else {
        Navigator.pushNamedAndRemoveUntil(ctx, route, (_) => false);
      }
    } catch (e) {
      debugPrint("Navigator error: $e");
    }
  }

  // handle blocked account
  Future<void> _handleBlockedUser() async {
    if (_loading) return;
    _setLoading(true);
    await _repo.logout();
    _setLoading(false);
    _navigateToLogin();
  }

  // login
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.login(email, password);
      if (user == null) throw Exception("Không thể đăng nhập");
      if (user.isBlocked) {
        await _handleBlockedUser();
      } else {
        _user = user;
        notifyListeners();
        _navigateAfterLogin(user);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // login with google
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final userModel = await _repo.loginWithGoogle();
      if (userModel == null) throw Exception("Đăng nhập Google thất bại");
      if (userModel.isBlocked == true) {
        await _repo.logout();
        _user = null;
        notifyListeners();
        return;
      }
      _user = userModel;
      notifyListeners();
      _navigateAfterLogin(userModel);
    } catch (e) {
      debugPrint("Google login error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // register
  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.register(email, password);
      debugPrint("Register success");
    } catch (e) {
      debugPrint("Register error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
      debugPrint("Reset email sent");
    } catch (e) {
      debugPrint("Reset error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // logout
  Future<void> logout() async {
    try {
      await _repo.logout();
      _navigateToLogin();
    } catch (e) {
      debugPrint("Logout error: $e");
      rethrow;
    }
  }

  // update profile
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
    try {
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
        availabilityNote: availabilityNote ?? _user!.availabilityNote,
      );

      notifyListeners();
      debugPrint("Profile updated");
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }

  // change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) throw Exception('Bạn chưa đăng nhập');
    _setLoading(true);
    try {
      final fb = FirebaseAuth.instance;
      final fbUser = fb.currentUser;
      if (fbUser == null || fbUser.email == null) {
        throw Exception('Không tìm thấy tài khoản hiện tại');
      }

      final isPasswordProvider =
      fbUser.providerData.any((p) => p.providerId == 'password');
      if (!isPasswordProvider) {
        throw FirebaseAuthException(
          code: 'provider-not-password',
          message: 'Không thể đổi mật khẩu tài khoản Google.',
        );
      }

      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(cred);
      await fbUser.updatePassword(newPassword);
      debugPrint("Password changed");
    } catch (e) {
      debugPrint("Change password error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
