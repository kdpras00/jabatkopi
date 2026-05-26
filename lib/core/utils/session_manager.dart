import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../ui/login_screen.dart';

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

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi berakhir karena tidak aktif. Silakan login kembali.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
