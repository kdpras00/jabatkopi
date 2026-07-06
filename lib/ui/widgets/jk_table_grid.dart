import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class JkTableGrid extends StatelessWidget {
  final List<Map<String, dynamic>> tables;
  final int? selectedTableId;
  final Function(int) onTableSelected;

  const JkTableGrid({
    super.key,
    required this.tables,
    required this.selectedTableId,
    required this.onTableSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada meja tersedia.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final id = table['id'] as int;
        final ref = table['qr_code_ref'] as String? ?? 'T-$id';
        final cap = table['capacity'] as int? ?? 4;
        final status = table['display_status'] ?? 'available';
        
        final isSelected = selectedTableId == id;
        
        // Color logic
        Color bgColor = AppColors.darkGrey;
        Color borderColor = AppColors.borderGrey;
        Color textColor = AppColors.softCream;
        bool isSelectable = true;

        if (status == 'occupied') {
          bgColor = Colors.red.withValues(alpha: 0.2);
          borderColor = Colors.red.withValues(alpha: 0.5);
          textColor = Colors.redAccent;
          isSelectable = false;
        } else if (status == 'reserved') {
          bgColor = Colors.orange.withValues(alpha: 0.2);
          borderColor = Colors.orange.withValues(alpha: 0.5);
          textColor = Colors.orangeAccent;
          isSelectable = false;
        }

        if (isSelected) {
          bgColor = AppColors.caramelGold;
          borderColor = AppColors.caramelGold;
          textColor = AppColors.charcoal;
        }

        return GestureDetector(
          onTap: isSelectable ? () => onTableSelected(id) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.caramelGold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Icon(
                        status == 'occupied' ? Icons.person : (status == 'reserved' ? Icons.event_busy : Icons.table_restaurant),
                        color: textColor,
                        size: !isSelectable ? 22 : 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ref.split('-').last,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$cap Pax',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSelectable)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 7, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
