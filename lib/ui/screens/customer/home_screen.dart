import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../widgets/jk_skeleton.dart';
import '../../widgets/jk_page_route.dart';
import '../../widgets/jk_menu_card.dart';
import '../../widgets/jk_virtual_pager_disc.dart';
import 'reservation_screen.dart';
import 'reservation_summary_screen.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'notification_screen.dart';
import 'dart:convert';
import '../../../core/utils/js_helper.dart'
    if (dart.library.js) '../../../core/utils/js_helper_web.dart' as jsh;

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

  // Pager Checking and Buzzer states
  Timer? _activeOrdersTimer;
  final Set<int> _silencedOrderIds = {};
  OrderModel? _ringingOrder;
  bool _buzzerActive = false;
  Timer? _buzzerTimer;
  bool _pagerPermissionGranted = false;
  bool _hasCheckedPermissionOnPrefs = false;
  bool _hasSeenPagerPrompt = false;

  @override
  void initState() {
    super.initState();
    _loadPagerPermissionPref();
    _startActiveOrdersPolling();
  }

  @override
  void dispose() {
    _activeOrdersTimer?.cancel();
    _buzzerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPagerPermissionPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final granted = prefs.getBool('pager_permission_granted') ?? false;
      final hasSeenPrompt = prefs.getBool('has_seen_pager_prompt') ?? false;
      if (mounted) {
        setState(() {
          _pagerPermissionGranted = granted;
          _hasSeenPagerPrompt = hasSeenPrompt;
          _hasCheckedPermissionOnPrefs = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePagerPermissionPref(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pager_permission_granted', value);
      await prefs.setBool('has_seen_pager_prompt', true);
    } catch (_) {}
  }

  void _startActiveOrdersPolling() {
    // Poll every 8 seconds for active orders
    _activeOrdersTimer = Timer.periodic(const Duration(seconds: 8), (_) => _checkActiveOrders());
    // Run an initial check after 2 seconds
    Timer(const Duration(seconds: 2), () => _checkActiveOrders());
  }

  Future<void> _checkActiveOrders() async {
    if (!mounted) return;
    try {
      final repo = OrderRepository(apiClient: ApiClient());
      final activeOrders = await repo.getActiveOrders();
      
      if (!mounted) return;

      // Find any order in 'ready' status that has not been silenced yet
      OrderModel? readyOrder;
      for (final order in activeOrders) {
        if (order.status == 'ready' && !_silencedOrderIds.contains(order.id)) {
          readyOrder = order;
          break;
        }
      }

      if (readyOrder != null) {
        if (_ringingOrder?.id != readyOrder.id) {
          setState(() {
            _ringingOrder = readyOrder;
          });
          if (_pagerPermissionGranted) {
            _startBuzzerLoop();
          } else {
            _checkAndRequestBuzzerPermission();
          }
        }
      } else {
        // If no ready orders, or currently ringing order is completed/cancelled, stop buzzer
        if (_ringingOrder != null) {
          _stopBuzzer();
        }
      }
    } catch (_) {
      // Quietly ignore network/auth errors in background check
    }
  }

  void _startBuzzerLoop() {
    if (_buzzerTimer != null || _ringingOrder == null || !_pagerPermissionGranted) return;
    
    setState(() {
      _buzzerActive = true;
    });

    // ponytail: deferred buzzer/pager alarm
    // HapticFeedback.vibrate();
    // jsh.playWebBeep();

    _buzzerTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      // HapticFeedback.vibrate();
      // jsh.playWebBeep();
    });
  }

  void _stopBuzzer() {
    _buzzerTimer?.cancel();
    _buzzerTimer = null;
    if (_ringingOrder != null) {
      _silencedOrderIds.add(_ringingOrder!.id);
    }
    setState(() {
      _ringingOrder = null;
      _buzzerActive = false;
    });
  }

  Future<void> _checkAndRequestBuzzerPermission() async {
    if (_hasSeenPagerPrompt || _pagerPermissionGranted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 270,
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_active, color: AppColors.caramelGold, size: 36),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Mau Tahu Kapan Pesanan Siap?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Aktifkan getaran dan bunyi pager agar Anda langsung tahu saat kopi siap diambil dari meja barista tanpa perlu mengantre.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Nanti Saja',
                        style: TextStyle(color: Colors.white30, fontSize: 14),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white10,
                  ),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Aktifkan',
                        style: TextStyle(
                          color: AppColors.caramelGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      final granted = result == true;
      setState(() {
        _pagerPermissionGranted = granted;
        _hasSeenPagerPrompt = true;
      });
      _savePagerPermissionPref(granted);
      if (granted && _ringingOrder != null) {
        _startBuzzerLoop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartCount = cartProvider.items.length;
    final totalAmount = cartProvider.totalAmount;

    return Stack(
      children: [
        Scaffold(
          body: _screens[_currentIndex],
          floatingActionButton: cartCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerCartScreen()),
                  ),
                  backgroundColor: AppColors.caramelGold,
                  icon: const Icon(Icons.shopping_cart, color: AppColors.charcoal),
                  label: Text(
                    'CHECKOUT ($cartCount)',
                    style: const TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          extendBody: false,
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.darkGrey,
                border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, 'Home'),
                  _buildNavItem(1, Icons.receipt_long_outlined, 'Orders'),
                  _buildNavItem(2, Icons.calendar_month_outlined, 'Booking'),
                  _buildNavItem(3, Icons.person_outline, 'Profile'),
                ],
              ),
            ),
          ),
        ),
        if (_ringingOrder != null && _pagerPermissionGranted)
          Positioned.fill(
            child: Container(
              color: AppColors.charcoal,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: JkVirtualPagerDisc(
                    isActive: _buzzerActive,
                    onSilence: _stopBuzzer,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.caramelGold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.caramelGold : Colors.white54,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.caramelGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
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
  String _selectedCategory = 'All';

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
    final displayedMenus = _selectedCategory == 'All' 
        ? _menus 
        : _menus.where((m) => m.category == _selectedCategory).toList();
    final categories = ['All', ..._menus.map((m) => m.category).toSet()];

    return Scaffold(
      body: _isLoading
          ? ListView.builder(itemCount: 6, itemBuilder: (c, i) => const JkSkeleton(height: 120, margin: EdgeInsets.all(16)))
          : RefreshIndicator(
              onRefresh: _fetchMenus,
              color: AppColors.caramelGold,
              backgroundColor: AppColors.darkGrey,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppColors.charcoal,
                    elevation: 0,
                    title: const Text(
                      'JABAT KOPI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white, letterSpacing: 1.5),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.event_seat_outlined, color: AppColors.caramelGold),
                        onPressed: () => Navigator.push(context, JkPageRoute(page: const CustomerReservationScreen())),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                      child: Text('Explore Our Collection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.caramelGold)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat, style: TextStyle(color: isSelected ? AppColors.charcoal : Colors.white)),
                              selected: isSelected,
                              selectedColor: AppColors.caramelGold,
                              backgroundColor: AppColors.darkGrey,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = cat);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                        (context, index) {
                          final menu = displayedMenus[index];
                          final cartQuantity = context.watch<CartProvider>().getQuantity(menu.id);
                          
                          return JkMenuCard(
                            menu: menu,
                            cartQuantity: cartQuantity,
                            onAdd: () {
                              final success = context.read<CartProvider>().addItem(menu);
                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Stok ${menu.name} terbatas!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            onRemove: () {
                              final newQty = cartQuantity - 1;
                              context.read<CartProvider>().updateQuantity(menu.id, newQty);
                            },
                          );
                        },
                        childCount: displayedMenus.length,
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const JkSkeleton(height: 140, margin: EdgeInsets.only(bottom: 16));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [_buildCartAction(context)],
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : _orders.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum Ada Pesanan',
                  description: 'Yuk, cari dan nikmati kopi favoritmu sekarang juga!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    Color badgeColor;
                    switch (order.status) {
                      case 'pending': badgeColor = Colors.orange; break;
                      case 'processing': badgeColor = Colors.indigo; break;
                      case 'preparing': badgeColor = Colors.blue; break;
                      case 'ready': badgeColor = Colors.green; break;
                      case 'completed': badgeColor = AppColors.caramelGold; break;
                      case 'cancelled': badgeColor = Colors.redAccent; break;
                      default: badgeColor = Colors.grey;
                    }

                    String statusLabel;
                    switch (order.status) {
                      case 'pending': statusLabel = 'Menunggu'; break;
                      case 'processing': statusLabel = 'Diproses'; break;
                      case 'preparing': statusLabel = 'Dibuat'; break;
                      case 'ready': statusLabel = 'Siap Diambil'; break;
                      case 'completed': statusLabel = 'Selesai'; break;
                      case 'cancelled': statusLabel = 'Dibatalkan'; break;
                      default: statusLabel = order.status;
                    }

                    String dateStr = '';
                    try {
                      final parsedDate = DateTime.parse(order.createdAt).toLocal();
                      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
                    } catch (e) {
                      dateStr = order.createdAt;
                    }

                    String orderSummary = '';
                    if (order.items.isEmpty) {
                      orderSummary = 'Tanpa Menu';
                    } else if (order.items.length == 1) {
                      orderSummary = '${order.items[0].qty}x ${order.items[0].menuName}';
                    } else {
                      final otherCount = order.items.length - 1;
                      orderSummary = '${order.items[0].qty}x ${order.items[0].menuName} +$otherCount menu lainnya';
                    }

                    final itemQtyTotal = order.items.fold<int>(0, (sum, i) => sum + i.qty);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            JkPageRoute(page: OrderTrackingScreen(orderId: order.id)),
                          );
                          _fetchHistory();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Date/Time & Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white10, height: 1),
                              const SizedBox(height: 12),
                              // Content Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orderSummary,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Order #${order.id} • $itemQtyTotal Item',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Rp ${NumberFormat('#,###').format(order.totalAmount)}',
                                    style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white24,
                                    size: 20,
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

  Future<void> _cancelReservation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text('Batalkan Reservasi?', style: TextStyle(color: AppColors.caramelGold)),
        content: const Text('Meja yang sudah direservasi akan dibebaskan.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEMBALI', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.normal)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YA, BATALKAN', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ReservationRepository(apiClient: ApiClient()).cancelReservation(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservasi berhasil dibatalkan.'), backgroundColor: Colors.green),
        );
        _fetchReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const JkSkeleton(height: 180, margin: EdgeInsets.only(bottom: 16));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Reservasi'),
        actions: [_buildCartAction(context)],
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : _reservations.isEmpty
              ? _buildEmptyState(
                  icon: Icons.event_seat_outlined,
                  title: 'Belum Ada Reservasi',
                  description: 'Meja favoritmu menanti. Buat reservasi meja sekarang juga!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) {
                    final res = _reservations[index];
                    final bookingId = 'JK-RES-${res['id']}';
                    final tableId = res['table_id'] ?? 0;
                    final pax = res['pax'] ?? 0;
                    final status = res['status']?.toString() ?? 'pending';

                    Color statusColor;
                    switch (status) {
                      case 'booked': statusColor = Colors.orange; break;
                      case 'checked_in': statusColor = Colors.green; break;
                      case 'completed': statusColor = AppColors.caramelGold; break;
                      case 'cancelled': statusColor = Colors.redAccent; break;
                      default: statusColor = Colors.grey;
                    }

                    String statusLabel;
                    switch (status) {
                      case 'booked': statusLabel = 'Terkonfirmasi'; break;
                      case 'checked_in': statusLabel = 'Sudah Hadir'; break;
                      case 'completed': statusLabel = 'Selesai'; break;
                      case 'cancelled': statusLabel = 'Dibatalkan'; break;
                      default: statusLabel = status;
                    }

                    String friendlyDate = '';
                    try {
                      final parsedDate = DateTime.parse(res['reservation_date']).toLocal();
                      friendlyDate = DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(parsedDate);
                    } catch (e) {
                      friendlyDate = res['reservation_date'];
                    }

                    final cardTitle = tableId > 0 ? 'Reservasi Meja $tableId' : 'Menunggu Pilihan Meja';

                    final canCancel = status == 'booked';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            JkPageRoute(
                              page: ReservationSummaryScreen(
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
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Date/Time & Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    friendlyDate,
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white10, height: 1),
                              const SizedBox(height: 12),
                              // Content Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cardTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Kode: $bookingId • $pax Orang',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                        if (canCancel) ...[
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () => _cancelReservation(res['id'] as int),
                                            child: const Text(
                                              'Batalkan Reservasi',
                                              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white24,
                                    size: 20,
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
  int _orderCount = 0;
  int _bookingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient().get('/profile');
      final orders = await OrderRepository(apiClient: ApiClient()).getOrderHistory();
      final reservations = await ReservationRepository(apiClient: ApiClient()).getReservationHistory();

      if (mounted) {
        setState(() {
          _profileData = res['data'];
          _orderCount = orders.length;
          _bookingCount = reservations.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          JkSkeleton(height: 120),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: JkSkeleton(height: 100)),
              SizedBox(width: 16),
              Expanded(child: JkSkeleton(height: 100)),
            ],
          ),
          SizedBox(height: 24),
          JkSkeleton(height: 250),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [_buildCartAction(context)],
      ),
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? _buildProfileSkeleton()
        : Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final username = _profileData?['username'] ?? auth.username;
          final imageUrl = _profileData?['image_url'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                // Header Profile Flat Card
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.caramelGold, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.darkGrey,
                          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                              ? (imageUrl.startsWith('data:image')
                                  ? MemoryImage(base64Decode(imageUrl.split(',').last))
                                  : NetworkImage(imageUrl)) as ImageProvider
                              : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person, size: 36, color: AppColors.caramelGold)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username?.toUpperCase() ?? 'CUSTOMER',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Member Jabat Kopi',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            // Compact inline stats row
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined, color: AppColors.caramelGold, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$_orderCount Orders',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                const Text('•', style: TextStyle(color: Colors.white24)),
                                const SizedBox(width: 12),
                                const Icon(Icons.event_seat_outlined, color: AppColors.caramelGold, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$_bookingCount Bookings',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Actions
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildProfileItem(
                        context, 
                        Icons.person_outline, 
                        'Edit Profile', 
                        'Update your personal info',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildProfileItem(
                        context, 
                        Icons.notifications_none, 
                        'Notifications', 
                        'Manage alerts & updates',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                      _buildProfileItem(
                        context, 
                        Icons.security, 
                        'Security', 
                        'Password & biometrics',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
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

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      auth.logout();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
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
    return Column(
      children: [
        Icon(icon, color: AppColors.caramelGold.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.caramelGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
  return const SizedBox.shrink();
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.darkGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.caramelGold.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
