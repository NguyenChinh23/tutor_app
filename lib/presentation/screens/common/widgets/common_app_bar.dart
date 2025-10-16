import 'package:flutter/material.dart';
import 'package:tutor_app/data/models/user_model.dart';

class GreetingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  const GreetingAppBar({
    super.key,
    this.user,
    this.onProfileTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 22,
                backgroundImage: (user?.avatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(user!.avatarUrl!)
                    : const AssetImage('assets/images/avatar.png')
                as ImageProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome 👋",
                      style:
                      TextStyle(fontSize: 13, color: Colors.grey[600])),
                  Text(
                    user?.displayName ?? "Student",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
