import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/presentation/screens/auth/login_page.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/config/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Chào mừng bạn đã đăng nhập!'),
      ),
    );
  }
}
