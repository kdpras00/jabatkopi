import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import 'login_screen.dart';
import 'screens/customer/home_screen.dart';

/// Widget reaktif yang mendengarkan [AuthProvider].
/// Digunakan sebagai home setelah onboarding selesai dan user belum/sudah login.
/// - Jika [isAuthenticated] = true  → CustomerHomeScreen
/// - Jika [isAuthenticated] = false → LoginScreen
///
/// NOTE: Auto-logout karena inaktif (SessionManager) sengaja dihapus.
/// Logout hanya terjadi saat user menekan tombol logout secara eksplisit,
/// atau ketika server mengembalikan 401 (token tidak valid).
class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    return const CustomerHomeScreen();
  }
}
