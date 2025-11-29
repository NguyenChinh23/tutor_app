import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';

// Tab 0: Dashboard (UI phức tạp xử lý file khác)
import 'package:tutor_app/presentation/screens/tutor/tutor_dashboard_screen.dart';

// Tab 1: Chat
import 'package:tutor_app/presentation/screens/chat/chat_list_screen.dart';

// Tab 2: Tutor Profile (mới)
import 'package:tutor_app/presentation/screens/profile/tutor_profile_screen.dart';

class TutorHomeScreen extends StatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Chặn nếu không phải tutor
    if (user.role != 'tutor') {
      return const Scaffold(
        body: Center(
          child: Text('Chỉ tài khoản gia sư mới truy cập được màn hình này'),
        ),
      );
    }

    final List<Widget> screens = [
      const TutorDashboardScreen(),
      const ChatListScreen(),
      const TutorProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
