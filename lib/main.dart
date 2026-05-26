import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'ui/app_startup_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tmudxkcovejdrweucpjl.supabase.co',
    anonKey: 'sb_publishable_cG85tYuK5oYYN-0ZxUqiMg_wlCvJvKO',
  );

  // Inisialisasi locale Indonesia untuk DateFormat
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id_ID';

  // Clear Supabase Auth session (kita pakai custom auth handler, bukan Supabase Auth)
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (e) {
    debugPrint('Supabase signOut error on startup: $e');
  }

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
      // AppStartupRouter menentukan ke mana user diarahkan:
      // - Pertama kali buka → Onboarding
      // - Sudah onboarding, ada session → HomeScreen
      // - Sudah onboarding, tidak ada session → LoginScreen
      home: const AppStartupRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
