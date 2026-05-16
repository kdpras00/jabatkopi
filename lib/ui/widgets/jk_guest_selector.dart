import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class JkGuestSelector extends StatelessWidget {
  final int guestCount;
  final Function(int) onCountChanged;

  const JkGuestSelector({
    super.key,
    required this.guestCount,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$guestCount Guests',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.caramelGold,
            inactiveTrackColor: AppColors.glassBorder,
            thumbColor: AppColors.caramelGold,
            overlayColor: AppColors.caramelGold.withOpacity(0.2),
            valueIndicatorColor: AppColors.caramelGold,
            valueIndicatorTextStyle: const TextStyle(color: AppColors.charcoal),
          ),
          child: Slider(
            value: guestCount.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: guestCount.toString(),
            onChanged: (value) => onCountChanged(value.toInt()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (index) => Text((index + 1).toString(), 
            style: TextStyle(fontSize: 12, color: AppColors.softCream.withOpacity(0.5)))),
        ),
      ],
    );
  }
}
