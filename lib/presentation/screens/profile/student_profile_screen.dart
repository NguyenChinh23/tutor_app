import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/app_router.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'package:tutor_app/data/models/tutor_model.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  ImageProvider _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/tutor1.png');
    }

    try {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        // base64
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

    final isTutor = user.role == 'tutor';
    TutorModel? tutor;

    if (isTutor) {
      final tutorProvider = context.watch<TutorProvider>();
      try {
        tutor = tutorProvider.tutors.firstWhere((t) => t.uid == user.uid);
      } catch (_) {
        tutor = null;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👤 Avatar + Info
            CircleAvatar(
              radius: 52,
              backgroundImage: _buildAvatar(user.avatarUrl),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ??
                  (isTutor ? (tutor?.name ?? "Tutor") : "Student"),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Role: ${user.role}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 12),

            // 🎯 Student goal
            if (user.role == 'student') ...[
              if (user.goal != null && user.goal!.isNotEmpty)
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

            // 👨‍🏫 Tutor info từ TutorModel nếu user = tutor
            if (isTutor && tutor != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (tutor!.subject.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.menu_book,
                          size: 18, color: Colors.indigo),
                      label: Text(
                        tutor!.subject,
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.indigo.shade50,
                    ),
                  Chip(
                    avatar: const Icon(Icons.payment,
                        size: 18, color: Colors.green),
                    label: Text(
                      "${tutor!.price.toStringAsFixed(0)} đ/buổi",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.green.shade50,
                  ),
                  Chip(
                    avatar: const Icon(Icons.star,
                        size: 18, color: Colors.amber),
                    label: Text(
                      tutor!.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.amber.shade50,
                  ),
                  if (tutor!.isTutorVerified)
                    Chip(
                      avatar: const Icon(Icons.verified,
                          size: 18, color: Colors.blueAccent),
                      label: const Text(
                        'Verified tutor',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade50,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // 🔹 Edit Profile (dùng chung)
            _profileTile(
              icon: Icons.edit,
              color: Colors.blueAccent,
              title: "Edit Profile",
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.editProfile,
              ),
            ),

            // 🎓 Apply Tutor (chỉ student mới thấy)
            if (user.role == 'student')
              _profileTile(
                icon: Icons.school_outlined,
                color: Colors.deepPurple,
                title: "Apply to Become a Tutor",
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.applyTutor,
                ),
              ),

            const SizedBox(height: 16),

            // 🚪 Logout
            _profileTile(
              icon: Icons.logout,
              color: Colors.redAccent,
              title: "Logout",
              textColor: Colors.redAccent,
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.login,
                        (route) => false,
                  );
                }
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
