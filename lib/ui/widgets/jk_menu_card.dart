import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/menu_model.dart';
import '../widgets/jk_glass_card.dart';

class JkMenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onAdd;

  const JkMenuCard({
    super.key,
    required this.menu,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = menu.stock <= 0;

    return JkGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(menu.imageUrl.isNotEmpty 
                          ? menu.imageUrl 
                          : 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=400'),
                      fit: BoxFit.cover,
                      colorFilter: isOutOfStock 
                          ? const ColorFilter.mode(Colors.black54, BlendMode.darken) 
                          : null,
                    ),
                  ),
                ),
                if (isOutOfStock)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HABIS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    color: isOutOfStock ? Colors.white54 : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  menu.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.softCream.withValues(alpha: isOutOfStock ? 0.3 : 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${menu.price.toInt()}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isOutOfStock ? AppColors.caramelGold.withValues(alpha: 0.5) : AppColors.caramelGold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    GestureDetector(
                      onTap: isOutOfStock ? null : onAdd,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey : AppColors.caramelGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isOutOfStock ? Icons.not_interested : Icons.add, 
                          color: AppColors.charcoal, 
                          size: 20
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
