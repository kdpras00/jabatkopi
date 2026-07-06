import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'jk_primary_button.dart';

class JkVirtualPagerDisc extends StatefulWidget {
  final bool isActive;
  final VoidCallback onSilence;

  const JkVirtualPagerDisc({
    super.key,
    required this.isActive,
    required this.onSilence,
  });

  @override
  State<JkVirtualPagerDisc> createState() => _JkVirtualPagerDiscState();
}

class _JkVirtualPagerDiscState extends State<JkVirtualPagerDisc> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'REMOTE PAGER ANTRIAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.caramelGold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 185,
                  height: 185,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.charcoal,
                    border: Border.all(
                      color: widget.isActive ? AppColors.caramelGold : Colors.white12,
                      width: 4,
                    ),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: AppColors.caramelGold.withValues(alpha: 0.35),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 3,
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Blinking LEDs around the rim
                      ...List.generate(8, (index) {
                        final angle = index * (2 * math.pi / 8);
                        final alignX = math.cos(angle) * 0.85;
                        final alignY = math.sin(angle) * 0.85;
                        final isLedLit = widget.isActive &&
                            (_pulseController.value > 0.5 ? index % 2 == 0 : index % 2 != 0);
                        return Align(
                          alignment: Alignment(alignX, alignY),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLedLit ? Colors.redAccent : Colors.red.withValues(alpha: 0.1),
                              boxShadow: isLedLit
                                  ? [
                                      const BoxShadow(
                                        color: Colors.redAccent,
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                      // Center details
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isActive ? Icons.ring_volume : Icons.coffee_outlined,
                            size: 36,
                            color: widget.isActive ? AppColors.caramelGold : Colors.white24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isActive ? 'PAGER AKTIF' : 'SIAP AMBIL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isActive ? AppColors.caramelGold : Colors.white30,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JABAT KOPI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white70,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Pesanan Anda Siap Diambil!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan bawa HP ini ke meja barista/kasir untuk melakukan pengambilan kopi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            JkPrimaryButton(
              label: 'MATIKAN PAGER',
              onPressed: widget.onSilence,
            ),
          ],
        ),
      ),
    );
  }
}
