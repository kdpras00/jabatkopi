import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class JkLogoutButton extends StatelessWidget {
  const JkLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () {
        // 1. Bersihkan status di AuthProvider
        context.read<AuthProvider>().logout();
        
        // 2. Paksa kembali ke root (MainNavigator) dan hapus semua stack
        // Ini memastikan halaman seperti Menu Management tertutup seketika
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
