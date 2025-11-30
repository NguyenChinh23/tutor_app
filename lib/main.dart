import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'config/app_router.dart';
import 'config/theme.dart';

import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/admin_provider.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'package:tutor_app/presentation/provider/booking_provider.dart';
import 'package:tutor_app/presentation/provider/notification_provider.dart';

import 'package:tutor_app/data/repositories/booking_repository.dart';
import 'package:tutor_app/data/services/notification_service.dart';
import 'package:tutor_app/data/repositories/notification_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TutorApp());
}

class TutorApp extends StatelessWidget {
  const TutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider()..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TutorProvider(),
        ),

        /// 🔹 BookingProvider KHÔNG dùng BookingService nữa
        ChangeNotifierProvider(
          create: (_) => BookingProvider(
            repository: BookingRepository(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            repository: NotificationRepository(
              NotificationService(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tutor Finder',
        navigatorKey: navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
        theme: AppTheme.lightTheme,

        // 🔥 THÊM PHẦN NÀY ĐỂ FIX showDatePicker / showTimePicker
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
