import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'presentation/provider/auth_provider.dart';
import 'config/app_router.dart';
import 'package:tutor_app/presentation/screens/common/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TutorApp());
}

class TutorApp extends StatelessWidget {
  const TutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppAuthProvider()..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tutor Finder',
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      ),
    );
  }
}