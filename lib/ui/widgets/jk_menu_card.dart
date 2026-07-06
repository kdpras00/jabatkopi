import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/menu_model.dart';

import '../widgets/jk_bounce.dart';

class JkMenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final int cartQuantity;

  const JkMenuCard({
    super.key,
    required this.menu,
    required this.onAdd,
    required this.onRemove,
    this.cartQuantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = menu.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: AppColors.charcoal,
                    image: menu.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(menu.imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: isOutOfStock 
                                ? const ColorFilter.mode(Colors.black54, BlendMode.darken) 
                                : null,
                          )
                        : null,
                  ),
                  child: menu.imageUrl.isEmpty
                      ? const Center(child: Icon(Icons.coffee, color: Colors.white24, size: 48))
                      : null,
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
                    Expanded(
                      child: Text(
                        'Rp ${menu.price.toInt()}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isOutOfStock ? AppColors.caramelGold.withValues(alpha: 0.5) : AppColors.caramelGold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.not_interested, color: AppColors.charcoal, size: 20),
                      )
                    else if (cartQuantity == 0)
                      JkBounce(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.caramelGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: AppColors.charcoal, size: 20),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.caramelGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.caramelGold.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            JkBounce(
                              onTap: onRemove,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.remove, color: AppColors.caramelGold, size: 16),
                              ),
                            ),
                            Text(
                              '$cartQuantity',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            JkBounce(
                              onTap: onAdd,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.add, color: AppColors.caramelGold, size: 16),
                              ),
                            ),
                          ],
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
