import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'ui/app_startup_router.dart';
import 'core/utils/notification_service.dart';

String? initError;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
    Intl.defaultLocale = 'id_ID';

    // Initialize Notification Service
    try {
      // ponytail: deferred notification service init
      // await NotificationService().initialize();
    } catch (e) {
      debugPrint("FCM Init error: $e");
    }
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
      // AppStartupRouter menentukan ke mana user diarahkan:
      // - Pertama kali buka → Onboarding
      // - Sudah onboarding, ada session → HomeScreen
      // - Sudah onboarding, tidak ada session → LoginScreen
      home: const AppStartupRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
