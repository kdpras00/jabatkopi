import 'package:flutter/material.dart';

class JkSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const JkSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  State<JkSkeleton> createState() => _JkSkeletonState();
}

class _JkSkeletonState extends State<JkSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.white.withValues(alpha: 0.05),
      end: Colors.white.withValues(alpha: 0.15),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
