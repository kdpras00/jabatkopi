import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import 'screens/splash_screen.dart';
import 'login_screen.dart';
import 'screens/customer/home_screen.dart';

/// Gerbang utama app. Dijalankan sekali saat startup untuk menentukan
/// halaman mana yang harus ditampilkan:
/// - Onboarding  → belum pernah buka app (install pertama kali)
/// - LoginScreen → sudah pernah buka tapi belum login / session expired
/// - HomeScreen  → sudah login sebelumnya (auto-resume)
class AppStartupRouter extends StatefulWidget {
  const AppStartupRouter({super.key});

  @override
  State<AppStartupRouter> createState() => _AppStartupRouterState();
}

class _AppStartupRouterState extends State<AppStartupRouter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Lakukan pengecekan session setelah frame pertama selesai render
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveStartup());
  }

  Future<void> _resolveStartup() async {
    if (!mounted) return;

    try {
      // Capture context-dependent objects BEFORE any awaits
      final navigator = Navigator.of(context);
      final authProvider = context.read<AuthProvider>();

      // Tunggu animasi logo singkat
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // Onboarding belum pernah dilihat → tampilkan onboarding
      if (!hasSeenOnboarding) {
        navigator.pushReplacement(_buildRoute(const SplashScreen()));
        return;
      }

      // Sudah pernah buka → coba restore session
      final restored = await authProvider.tryRestoreSession();
      if (!mounted) return;

      if (restored) {
        navigator.pushReplacement(_buildRoute(const CustomerHomeScreen()));
      } else {
        navigator.pushReplacement(_buildRoute(const LoginScreen()));
      }
    } catch (e, stack) {
      debugPrint('Startup resolve error: $e\n$stack');
      if (mounted) {
        Navigator.of(context).pushReplacement(_buildRoute(const LoginScreen()));
      }
    }
  }

  PageRoute _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.caramelGold.withValues(alpha: 0.15),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logojabatkopi.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.coffee,
                      size: 60,
                      color: AppColors.caramelGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'JABAT KOPI',
                style: TextStyle(
                  color: AppColors.caramelGold,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PREMIUM COFFEE EXPERIENCE',
                style: TextStyle(
                  color: AppColors.softCream.withValues(alpha: 0.4),
                  fontSize: 11,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.caramelGold.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
