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

  bool _justRegistered = false; // tránh redirect sau khi đăng ký

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // 🔹 Lắng nghe trạng thái đăng nhập Firebase
  void bootstrap() {
    _repo.authChanges.listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
        notifyListeners();
        return;
      }

      try {
        if (fbUser.uid == "eYngCmflUZQ2p2k9XfvctEvyOWP2") {
          _adminUid ??= await _config.fetchAdminUid();
        }

        // 🔹 Lắng nghe thông tin user realtime
        _repo.userDocStream(fbUser.uid).listen((u) {
          _user = u;
          notifyListeners();

          //  Chỉ điều hướng khi login, không khi register
          if (u != null && !_justRegistered) {
            _navigateAfterLogin(u);
          }
        });
      } catch (e) {
        debugPrint("Bootstrap error: $e");
      }
    });
  }

  // 🔹 Điều hướng theo vai trò
  void _navigateAfterLogin(UserModel u) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      if (u.role == 'admin' || u.uid == "eYngCmflUZQ2p2k9XfvctEvyOWP2") {
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

  // 🔹 Đăng nhập Email & Password
  Future<void> login(
      BuildContext context,
      String email,
      String password,
      ) async {
    _setLoading(true);
    try {
      final user = await _repo.login(email, password);
      if (user == null) throw Exception("Không thể đăng nhập");
      _user = user;
      notifyListeners();
      _navigateAfterLogin(user);
    } catch (e) {
      debugPrint("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: $e')),
      );
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Đăng nhập bằng Google
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

  // 🔹 Đăng ký tài khoản → quay lại login
  Future<void> register(
      BuildContext context,
      String email,
      String password,
      ) async {
    _setLoading(true);
    _justRegistered = true;
    try {
      final user = await _repo.register(email, password);
      _user = user;
      notifyListeners();

      //  Đăng xuất ngay để tránh auto-login
      await _repo.logout();
      _user = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng ký thành công 🎉 Vui lòng đăng nhập!"),
        ),
      );

      Navigator.pushReplacementNamed(context, AppRouter.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng ký: $e")),
      );
    } finally {
      _setLoading(false);
      _justRegistered = false;
    }
  }

  // 🔹 Đăng xuất – ưu tiên UI nhanh
  Future<void> logout() async {
    // 1. Xoá user cục bộ trước → UI chuyển màn hình ngay
    _user = null;
    notifyListeners();

    // 2. Gọi Firebase signOut phía sau
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
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Cập nhật hồ sơ (student + tutor)
  Future<void> updateProfile(
      String name,
      String goal, {
        String? avatarUrl,

        // field cho tutor – student bỏ trống
        String? subject,
        String? bio,
        double? price,
        String? experience,
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
      );

      // UserModel hiện chỉ lưu name/avatar/goal
      _user = _user!.copyWith(
        displayName: name,
        goal: goal,
        avatarUrl: avatarUrl ?? _user!.avatarUrl,
      );

      notifyListeners();
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }
}

// 🌍 Biến global Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
