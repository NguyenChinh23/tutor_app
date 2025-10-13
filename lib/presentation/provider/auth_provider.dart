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

  // ✅ Lắng nghe trạng thái đăng nhập Firebase
  void bootstrap() {
    _repo.authChanges.listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
        notifyListeners();
        return;
      }

      try {
        _adminUid ??= await _config.fetchAdminUid();

        // 🔁 Lắng nghe dữ liệu user Firestore realtime
        _repo.userDocStream(fbUser.uid).listen((u) {
          _user = u;
          notifyListeners();
        });
      } catch (e) {
        debugPrint("Bootstrap error: $e");
      }
    });
  }

  // ✅ Đăng nhập bằng Email + Password
  Future<void> login(BuildContext context, String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.login(email, password);
      _user = user;
      notifyListeners();

      if (user != null) {
        //  Lấy admin UID từ Firestore (nếu chưa có)
        _adminUid ??= await _config.fetchAdminUid();

        //  Nếu trùng UID admin → điều hướng admin
        if (user.uid == _adminUid) {
          Navigator.pushReplacementNamed(context, AppRouter.admin);
          return;
        }

        //  Nếu không → điều hướng theo role
        if (user.role == 'student') {
          Navigator.pushReplacementNamed(context, AppRouter.studentHome);
        } else if (user.role == 'tutor') {
          Navigator.pushReplacementNamed(context, AppRouter.tutorHome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không xác định được vai trò người dùng')),
          );
        }
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
      _user = user;
      notifyListeners();

      if (user != null) {
        if (user.role == 'student') {
          Navigator.pushReplacementNamed(context, AppRouter.studentHome);
        } else if (user.role == 'tutor') {
          Navigator.pushReplacementNamed(context, AppRouter.tutorHome);
        } else if (user.role == 'admin') {
          Navigator.pushReplacementNamed(context, AppRouter.admin);
        }
      }
    } catch (e) {
      debugPrint("Google login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
      );
    } finally {
      _setLoading(false);
    }
  }

  //  Đăng ký tài khoản
  Future<void> register(BuildContext context, String email, String password) async {
    _setLoading(true);
    try {
      final user = await _repo.register(email, password);
      _user = user;
      notifyListeners();

      // Sau khi đăng ký → chuyển đến StudentHome
      Navigator.pushReplacementNamed(context, AppRouter.studentHome);
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

  // 11 Đăng xuất
  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }
}
