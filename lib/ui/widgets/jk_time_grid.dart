import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class JkTimeGrid extends StatelessWidget {
  final String? selectedTime;
  final Function(String) onTimeSelected;

  const JkTimeGrid({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final times = [
      '16:00', '17:00', '18:00', '19:00',
      '20:00', '21:00', '22:00', '23:00',
      '00:00',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.0,
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        final isSelected = selectedTime == time;

        return GestureDetector(
          onTap: () => onTimeSelected(time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.caramelGold : AppColors.glassBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.caramelGold : AppColors.glassBorder,
              ),
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  color: isSelected ? AppColors.charcoal : AppColors.softCream,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
