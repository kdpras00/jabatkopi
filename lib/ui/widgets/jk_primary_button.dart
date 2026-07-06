import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class JkPrimaryButton extends StatefulWidget {
  final String label;
  final dynamic onPressed; // Gunakan dynamic untuk menghindari konflik tipe Future
  final bool isLoading;

  const JkPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<JkPrimaryButton> createState() => _JkPrimaryButtonState();
}

class _JkPrimaryButtonState extends State<JkPrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tombol aktif jika onPressed tidak null dan tidak sedang loading
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      onTap: isEnabled ? () {
        HapticFeedback.lightImpact();
        if (widget.onPressed is Function) {
          widget.onPressed();
        }
      } : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.caramelGold : AppColors.caramelGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isEnabled ? Colors.white : Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
