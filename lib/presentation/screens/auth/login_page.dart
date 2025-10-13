import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/presentation/screens/auth/register_page.dart';
import '../../../config/app_router.dart';
import '../../provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutor_app/presentation/screens/auth/login_page.dart';
import 'package:tutor_app/presentation/screens/auth/reset_password_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscure = true;

  // Regex kiểm tra định dạng email
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 Logo + Tiêu đề
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade50,
                ),
                child: const Icon(Icons.school, size: 80, color: Colors.indigo),
              ),
              const SizedBox(height: 18),
              const Text(
                "Tutor Finder",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 40),

              // 🔸 Email
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

              // 🔸 Password
              TextField(
                controller: passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.resetPassword),
                  child: const Text(
                    "Quên mật khẩu?",
                    style: TextStyle(color: Colors.indigo),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Nút Đăng nhập
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    final email = emailController.text.trim();
                    final pass = passwordController.text.trim();

                    // 🧠 Kiểm tra đầu vào
                    if (email.isEmpty || pass.isEmpty) {
                      _showSnack("Vui lòng nhập đầy đủ thông tin!");
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

                    try {
                      // 🧹 Clear session cũ để tránh lỗi token sau khi đổi mật khẩu
                      await FirebaseAuth.instance.signOut();

                      // 🧩 Thực hiện đăng nhập thật
                      await auth.login(context, email, pass);
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'wrong-password') {
                        _showSnack("Sai mật khẩu! Vui lòng thử lại.");
                      } else if (e.code == 'user-not-found') {
                        _showSnack("Tài khoản không tồn tại!");
                      } else if (e.code == 'invalid-credential') {
                        _showSnack(
                            "Thông tin đăng nhập không hợp lệ! (Có thể mật khẩu vừa được đổi)");
                      } else if (e.code == 'too-many-requests') {
                        _showSnack(
                            "Đăng nhập quá nhiều lần. Vui lòng thử lại sau!");
                      } else {
                        _showSnack("Lỗi: ${e.message}");
                      }
                    } catch (e) {
                      _showSnack("Đăng nhập thất bại: $e");
                    }
                  },
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Đăng nhập",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const Text("hoặc", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 22),

              // 🔹 Nút Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    try {
                      await auth.loginWithGoogle(context);
                      _showSnack("Đăng nhập Google thành công ✅");
                    } catch (e) {
                      _showSnack("Lỗi: $e");
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/gglogo.png', height: 26, width: 26),
                      const SizedBox(width: 10),
                      const Text(
                        "Đăng nhập bằng Google",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRouter.signup),
                    child: const Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}