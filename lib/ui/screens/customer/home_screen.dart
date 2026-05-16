import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../data/models/menu_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/reservation_repository.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_menu_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_shimmer.dart';
import 'reservation_screen.dart';
import 'reservation_summary_screen.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'notification_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MenuCatalogTab(),
    const OrderHistoryTab(),
    const ReservationHistoryTab(),
    const CustomerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.charcoal,
        selectedItemColor: AppColors.caramelGold,
        unselectedItemColor: AppColors.softCream.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class MenuCatalogTab extends StatefulWidget {
  const MenuCatalogTab({super.key});

  @override
  State<MenuCatalogTab> createState() => _MenuCatalogTabState();
}

class _MenuCatalogTabState extends State<MenuCatalogTab> {
  List<MenuModel> _menus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    try {
      final repo = MenuRepository(apiClient: ApiClient());
      final menus = await repo.getMenus();
      if (mounted) {
        setState(() {
          _menus = menus;
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
      appBar: AppBar(
        title: const Text('JABAT KOPI'),
        actions: [
          _buildCartAction(context),
          IconButton(
            icon: const Icon(Icons.event_seat),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerReservationScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : RefreshIndicator(
              onRefresh: _fetchMenus,
              color: AppColors.caramelGold,
              backgroundColor: AppColors.darkGrey,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Explore Our Collection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.caramelGold)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => JkMenuCard(
                          menu: _menus[index],
                          onAdd: () {
                            final success = context.read<CartProvider>().addItem(_menus[index]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? '${_menus[index].name} ditambahkan ke keranjang' 
                                    : 'Stok ${_menus[index].name} terbatas!'),
                                backgroundColor: success ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                        childCount: _menus.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({super.key});

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final repo = OrderRepository(apiClient: ApiClient());
      final orders = await repo.getOrderHistory();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [_buildCartAction(context)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.softCream)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JkGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order.status == 'pending' ? Colors.orange : AppColors.caramelGold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Total: Rp ${order.totalAmount.toInt()}', style: const TextStyle(color: AppColors.caramelGold)),
                            const SizedBox(height: 16),
                            JkPrimaryButton(
                              label: 'LIHAT STATUS / STRUK',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ReservationHistoryTab extends StatefulWidget {
  const ReservationHistoryTab({super.key});

  @override
  State<ReservationHistoryTab> createState() => _ReservationHistoryTabState();
}

class _ReservationHistoryTabState extends State<ReservationHistoryTab> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    try {
      final repo = ReservationRepository(apiClient: ApiClient());
      final res = await repo.getReservationHistory();
      if (mounted) {
        setState(() {
          _reservations = res;
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
      appBar: AppBar(
        title: const Text('Riwayat Reservasi'),
        actions: [_buildCartAction(context)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _reservations.isEmpty
              ? const Center(child: Text('Belum ada reservasi', style: TextStyle(color: AppColors.softCream)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) {
                    final res = _reservations[index];
                    final bookingId = res['booking_id'] ?? 'N/A';
                    final tableId = res['table_id'] ?? 0;
                    final pax = res['pax'] ?? 0;
                    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(res['reservation_date']));
                    final status = res['status'] ?? 'pending';

                    final isArrived = status == 'arrived';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationSummaryScreen(
                                date: DateTime.parse(res['reservation_date']),
                                time: DateFormat('HH:mm').format(DateTime.parse(res['reservation_date'])),
                                guests: pax,
                                tableId: tableId,
                                qrCode: res['qr_code'] ?? 'JK-RES-${res['id']}',
                                bookingId: bookingId,
                              ),
                            ),
                          );
                        },
                        child: JkGlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(bookingId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.caramelGold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isArrived ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isArrived ? Colors.green : Colors.orange),
                                    ),
                                    child: Text(
                                      isArrived ? 'TELAH TIBA' : status.toString().toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isArrived ? Colors.greenAccent : Colors.orangeAccent),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: AppColors.glassBorder, height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.table_restaurant, color: Colors.white54, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Meja $tableId', style: const TextStyle(color: Colors.white54)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.people, color: Colors.white54, size: 16),
                                  const SizedBox(width: 8),
                                  Text('$pax Orang', style: const TextStyle(color: Colors.white54)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
                                      const SizedBox(width: 8),
                                      Text(timeStr, style: const TextStyle(color: Colors.white54)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_activity, color: AppColors.caramelGold, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('TIKET CHECK-IN', style: TextStyle(color: AppColors.caramelGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient().get('/profile');
      if (mounted) {
        setState(() {
          _profileData = res['data'];
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
      appBar: AppBar(
        title: const Text('PROFILE'),
        centerTitle: true,
        actions: [_buildCartAction(context)],
      ),
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
        : Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final username = _profileData?['username'] ?? auth.username;
          final imageUrl = _profileData?['image_url'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                // Header Profile - Clickable to Edit
                GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    if (updated == true) _fetchProfile();
                  },
                  child: JkGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.caramelGold, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: AppColors.darkGrey,
                                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) 
                                  ? NetworkImage(imageUrl) 
                                  : null,
                                child: (imageUrl == null || imageUrl.isEmpty)
                                  ? const Icon(Icons.person, size: 50, color: AppColors.caramelGold)
                                  : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username?.toUpperCase() ?? 'CUSTOMER',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.caramelGold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Member Jabat Kopi',
                          style: TextStyle(color: AppColors.softCream.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Section
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Orders', '12', Icons.receipt_long),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard('Booking', '3', Icons.event_seat),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Account Actions
                JkGlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildProfileItem(
                        context, 
                        Icons.person_outline, 
                        'Edit Profile', 
                        'Update your personal info',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      ),
                      const Divider(color: AppColors.glassBorder, height: 1),
                      _buildProfileItem(
                        context, 
                        Icons.notifications_none, 
                        'Notifications', 
                        'Manage alerts & updates',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                      ),
                      const Divider(color: AppColors.glassBorder, height: 1),
                      _buildProfileItem(
                        context, 
                        Icons.security, 
                        'Security', 
                        'Password & biometrics',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                      ),
                      const Divider(color: AppColors.glassBorder, height: 1),
                      _buildProfileItem(
                        context, 
                        Icons.help_outline, 
                        'Help & Support', 
                        'FAQs and contact info',
                        onTap: _contactSupport,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    onPressed: () {
                      auth.logout();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'v1.2.0 Build 2024.05',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return JkGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.caramelGold.withOpacity(0.7), size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.caramelGold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.caramelGold, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fitur $title akan segera hadir!'),
            backgroundColor: AppColors.charcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _contactSupport() async {
    const phone = "087780086677";
    final url = Uri.parse("https://wa.me/62${phone.substring(1)}?text=Halo Jabat Kopi, saya butuh bantuan terkait akun saya.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

Widget _buildCartAction(BuildContext context) {
  final cartCount = context.watch<CartProvider>().items.length;
  
  return Stack(
    alignment: Alignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => const CustomerCartScreen())
        ),
      ),
      if (cartCount > 0)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.caramelGold,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '$cartCount',
              style: const TextStyle(color: AppColors.charcoal, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}
