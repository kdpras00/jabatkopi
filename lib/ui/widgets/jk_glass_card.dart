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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderGrey, width: 1.5),
      ),
      child: child,
    );
  }
}
