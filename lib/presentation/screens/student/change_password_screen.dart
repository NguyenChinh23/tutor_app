import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  // Regex: ≥8 ký tự, có hoa, thường, số, ký tự đặc biệt
  final _passwordRegex =
  RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~^%]).{8,}$');

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade50,
                ),
                child:
                const Icon(Icons.lock_outline, size: 60, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cập nhật mật khẩu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 24),

              // Mật khẩu hiện tại
              TextField(
                controller: currentController,
                obscureText: _hideCurrent,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideCurrent ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () =>
                        setState(() => _hideCurrent = !_hideCurrent),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mật khẩu mới
              TextField(
                controller: newController,
                obscureText: _hideNew,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideNew ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _hideNew = !_hideNew),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu mới
              TextField(
                controller: confirmController,
                obscureText: _hideConfirm,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () =>
                        setState(() => _hideConfirm = !_hideConfirm),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gợi ý rule
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // Nút Lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    final current = currentController.text.trim();
                    final newPass = newController.text.trim();
                    final confirm = confirmController.text.trim();

                    // Validate
                    if (current.isEmpty ||
                        newPass.isEmpty ||
                        confirm.isEmpty) {
                      _showSnack('Vui lòng nhập đầy đủ thông tin');
                      return;
                    }
                    if (!_passwordRegex.hasMatch(newPass)) {
                      _showSnack(
                          'Mật khẩu mới không đủ mạnh. Vui lòng xem yêu cầu phía dưới.');
                      return;
                    }
                    if (newPass != confirm) {
                      _showSnack(
                          'Mật khẩu xác nhận không khớp với mật khẩu mới');
                      return;
                    }
                    if (newPass == current) {
                      _showSnack(
                          'Mật khẩu mới phải khác mật khẩu hiện tại');
                      return;
                    }

                    // Loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      await auth.changePassword(
                        currentPassword: current,
                        newPassword: newPass,
                      );

                      if (!mounted) return;
                      Navigator.pop(context); // close dialog
                      _showSnack('Đổi mật khẩu thành công');
                      Navigator.pop(context); // back profile
                    } on FirebaseAuthException catch (e) {
                      if (mounted) Navigator.pop(context);
                      if (e.code == 'wrong-password') {
                        _showSnack('Mật khẩu hiện tại không đúng');
                      } else if (e.code == 'provider-not-password') {
                        _showSnack(
                            'Tài khoản đăng nhập bằng Google, không thể đổi mật khẩu trong ứng dụng.');
                      } else if (e.code == 'weak-password') {
                        _showSnack(
                            'Mật khẩu mới quá yếu theo Firebase (weak-password)');
                      } else {
                        _showSnack('Lỗi đổi mật khẩu: ${e.message}');
                      }
                    } catch (e) {
                      if (mounted) Navigator.pop(context);
                      _showSnack('Không thể đổi mật khẩu: $e');
                    }
                  },
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Lưu mật khẩu mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
