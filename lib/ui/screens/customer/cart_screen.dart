import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import 'checkout_screen.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  bool _isLoading = false;

  // Tipe pesanan: dine_in, pickup, takeaway
  String _orderType = 'dine_in';

  // Untuk Dine In: meja yang dipilih
  int? _selectedTableId;
  String? _selectedTableLabel;

  // Untuk Pickup: jam pengambilan
  String? _pickupTime;

  // Daftar meja dari API
  List<Map<String, dynamic>> _tables = [];
  bool _loadingTables = false;

  bool _isTableLocked = false;
  String? _lockedMessage;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _checkAssignedTable();
  }

  Future<void> _checkAssignedTable() async {
    try {
      // DEBUG: Cek API response langsung
      final activeRes = await ApiClient().get('/orders/active');
      final List<dynamic> activeOrders = activeRes['data'] ?? [];
      
      // DEBUG: tampilkan berapa order aktif yang ditemukan
      debugPrint('=== CART DEBUG: activeOrders.length = ${activeOrders.length}');
      for (final o in activeOrders) {
        debugPrint('=== CART DEBUG: order id=${o['id']} table_id=${o['table_id']} status=${o['status']}');
      }

      if (activeOrders.isNotEmpty) {
        // Cari HANYA pesanan yang punya table_id
        final withTable = activeOrders.firstWhere((o) => o['table_id'] != null, orElse: () => null);

        // Jika ada pesanan yang punya meja, baru kita lock ke meja tersebut
        if (withTable != null) {
          final tableId = int.tryParse(withTable['table_id'].toString());
          if (mounted) {
            setState(() {
              _orderType = 'dine_in';
              _selectedTableId = tableId;
              _selectedTableLabel = 'Meja $tableId';
              _isTableLocked = true;
              _lockedMessage = 'Pesanan Tambahan — Otomatis digabung ke tagihan Meja $tableId Anda';
            });
          }
          return;
        }
        // Jika semua pesanan aktif tidak punya table_id (misal: Takeaway/Pickup, atau bug data lama),
        // kita tidak lock UI dan biarkan user memesan secara normal.
      }

      // 2. Cek Waiting List jika tidak ada pesanan aktif
      final res = await ApiClient().get('/waiting-list/my');
      final wlData = res['data'];
      if (wlData != null && (wlData['status'] == 'notified' || wlData['status'] == 'seated') && wlData['table_id'] != null) {
        if (mounted) {
          setState(() {
            _orderType = 'dine_in';
            _selectedTableId = int.tryParse(wlData['table_id'].toString());
            _selectedTableLabel = 'Meja ${int.tryParse(wlData["table_id"].toString()) ?? ""}';
            _isTableLocked = true;
            _lockedMessage = 'Meja ini diisi otomatis dari Daftar Tunggu Anda';
          });
        }
      }
    } catch (e) {
      // DEBUG: tampilkan error yang sebenarnya
      debugPrint('=== CART ERROR: _checkAssignedTable failed: $e');
    }
  }

  Future<void> _loadTables() async {
    setState(() => _loadingTables = true);
    try {
      final response = await ApiClient().get('/tables');
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _tables = data.map((t) => Map<String, dynamic>.from(t)).toList();
      });
    } catch (_) {
      // Jika gagal load meja, list tetap kosong — user tetap bisa pilih Pickup/Takeaway
    } finally {
      if (mounted) setState(() => _loadingTables = false);
    }
  }

  /// Cek reservasi aktif customer hari ini (status checked_in)
  Future<Map<String, dynamic>?> _getCheckedInReservation() async {
    try {
      final response = await ApiClient().get('/reservations/active');
      final data = response['data'];
      if (data != null && data['status'] == 'checked_in' && data['table_id'] != null) {
        return {
          'table_id': (data['table_id'] as num).toInt(),
          'table_ref': data['table_ref'] ?? 'Meja ${data['table_id']}',
          'reservation_id': data['reservation_id'],
        };
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickupTimePicker() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: 'Pilih jam pengambilan',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.caramelGold,
              surface: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() => _pickupTime = '$hour:$minute');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_cafe_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'Gelasmu masih kosong',
                    style: TextStyle(fontSize: 18, color: AppColors.softCream),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Yuk, seduh kopi pertamamu hari ini!',
                    style: TextStyle(fontSize: 13, color: Colors.white38),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ─── SELECTOR TIPE PESANAN ───────────────────────────
                    _OrderTypeSelector(
                      selected: _orderType,
                      onChanged: _isTableLocked ? null : (type) {
                        setState(() {
                          _orderType = type;
                          // Reset pilihan saat ganti tipe
                          if (type != 'dine_in') {
                            _selectedTableId = null;
                            _selectedTableLabel = null;
                          }
                          if (type != 'pickup') {
                            _pickupTime = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── PANEL KONDISIONAL ────────────────────────────────
                    if (_orderType == 'dine_in') ...[
                      _buildDineInPanel(),
                      const SizedBox(height: 16),
                    ],
                    if (_orderType == 'pickup') ...[
                      _buildPickupPanel(),
                      const SizedBox(height: 16),
                    ],
                    if (_orderType == 'takeaway') ...[
                      _buildTakeawayInfo(),
                      const SizedBox(height: 16),
                    ],

                    // ─── DAFTAR ITEM KERANJANG ────────────────────────────
                    const Text(
                      'Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.softCream,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...cartProvider.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JkGlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.charcoal,
                                image: item.menu.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(item.menu.imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.menu.imageUrl.isEmpty
                                  ? const Icon(Icons.coffee, color: Colors.white24, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.menu.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                                  Text(item.menu.category,
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text('Rp ${NumberFormat('#,###', 'id_ID').format(item.menu.price.toInt())}',
                                      style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _QtyBtn(
                                  icon: Icons.remove,
                                  onTap: () => cartProvider.updateQuantity(item.menu.id, item.quantity - 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                _QtyBtn(
                                  icon: Icons.add,
                                  onTap: () {
                                    final success = cartProvider.updateQuantity(item.menu.id, item.quantity + 1);
                                    if (!success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Maaf, stok sudah mencapai batas maksimal.'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),

              // ─── RINGKASAN & TOMBOL CHECKOUT ──────────────────────────
              JkGlassCard(
                borderRadius: 0,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: Colors.white70)),
                        Text('Rp ${NumberFormat('#,###', 'id_ID').format(cartProvider.subtotal.toInt())}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PPN (10%)', style: TextStyle(color: Colors.white70)),
                        Text('Rp ${NumberFormat('#,###', 'id_ID').format(cartProvider.tax.toInt())}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const Divider(height: 28, color: AppColors.borderGrey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('Rp ${NumberFormat('#,###', 'id_ID').format(cartProvider.totalAmount.toInt())}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    JkPrimaryButton(
                      label: (_isTableLocked && _selectedTableId == null)
                          ? 'SELESAIKAN PESANAN AKTIF DULU'
                          : 'LANJUT CHECKOUT',
                      isLoading: _isLoading,
                      onPressed: (_isLoading || (_isTableLocked && _selectedTableId == null))
                          ? null
                          : () => _handleCheckout(cartProvider),
                    ),
                    const SafeArea(top: false, child: SizedBox(height: 8)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDineInPanel() {
    return JkGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_restaurant, color: AppColors.caramelGold, size: 18),
              const SizedBox(width: 8),
              Text(_isTableLocked ? 'Meja Anda' : 'Pilih Meja', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.softCream)),
              if (_isTableLocked) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock, size: 14, color: AppColors.caramelGold),
              ]
            ],
          ),
          const SizedBox(height: 12),
          if (_isTableLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.caramelGold.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.caramelGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTableLabel ?? 'Meja Terkunci',
                    style: const TextStyle(color: AppColors.caramelGold, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.caramelGold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lockedMessage ?? '',
                          style: const TextStyle(color: AppColors.caramelGold, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            _loadingTables
                ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.caramelGold)))
                : _tables.isEmpty
                    ? const Text('Gagal memuat daftar meja. Pastikan internet tersambung.', style: TextStyle(color: Colors.white54, fontSize: 13))
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _tables.where((t) {
                          final status = t['status'] ?? 'available';
                          return status != 'occupied';
                        }).map((table) {
                          final id = int.tryParse(table['id']?.toString() ?? '0') ?? 0;
                          final ref = table['qr_code_ref'] ?? 'Meja $id';
                          final capacity = table['capacity'] ?? '?';
                          final activeOrders = table['active_order_count'] ?? 0;
                          final isSelected = _selectedTableId == id;

                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedTableId = id;
                              _selectedTableLabel = ref.toString();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.caramelGold.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: isSelected ? AppColors.caramelGold : Colors.white24,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    ref.toString().replaceAll('JK-TABLE-', 'Meja '),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.caramelGold : AppColors.softCream,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\u{1F464} $capacity orang',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Tersedia',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (activeOrders > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$activeOrders pesanan aktif',
                                          style: const TextStyle(color: Colors.amber, fontSize: 10),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          if (!_isTableLocked && _selectedTableLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              '✅ Dipilih: ${_selectedTableLabel!.replaceAll('JK-TABLE-', 'Meja ')}',
              style: const TextStyle(color: AppColors.caramelGold, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickupPanel() {
    return JkGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_filled, color: AppColors.caramelGold, size: 18),
              SizedBox(width: 8),
              Text('Waktu Pengambilan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.softCream)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pesanan akan disiapkan sesuai waktu yang dipilih agar kopi tetap segar saat diambil.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickupTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: _pickupTime != null ? AppColors.caramelGold : Colors.white24),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: _pickupTime != null ? AppColors.caramelGold : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _pickupTime != null ? 'Diambil jam $_pickupTime' : 'Ketuk untuk pilih jam',
                    style: TextStyle(
                      color: _pickupTime != null ? AppColors.caramelGold : Colors.white38,
                      fontSize: 15,
                      fontWeight: _pickupTime != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeawayInfo() {
    return JkGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.caramelGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.caramelGold),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Takeaway', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.softCream)),
                SizedBox(height: 4),
                Text(
                  'Pesanan akan dikemas untuk dibawa pulang. Ambil di kasir setelah pembayaran dikonfirmasi.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(CartProvider cartProvider) async {
    // Validasi tipe pesanan
    if (_orderType == 'dine_in' && _selectedTableId == null && !_isTableLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih meja terlebih dahulu untuk Dine In.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Jika meja terkunci tapi tidak ada table_id → ada pesanan aktif tanpa meja → blok
    if (_isTableLocked && _selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selesaikan atau batalkan pesanan aktif Anda terlebih dahulu.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    if (_orderType == 'pickup' && (_pickupTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih jam pengambilan untuk Pickup.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      int? currentTableId = _orderType == 'dine_in' ? _selectedTableId : null;

      // Capture context-dependent objects BEFORE any await
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Cek reservasi aktif jika Dine In tanpa meja dipilih manual
      if (_orderType == 'dine_in' && currentTableId == null) {
        final checkedInRes = await _getCheckedInReservation();
        if (checkedInRes != null) {
          currentTableId = int.tryParse(checkedInRes['table_id']?.toString() ?? '0') ?? 0;
          messenger.showSnackBar(
            SnackBar(
              content: Text('✅ Check-in aktif. Pesanan dikirim ke ${checkedInRes['table_ref']}.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      final items = cartProvider.items.map((item) => {
        'menu_id': item.menu.id,
        'qty': item.quantity,
        'subtotal': item.totalPrice,
      }).toList();

      navigator.push(
        MaterialPageRoute(
          builder: (_) => CustomerCheckoutScreen(
            tableId: currentTableId,
            items: items,
            totalAmount: cartProvider.totalAmount,
            orderType: _orderType,
            pickupTime: _pickupTime,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melanjutkan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── WIDGET SELECTOR TIPE PESANAN ────────────────────────────────────────────

class _OrderTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String>? onChanged;

  const _OrderTypeSelector({required this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'id': 'dine_in', 'label': 'Dine In', 'icon': Icons.restaurant},
      {'id': 'pickup', 'label': 'Pickup', 'icon': Icons.shopping_bag_outlined},
      {'id': 'takeaway', 'label': 'Takeaway', 'icon': Icons.directions_walk},
    ];

    return JkGlassCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: types.map((t) {
          final id = t['id'] as String;
          final label = t['label'] as String;
          final icon = t['icon'] as IconData;
          final isSelected = selected == id;

          return Expanded(
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.caramelGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.charcoal : Colors.white38,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.charcoal : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── TOMBOL QTY ──────────────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.caramelGold,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.charcoal),
      ),
    );
  }
}
