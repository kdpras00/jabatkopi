import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'ui/app_startup_router.dart';

import 'ui/app_startup_router.dart';

String? initError;
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Minta izin Notifikasi (Wajib untuk Android 13+ / iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Tangkap notifikasi saat aplikasi sedang dibuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification!.title ?? 'Notifikasi', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                Text(message.notification!.body ?? '', style: const TextStyle(color: Colors.black87)),
              ],
            ),
            backgroundColor: const Color(0xFFC9A96E), // caramelGold
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          ),
        );
      }
    });

    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
    Intl.defaultLocale = 'id_ID';
  } catch (e) {
    initError = "Init Error: $e";
    debugPrint(initError);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(error: initError),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? error;
  const MyApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1210), // Coffee-panel/dark theme
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    const Text(
                      'App Initialization Failed',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Jabat Kopi',
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: scaffoldMessengerKey, // <-- Pasang global key
      // AppStartupRouter menentukan ke mana user diarahkan:
      // - Pertama kali buka → Onboarding
      // - Sudah onboarding, ada session → HomeScreen
      // - Sudah onboarding, tidak ada session → LoginScreen
      home: const AppStartupRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
