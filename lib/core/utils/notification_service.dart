import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as flutter_secure_storage;
import '../config/app_config.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Only init if firebase is supported and we're not running in environments where it crashes without config
    try {
      await Firebase.initializeApp();
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
          
      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Create high importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'jabatkopi_alerts', // id
        'Jabat Kopi Alerts', // title
        description: 'Pemberitahuan penting seperti pesanan siap.', // description
        importance: Importance.max,
        playSound: true,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.instance.getToken().then((token) {
        debugPrint("FCM Token: $token");
        if (token != null) {
          syncTokenToBackend(token);
        }
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        syncTokenToBackend(token);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });
      
    } catch (e) {
      debugPrint("Failed to initialize Firebase: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jabatkopi_alerts',
      'Jabat Kopi Alerts',
      channelDescription: 'Pemberitahuan penting seperti pesanan siap.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> syncTokenToBackend(String fcmToken) async {
    try {
      const storage = flutter_secure_storage.FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      final userId = await storage.read(key: 'user_id');
      
      if (token == null || userId == null) return;

      await http.put(
        Uri.parse('${AppConfig.laravelBaseUrl}/api/profile/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );
    } catch (e) {
      debugPrint("Failed to sync FCM token: $e");
    }
  }
}
