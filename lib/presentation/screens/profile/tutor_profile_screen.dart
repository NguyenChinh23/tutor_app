import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/app_router.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({super.key});

  ImageProvider _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/tutor1.png');
    }

    try {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        final bytes = base64Decode(avatarUrl);
        return MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint('Avatar decode error: $e');
      return const AssetImage('assets/tutor1.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user data")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("My Profile"),   // ⭐ ĐÃ ĐỔI TÊN
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 52,
              backgroundImage: _buildAvatar(user.avatarUrl),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user.displayName ?? "Tutor",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // Email
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 12),

            // Check verified
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: user.isTutorVerified
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isTutorVerified
                    ? "✅ Verified Tutor"
                    : "⏳ Tutor pending approval",
                style: TextStyle(
                  color:
                  user.isTutorVerified ? Colors.green : Colors.orange[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),

            // Goal (nếu có)
            if (user.goal != null && user.goal!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "🎯 ${user.goal}",
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ===== EDIT PROFILE =====
            _profileTile(
              icon: Icons.edit,
              color: Colors.blueAccent,
              title: "Edit Profile",
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.editProfile,
              ),
            ),

            const SizedBox(height: 16),

            // ===== LOGOUT =====
            _profileTile(
              icon: Icons.logout,
              color: Colors.redAccent,
              title: "Logout",
              textColor: Colors.redAccent,
              onTap: () {
                context.read<AppAuthProvider>().logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required Color color,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
