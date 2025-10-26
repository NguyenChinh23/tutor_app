import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
          "Quên mật khẩu",
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
              // 🔹 Icon tiêu đề
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade50,
                ),
                child: const Icon(Icons.lock_reset,
                    size: 60, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              const Text(
                "Đặt lại mật khẩu",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 30),

              // 🔸 Email input
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email của bạn",
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 🔹 Nút Gửi yêu cầu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    final email = emailController.text.trim();

                    //  Kiểm tra đầu vào
                    if (email.isEmpty || !email.contains('@')) {
                      _showSnack("Vui lòng nhập email hợp lệ!");
                      return;
                    }

                    // 🌀 Loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await auth.resetPassword(email);

                      if (context.mounted) {
                        Navigator.pop(context); // Đóng loading
                        _showSnack("Đã gửi email đặt lại mật khẩu");
                        Navigator.pop(context); // Quay lại màn login
                      }
                    } on FirebaseAuthException catch (e) {
                      Navigator.pop(context); // Đóng loading

                      if (e.code == 'user-not-found') {
                        _showSnack(
                            "Không tìm thấy tài khoản với email này!");
                      } else if (e.code == 'invalid-email') {
                        _showSnack("Email không hợp lệ!");
                      } else if (e.code == 'google-account') {
                        _showSnack(
                            "Tài khoản này đăng nhập bằng Google, không cần đặt lại mật khẩu.");
                      } else {
                        _showSnack("Lỗi Firebase: ${e.message}");
                      }
                    } catch (e) {
                      Navigator.pop(context); // Đóng loading
                      _showSnack("Không thể gửi email: $e");
                    }
                  },
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Gửi yêu cầu",
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