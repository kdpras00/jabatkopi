import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const bool granted = true;
      return granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> showReservationNotification(String bookingId, String dateTime, int tableId, int guests) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jabatkopi_reservations',
      'Reservasi Jabat Kopi',
      channelDescription: 'Notifikasi konfirmasi dan pengingat reservasi meja',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      bookingId.hashCode,
      'Reservasi Berhasil Dikonfirmasi! 🎉',
      'Kode: $bookingId | Meja $tableId | $guests Orang\nJadwal: $dateTime',
      notificationDetails,
      payload: bookingId,
    );
  }
}
