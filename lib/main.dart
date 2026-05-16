import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'ui/main_navigator.dart';
import 'ui/screens/splash_screen.dart';
import 'core/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://tmudxkcovejdrweucpjl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtdWR4a2NvdmVqZHJ3ZXVjcGpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTE0NjgsImV4cCI6MjA5NDAyNzQ2OH0._9istl2Z74htepKfclwE4zdCqzzk0G4eUGO9anhcrr8',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jabat Kopi',
      theme: AppTheme.darkTheme,
      home: const SessionManager(
        timeout: Duration(minutes: 10), // Set ke 10 menit inactivity
        child: SplashScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
