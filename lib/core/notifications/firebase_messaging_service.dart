import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  } else {
    await Firebase.initializeApp();
  }
  debugPrint('Handling a background message: ${message.messageId}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._internal();
  FirebaseMessagingService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request notification permission for iOS
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // Enable foreground notification presentation on Apple devices
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground: ${message.messageId}');
        final notification = message.notification;
        if (notification != null) {
          NotificationService.instance.showNotification(
            id: notification.hashCode,
            title: notification.title ?? 'تنبيه من طُلاّب',
            body: notification.body ?? '',
          );
        }
      });

      // Fetch FCM token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Device Token: $_fcmToken');
      } catch (e) {
        debugPrint('Could not retrieve APNs/FCM token on simulator: $e');
      }

      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
      });
    } catch (e) {
      debugPrint('Firebase messaging initialization error: $e');
    }
  }

  Future<String?> getOrFetchToken() async {
    if (_fcmToken != null) return _fcmToken;
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting token: $e');
    }
    return _fcmToken;
  }
}
