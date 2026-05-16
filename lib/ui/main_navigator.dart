import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import 'login_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    switch (authProvider.role) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'pegawai':
        return const StaffDashboardScreen();
      case 'customer':
      default:
        return const CustomerHomeScreen();
    }
  }
}
