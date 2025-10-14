import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/app_router.dart';
import '../../provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutor_app/config/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(
          "Đăng ký tài khoản",
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
              // 🔹 Icon + Title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade50,
                ),
                child: const Icon(Icons.person_add_alt,
                    size: 70, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tạo tài khoản mới",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 30),

              // 📨 Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔑 Password
              TextField(
                controller: passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600]),
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔁 Confirm Password
              TextField(
                controller: confirmController,
                obscureText: _hideConfirm,
                decoration: InputDecoration(
                  labelText: "Xác nhận mật khẩu",
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hideConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600]),
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
              const SizedBox(height: 25),

              // 🔹 Nút Đăng ký
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
                    final email = emailController.text.trim();
                    final pass = passwordController.text.trim();
                    final confirm = confirmController.text.trim();

                    // Kiểm tra lỗi cơ bản
                    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
                      _showSnack("Vui lòng nhập đủ thông tin!");
                      return;
                    }
                    if (!_emailRegex.hasMatch(email)) {
                      _showSnack("Email không hợp lệ!");
                      return;
                    }
                    if (pass.length < 6) {
                      _showSnack("Mật khẩu phải có ít nhất 6 ký tự!");
                      return;
                    }
                    if (pass != confirm) {
                      _showSnack("Mật khẩu xác nhận không khớp!");
                      return;
                    }

                    try {
                      await auth.register(context, email, pass);
                      _showSnack("Đăng ký thành công 🎉");
                      Navigator.of(context).pushNamed(AppRouter.login);
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'email-already-in-use') {
                        _showSnack("Email này đã được sử dụng!");
                      } else {
                        _showSnack("Lỗi đăng ký: ${e.message}");
                      }
                    } catch (e) {
                      _showSnack("Đăng ký thất bại: $e");
                    }
                  },
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Đăng ký",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Đã có tài khoản? Đăng nhập",
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}