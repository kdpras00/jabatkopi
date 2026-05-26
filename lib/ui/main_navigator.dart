import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/utils/session_manager.dart';
import 'login_screen.dart';
import 'screens/customer/home_screen.dart';

/// Widget reaktif yang mendengarkan [AuthProvider].
/// Digunakan sebagai home setelah onboarding selesai dan user belum/sudah login.
/// - Jika [isAuthenticated] = true  → CustomerHomeScreen (terbungkus SessionManager)
/// - Jika [isAuthenticated] = false → LoginScreen
class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Customer authenticated — bungkus dengan SessionManager agar
    // otomatis logout setelah inaktif 10 menit
    return const SessionManager(
      timeout: Duration(minutes: 10),
      child: CustomerHomeScreen(),
    );
  }
}
