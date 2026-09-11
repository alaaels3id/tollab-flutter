import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  try {
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
  }

  // Initialize Firebase Cloud Messaging
  try {
    await FirebaseMessagingService.instance.initialize();
  } catch (e) {
    debugPrint('Error initializing Firebase Messaging: $e');
  }

  runApp(
    const ProviderScope(
      child: TollabApp(),
    ),
  );
}

class TollabApp extends StatelessWidget {
  const TollabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'طُلاّب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
