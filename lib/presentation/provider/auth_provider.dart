// lib/presentation/provider/auth_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:tutor_app/data/models/user_model.dart';
import 'package:tutor_app/data/repositories/auth_repository.dart';
import 'package:tutor_app/config/app_router.dart';

// 🌍 Biến global Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppAuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get isLoading => _loading;

  bool _justRegistered = false; // tránh redirect sau khi đăng ký

  StreamSubscription? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // 🔹 Lắng nghe trạng thái đăng nhập Firebase + user Firestore
  void bootstrap() {
    // tránh subscribe nhiều lần
    _authSub?.cancel();

    _authSub = _repo.authChanges.listen((fbUser) {
      // mỗi lần user auth thay đổi -> hủy stream cũ
      _userSub?.cancel();

      if (fbUser == null) {
        _user = null;
        notifyListeners();
        return;
      }

      // 🔹 Lắng nghe thông tin user realtime từ Firestore
      _userSub = _repo.userDocStream(fbUser.uid).listen((u) {
        _user = u;
        notifyListeners();

        if (u != null && !_justRegistered) {
          _navigateAfterLogin(u);
        }
      }, onError: (e) {
        debugPrint("userDocStream error: $e");
      });
    }, onError: (e) {
      debugPrint("authChanges error: $e");
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  // 🔹 Điều hướng theo vai trò
  void _navigateAfterLogin(UserModel u) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      final role = u.role.trim().toLowerCase();

      debugPrint(
        '🔐 NAVIGATE: uid=${u.uid}, email=${u.email}, role=$role, isTutorVerified=${u.isTutorVerified}',
      );

      if (role == 'admin') {
        Navigator.pushNamedAndRemoveUntil(
          ctx,
          AppRouter.admin,
              (route) => false,
        );
      } else if (role == 'tutor') {
        if (u.isTutorVerified == true) {
          Navigator.pushNamedAndRemoveUntil(
            ctx,
            AppRouter.tutorHome,
                (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            ctx,
            AppRouter.studentHome,
                (route) => false,
          );
        }
      } else {
        Navigator.pushNamedAndRemoveUntil(
          ctx,
          AppRouter.studentHome,
              (route) => false,
        );
      }
    });
  }

  // 🔹 Đăng nhập Email & Password
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.login(email, password);
      if (user == null) {
        throw Exception("Không thể đăng nhập");
      }
      _user = user;
      notifyListeners();
      // điều hướng vẫn do bootstrap() xử lý
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow; // để UI tự xử lý lỗi và show SnackBar
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Đăng nhập bằng Google (giữ nguyên, vẫn dùng context để SnackBar)
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final user = await _repo.loginWithGoogle();
      if (user == null) throw Exception("Đăng nhập Google thất bại");

      _user = user;
      notifyListeners();
      // Điều hướng vẫn do bootstrap xử lý
    } catch (e) {
      debugPrint("Google login error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi đăng nhập Google: $e')));
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Đăng ký tài khoản → không tự SnackBar, không tự điều hướng
  Future<void> register(String email, String password) async {
    _setLoading(true);
    _justRegistered = true;
    try {
      final user = await _repo.register(email, password);
      _user = user;
      notifyListeners();

      // Đăng xuất ngay sau khi tạo tài khoản để quay lại màn login
      await _repo.logout();
      _user = null;
    } catch (e) {
      debugPrint("Register error: $e");
      rethrow; // UI sẽ bắt để show message đẹp
    } finally {
      _setLoading(false);
      _justRegistered = false;
    }
  }

  // 🔹 Đăng xuất
  Future<void> logout() async {
    _user = null;
    notifyListeners();

    try {
      await _repo.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // 🔹 Quên mật khẩu
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Cập nhật hồ sơ
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
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }
}
