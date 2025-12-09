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

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // Bootstrap listener
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
        final current = ModalRoute.of(ctx)?.settings.name ?? AppRouter.splash;
        if (u.isBlocked) await _handleBlockedUser();
        else if (current == AppRouter.login || current == AppRouter.splash) _navigateAfterLogin(u);
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  void _safeNavigate(BuildContext ctx, String route) {
    try {
      Navigator.pushNamedAndRemoveUntil(ctx, route, (_) => false);
    } catch (_) {}
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      final current = ModalRoute.of(ctx)?.settings.name;
      if (current == AppRouter.login) return;
      _safeNavigate(ctx, AppRouter.login);
    });
  }

  void _navigateAfterLogin(UserModel u) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      final role = u.role.trim().toLowerCase();
      final target = (role == 'tutor' && u.isTutorVerified)
          ? AppRouter.tutorHome
          : AppRouter.studentHome;
      final current = ModalRoute.of(ctx)?.settings.name;
      if (current != target) _safeNavigate(ctx, target);
    });
  }

  Future<void> _handleBlockedUser() async {
    if (_loading) return;
    _setLoading(true);
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text('❌ Tài khoản của bạn đã bị khóa.'),
      ));
    }
    await _repo.logout();
    _setLoading(false);
    _navigateToLogin();
  }

  // Login email
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final fb = FirebaseAuth.instance;
      if (fb.currentUser != null) await fb.signOut();
      final user = await _repo.login(email, password);
      if (user == null) throw Exception("Không thể đăng nhập");
      if (user.isBlocked) await _handleBlockedUser();
      else {
        _user = user;
        notifyListeners();
        _navigateAfterLogin(user);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') _showError('Tài khoản không tồn tại.');
      else if (e.code == 'wrong-password' || e.code == 'invalid-credential')
        _showError('Tài khoản hoặc mật khẩu không đúng.');
      else if (e.code == 'too-many-requests')
        _showError('Đăng nhập thất bại nhiều lần, thử lại sau.');
      else _showError('Lỗi đăng nhập: ${e.message}');
    } catch (e) {
      _showError('Đăng nhập thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Login Google
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final u = await _repo.loginWithGoogle();
      if (u == null) throw Exception("Đăng nhập Google thất bại");
      if (u.isBlocked) {
        await _repo.logout();
        _user = null;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('❌ Tài khoản của bạn đã bị khóa.'),
        ));
        return;
      }
      _user = u;
      notifyListeners();
      _navigateAfterLogin(u);
    } catch (e) {
      _showError('Lỗi đăng nhập Google: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.register(email, password);
      _showSuccess('Đăng ký thành công! Vui lòng đăng nhập.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use')
        _showError('Email này đã được sử dụng.');
      else if (e.code == 'invalid-email')
        _showError('Email không hợp lệ.');
      else
        _showError('Lỗi đăng ký: ${e.message}');
    } catch (e) {
      _showError('Lỗi đăng ký: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
      _showSuccess('Email khôi phục mật khẩu đã được gửi.');
    } catch (e) {
      _showError('Lỗi gửi email khôi phục: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _repo.logout();
      _navigateToLogin();
    } catch (e) {
      _showError('Lỗi khi đăng xuất: $e');
    }
  }

  // Update profile
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
      await _userSub?.cancel();
      _userSub = null;
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
      _userSub = _repo.userDocStream(_user!.uid).listen((u) {
        _user = u;
        notifyListeners();
      });
      _showSuccess('Cập nhật hồ sơ thành công.');
    } catch (e) {
      _showError('Lỗi khi cập nhật hồ sơ: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) throw Exception('Bạn chưa đăng nhập');
    _setLoading(true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null || fbUser.email == null)
        throw Exception('Không tìm thấy tài khoản');
      final isPassword =
      fbUser.providerData.any((p) => p.providerId == 'password');
      if (!isPassword) {
        throw FirebaseAuthException(
          code: 'provider-not-password',
          message: 'Không thể đổi mật khẩu cho tài khoản Google.',
        );
      }
      final cred = EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(cred);
      await fbUser.updatePassword(newPassword);
      _showSuccess('Đổi mật khẩu thành công.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password')
        _showError('Mật khẩu hiện tại không chính xác.');
      else
        _showError('Lỗi Firebase: ${e.message}');
    } catch (e) {
      _showError('Lỗi khi đổi mật khẩu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Snackbar
  void _showError(String msg) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(msg, textAlign: TextAlign.center),
    ));
  }

  void _showSuccess(String msg) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(msg, textAlign: TextAlign.center),
    ));
  }
}
