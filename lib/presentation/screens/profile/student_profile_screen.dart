import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/app_router.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: user == null
          ? const Center(child: Text("No user data"))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👤 Avatar + Info
            CircleAvatar(
              radius: 52,
              backgroundImage: (user.avatarUrl != null &&
                  user.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : const AssetImage('assets/tutor1.png')
              as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? "Student",
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
            const SizedBox(height: 12),

            if (user.goal != null && user.goal!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
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

            const SizedBox(height: 32),

            // 🔹 Edit Profile
            _profileTile(
              icon: Icons.edit,
              color: Colors.blueAccent,
              title: "Edit Profile",
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.editProfile,
              ),
            ),

            // 🎓 Apply Tutor
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
