import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/config_repository.dart';
import 'package:tutor_app/config/app_router.dart';

class AppAuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  final _config = ConfigRepository();

  UserModel? _user;
  UserModel? get user => _user;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _adminUid;
  String? get adminUid => _adminUid;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  //  Khởi động: lắng nghe trạng thái đăng nhập + user Firestore realtime
  void bootstrap() {
    _repo.authChanges.listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
        notifyListeners();
        return;
      }

      try {
        //Nếu là admin → lấy config
        if (fbUser.uid == "eYngCmflUZQ2p2k9XfvctEvyOWP2") {
          _adminUid ??= await _config.fetchAdminUid();
        }

        //  Lắng nghe user realtime trong Firestore
        _repo.userDocStream(fbUser.uid).listen((u) {
          _user = u;
          notifyListeners();

          if (u != null) {
            _navigateAfterLogin(u);
          }
        });
      } catch (e) {
        debugPrint("Bootstrap error: $e");
      }
    });
  }

  //  Điều hướng theo vai trò
  void _navigateAfterLogin(UserModel u) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      if (u.uid == "eYngCmflUZQ2p2k9XfvctEvyOWP2" || u.role == 'admin') {
        Navigator.pushReplacementNamed(ctx, AppRouter.admin);
      } else if (u.role == 'tutor') {
        if (u.isTutorVerified == true) {
          Navigator.pushReplacementNamed(ctx, AppRouter.tutorHome);
        } else {
          Navigator.pushReplacementNamed(ctx, AppRouter.studentHome);
        }
      } else {
        Navigator.pushReplacementNamed(ctx, AppRouter.studentHome);
      }
    });
  }

  //  Đăng nhập Email & Password
  Future<void> login(BuildContext context, String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.login(email, password);
      if (user == null) throw Exception("Không thể đăng nhập");

      _user = user;
      notifyListeners();

      if (user.uid == "eYngCmflUZQ2p2k9XfvctEvyOWP2") {
        Navigator.pushReplacementNamed(context, AppRouter.admin);
        return;
      }

      if (user.role == 'tutor') {
        if (user.isTutorVerified == true) {
          Navigator.pushReplacementNamed(context, AppRouter.tutorHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.studentHome);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.studentHome);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: $e')),
      );
    } finally {
      _setLoading(false);
    }
  }

  //  Đăng nhập Google
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      final user = await _repo.loginWithGoogle();
      if (user == null) throw Exception("Đăng nhập Google thất bại");

      _user = user;
      notifyListeners();
      _navigateAfterLogin(user);
    } catch (e) {
      debugPrint("Google login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
      );
    } finally {
      _setLoading(false);
    }
  }

  //  Đăng ký tài khoản → quay lại login
  Future<void> register(BuildContext context, String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.register(email, password);
      _user = user;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công 🎉 Vui lòng đăng nhập!")),
      );

      Navigator.pushReplacementNamed(context, AppRouter.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng ký: $e")),
      );
    } finally {
      _setLoading(false);
    }
  }

  //  Quên mật khẩu
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
    } catch (e) {
      debugPrint("Reset password error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  //  Đăng xuất
  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }

  // cập nhật hồ sơ người dùng
  Future<void> updateProfile(String name, String goal) async {
    if (_user == null) return;
    try {
      await _repo.updateUserProfile(_user!.uid, name, goal);
      _user = _user!.copyWith(displayName: name, goal: goal);
      notifyListeners();
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }
}

// Biến global cho điều hướng (Navigator)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
