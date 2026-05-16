import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SessionManager extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const SessionManager({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 15), // Default 15 menit
  });

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _handleLogout);
  }

  void _handleLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      authProvider.logout();
      
      // Bersihkan semua stack navigasi
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
      // Tampilkan info singkat jika perlu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired due to inactivity.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleInteraction([_]) {
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleInteraction,
      onPointerMove: _handleInteraction,
      onPointerUp: _handleInteraction,
      child: widget.child,
    );
  }
}
