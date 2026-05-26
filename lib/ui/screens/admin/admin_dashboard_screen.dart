import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import 'menu_management_screen.dart';
import 'manage_account_screen.dart';
import 'table_management_screen.dart';
import '../../widgets/jk_logout_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchAnalytics());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAnalytics() async {
    if (_analytics == null) setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/admin/analytics');
      if (mounted) {
        setState(() {
          _analytics = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('ADMIN CONTROL CENTER'),
        centerTitle: true,
        actions: const [
          JkLogoutButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Revenue',
                          'Rp ${_analytics?['total_revenue'] ?? 0}',
                          Icons.payments,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Orders',
                          '${_analytics?['total_orders'] ?? 0}',
                          Icons.shopping_bag,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Top Selling Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  JkGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: (_analytics?['top_items'] as List? ?? []).map((item) {
                        return Column(
                          children: [
                            _buildTopItemRow(item['name'], '${item['sales']} sales'),
                            if (item != (_analytics?['top_items'] as List).last)
                              const Divider(color: AppColors.glassBorder),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return JkGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.caramelGold),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.caramelGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemRow(String name, String sales) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(sales, style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.charcoal,
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.darkGrey),
            child: Center(
              child: Text(
                'JABAT KOPI\nADMIN',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.caramelGold),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu, color: AppColors.caramelGold),
            title: const Text('Menu Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts, color: AppColors.caramelGold),
            title: const Text('Manage Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAccountScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant, color: AppColors.caramelGold),
            title: const Text('Kelola Meja'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TableManagementScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
