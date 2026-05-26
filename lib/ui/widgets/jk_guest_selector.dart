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
          '$guestCount Orang',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.caramelGold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Geser untuk mengatur jumlah orang',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.caramelGold,
            inactiveTrackColor: AppColors.glassBorder,
            thumbColor: AppColors.caramelGold,
            overlayColor: AppColors.caramelGold.withValues(alpha: 0.2),
            valueIndicatorColor: AppColors.caramelGold,
            valueIndicatorTextStyle: const TextStyle(color: AppColors.charcoal),
          ),
          child: Slider(
            value: guestCount.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: '$guestCount orang',
            onChanged: (value) => onCountChanged(value.toInt()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final val = index + 1;
            final isSelected = val == guestCount;
            return Text(
              '$val',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.caramelGold : AppColors.softCream.withValues(alpha: 0.5),
              ),
            );
          }),
        ),
        if (guestCount > 4)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kapasitas standar adalah 4 orang/meja. Staf kami akan menyiapkan kursi ekstra atau meja gabungan saat Anda tiba.',
                      style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
