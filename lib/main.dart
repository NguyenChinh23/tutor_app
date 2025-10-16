import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'firebase_options.dart';
import 'config/app_router.dart';
import 'config/theme.dart';
import 'presentation/provider/auth_provider.dart';
import 'presentation/provider/admin_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TutorApp());
}

class TutorApp extends StatelessWidget {
  const TutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_)=> TutorProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tutor Finder',
        navigatorKey: navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
