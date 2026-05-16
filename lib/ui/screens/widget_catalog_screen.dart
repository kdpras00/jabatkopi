import 'package:flutter/material.dart';
import '../widgets/jk_glass_card.dart';
import '../widgets/jk_primary_button.dart';
import '../widgets/jk_shimmer.dart';
import '../../core/theme/app_colors.dart';

class WidgetCatalogScreen extends StatelessWidget {
  const WidgetCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jabat Kopi Widget Catalog')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typography', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 16),
            Text('Headline Large', style: Theme.of(context).textTheme.displayLarge),
            Text('Title Large', style: Theme.of(context).textTheme.titleLarge),
            Text('Body Large - Premium coffee experience.', style: Theme.of(context).textTheme.bodyLarge),
            Text('Body Medium - Modern and aesthetic.', style: Theme.of(context).textTheme.bodyMedium),
            
            const SizedBox(height: 40),
            Text('Buttons', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            JkPrimaryButton(
              label: 'PRIMARY BUTTON',
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            JkPrimaryButton(
              label: 'LOADING BUTTON',
              onPressed: () {},
              isLoading: true,
            ),
            
            const SizedBox(height: 40),
            Text('Glassmorphism Cards', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            JkGlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.coffee_maker, color: AppColors.caramelGold, size: 48),
                  const SizedBox(height: 16),
                  Text('Premium Espresso', style: Theme.of(context).textTheme.titleLarge),
                  const Text('Experience the depth of charcoal roasted beans.'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Text('Loading Shimmers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const JkShimmer(width: double.infinity, height: 100, borderRadius: 16),
            const SizedBox(height: 8),
            const JkShimmer(width: 200, height: 20),
          ],
        ),
      ),
    );
  }
}
