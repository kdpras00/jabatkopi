import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class JkShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const JkShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
