import 'package:flutter/material.dart';
import 'package:tutor_app/presentation/screens/auth/login_page.dart';
import 'package:tutor_app/presentation/screens/auth/register_page.dart';
import 'package:tutor_app/presentation/screens/auth/reset_password_screen.dart';
import 'package:tutor_app/presentation/screens/common/splash_screen.dart';
import 'package:tutor_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:tutor_app/presentation/screens/student/student_home.dart' hide TutorHomeScreen;
import 'package:tutor_app/presentation/screens/tutor/tutor_home.dart';
import 'package:tutor_app/presentation/screens/profile/apply_tutor_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';
  static const String studentHome = '/student-home';
  static const String tutorHome = '/tutor-home';
  static const String applyTutor = '/apply-tutor';
  static const String admin = '/admin';
  static const String editProfile = '/edit-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case studentHome:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case tutorHome:
        return MaterialPageRoute(builder: (_) => const TutorHomeScreen());
      case applyTutor:
        return MaterialPageRoute(builder: (_) => const ApplyTutorScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text(' Route không tồn tại')),
          ),
        );
    }
  }
}
