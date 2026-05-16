import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../main_navigator.dart';
import '../widgets/jk_primary_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Selamat Datang',
      'subtitle': 'Nikmati pengalaman minum kopi terbaik dengan biji pilihan berkualitas tinggi.',
      'image': 'https://tmudxkcovejdrweucpjl.supabase.co/storage/v1/object/public/assets/jabat_kopi_logo.png',
      'bg': 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=800',
    },
    {
      'title': 'Biji Kopi Pilihan',
      'subtitle': 'Kami hanya menggunakan biji kopi arabika dan robusta terbaik dari seluruh nusantara.',
      'image': 'https://tmudxkcovejdrweucpjl.supabase.co/storage/v1/object/public/assets/beans_intro.png',
      'bg': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800',
    },
    {
      'title': 'Suasana Nyaman',
      'subtitle': 'Tempat yang sempurna untuk bekerja, bersantai, atau sekadar berbincang dengan teman.',
      'image': 'https://tmudxkcovejdrweucpjl.supabase.co/storage/v1/object/public/assets/cafe_intro.png',
      'bg': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    data['bg']!,
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.15),
                  ),
                  // Content centered
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.caramelGold.withOpacity(0.1),
                                  blurRadius: 100,
                                  spreadRadius: 20,
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                data['image']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.coffee, size: 100, color: AppColors.caramelGold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          Text(
                            data['title']!.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: AppColors.caramelGold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            data['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.softCream.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
      ),
          
          // Page Indicator & Buttons
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.caramelGold : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Get Started or Next
                if (_currentPage == _onboardingData.length - 1)
                  JkPrimaryButton(
                    label: 'MULAI SEKARANG',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigator()),
                      );
                    },
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _onboardingData.length - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('SKIP', style: TextStyle(color: Colors.white24)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.caramelGold,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(Icons.chevron_right, color: AppColors.charcoal),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
