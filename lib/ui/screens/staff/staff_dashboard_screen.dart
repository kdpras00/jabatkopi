import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/reservation_repository.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_logout_button.dart';
import 'reservation_verification_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'DASHBOARD PEGAWAI',
    'ACTION ORDER',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: StaffDrawer(
        selectedIndex: _selectedIndex,
        onSelect: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: const [
          JkLogoutButton(),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const StaffOverviewTab();
      case 1:
        return const OrderMonitorTab();
      default:
        return const StaffOverviewTab();
    }
  }
}

class StaffDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const StaffDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

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
                'JABAT KOPI\nSTAFF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.caramelGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.dashboard,
              color: selectedIndex == 0 ? AppColors.caramelGold : Colors.white70,
            ),
            title: Text(
              'Dashboard Pegawai',
              style: TextStyle(
                color: selectedIndex == 0 ? AppColors.caramelGold : Colors.white,
              ),
            ),
            selected: selectedIndex == 0,
            onTap: () {
              onSelect(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shopping_cart,
              color: selectedIndex == 1 ? AppColors.caramelGold : Colors.white70,
            ),
            title: Text(
              'Action Order',
              style: TextStyle(
                color: selectedIndex == 1 ? AppColors.caramelGold : Colors.white,
              ),
            ),
            selected: selectedIndex == 1,
            onTap: () {
              onSelect(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.fact_check,
              color: Colors.white70,
            ),
            title: const Text(
              'Verifikasi Reservasi',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationVerificationScreen()));
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

class StaffOverviewTab extends StatefulWidget {
  const StaffOverviewTab({super.key});

  @override
  State<StaffOverviewTab> createState() => _StaffOverviewTabState();
}

class _StaffOverviewTabState extends State<StaffOverviewTab> {
  late OrderRepository _orderRepo;
  late ReservationRepository _reservationRepo;
  int _activeOrdersCount = 0;
  int _reservationsCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository(apiClient: ApiClient());
    _reservationRepo = ReservationRepository(apiClient: ApiClient());
    _fetchCounts();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchCounts());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCounts() async {
    try {
      final orders = await _orderRepo.getActiveOrders();
      final reservations = await _reservationRepo.getAdminReservations();
      if (mounted) {
        setState(() {
          _activeOrdersCount = orders.length;
          _reservationsCount = reservations.length;
        });
      }
    } catch (e) {
      // Keep existing counts if polling fails temporarily
      if (mounted && _activeOrdersCount == 0 && _reservationsCount == 0) {
        // Option to show a subtle offline indicator could go here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Active Orders',
                  '$_activeOrdersCount',
                  Icons.shopping_cart_checkout,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Reservations',
                  '$_reservationsCount',
                  Icons.book_online,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Quick Guidelines',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          JkGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuideItem(
                  Icons.touch_app,
                  'Use the sidebar drawer to switch between modules.',
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  Icons.update,
                  'Update order status promptly from Pending -> Preparing -> Ready -> Completed.',
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  Icons.table_restaurant,
                  'Monitor table reservations to prepare seating in advance.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return JkGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.caramelGold, size: 28),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.caramelGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.caramelGold, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ),
      ],
    );
  }
}

class OrderMonitorTab extends StatefulWidget {
  const OrderMonitorTab({super.key});

  @override
  State<OrderMonitorTab> createState() => _OrderMonitorTabState();
}

class _OrderMonitorTabState extends State<OrderMonitorTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late OrderRepository _orderRepo;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  int _lastOrderCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository(apiClient: ApiClient());
    _fetchOrders();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await _orderRepo.getActiveOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });

        if (_orders.length > _lastOrderCount && _lastOrderCount != 0) {
          _playNotification();
        }
        _lastOrderCount = _orders.length;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_orders.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Koneksi terputus. Menunggu jaringan...')),
          );
        }
      }
    }
  }

  void _playNotification() async {
    HapticFeedback.heavyImpact();
    await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _orderRepo.updateOrderStatus(id, status);
      _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.caramelGold));
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('Belum ada pesanan aktif', style: TextStyle(color: AppColors.softCream)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: JkGlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(order.status),
                  child: Text('#${order.id}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table ${order.tableId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Rp ${order.totalAmount.toInt()}', style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) => _updateStatus(order.id, val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pending', child: Text('Pending')),
                    const PopupMenuItem(value: 'processing', child: Text('Processing')),
                    const PopupMenuItem(value: 'preparing', child: Text('Preparing')),
                    const PopupMenuItem(value: 'ready', child: Text('Ready')),
                    const PopupMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.caramelGold),
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.caramelGold.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.status.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.caramelGold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: AppColors.caramelGold, size: 16),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.purple;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'completed': return Colors.grey;
      default: return Colors.white;
    }
  }
}
