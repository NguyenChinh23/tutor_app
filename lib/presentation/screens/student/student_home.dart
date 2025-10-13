import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import 'package:tutor_app/config/app_router.dart';


class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AppAuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Xin chào, ${user?.email ?? 'User'}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.school),
            label: const Text('Trở thành Gia sư'),
            onPressed: () => Navigator.pushNamed(context, AppRouter.applyTutor),
          ),
        ]),
      ),
    );
  }
}
