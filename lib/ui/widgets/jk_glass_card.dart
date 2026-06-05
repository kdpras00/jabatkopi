import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class JkGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool withBlur;

  const JkGlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.borderRadius = 16.0,
    this.padding,
    this.withBlur = false, // Disabled by default for better scrolling performance
  });

  @override
  Widget build(BuildContext context) {
    // The simulated glass container
    Widget glassContainer = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: withBlur ? AppColors.glassBackground : AppColors.glassBackground.withValues(alpha: 0.2),
        gradient: withBlur ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );

    if (withBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: glassContainer,
        ),
      );
    }

    // High performance fallback
    return glassContainer;
  }
}
