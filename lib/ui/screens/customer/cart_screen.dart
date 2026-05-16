import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_table_grid.dart';
import 'midtrans_payment_screen.dart';
import 'digital_receipt_screen.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  /// Cek reservasi aktif customer hari ini
  /// Returns: Map dengan table_id, status, table_ref — atau null jika tidak ada
  Future<Map<String, dynamic>?> _getActiveReservation() async {
    try {
      final response = await ApiClient().get('/reservations/active');
      final data = response['data'];
      if (data != null && data['table_id'] != null) {
        return {
          'table_id': (data['table_id'] as num).toInt(),
          'status': data['status'] ?? 'booked',
          'table_ref': data['table_ref'] ?? 'Meja ${data['table_id']}',
          'reservation_id': data['reservation_id'],
        };
      }
    } catch (_) {}
    return null;
  }

  /// Shortcut untuk hanya mengambil table_id
  Future<int?> _getActiveReservationTableId() async {
    final res = await _getActiveReservation();
    return res?['table_id'] as int?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: AppColors.softCream),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JkGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(item.menu.imageUrl.isNotEmpty
                                      ? item.menu.imageUrl
                                      : 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=400'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.menu.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                                  Text(item.menu.category),
                                  const SizedBox(height: 8),
                                  Text('Rp ${item.menu.price.toInt()}',
                                      style: const TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _QtyBtn(
                                  icon: Icons.remove,
                                  onTap: () {
                                    cartProvider.updateQuantity(item.menu.id, item.quantity - 1);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    );
                  },
                ),
              ),
              JkGlassCard(
                borderRadius: 0,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('Rp ${cartProvider.subtotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (10%)'),
                        Text('Rp ${cartProvider.tax.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.glassBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Rp ${cartProvider.totalAmount.toInt()}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    JkPrimaryButton(
                      label: 'CHECKOUT NOW',
                      onPressed: () async {
                        try {
                          final repo = OrderRepository(apiClient: ApiClient());
                          
                          // Convert cart items to the format expected by the API
                          final items = cartProvider.items.map((item) => {
                            'menu_id': item.menu.id,
                            'qty': item.quantity,
                            'subtotal': item.totalPrice,
                          }).toList();
                          
                          // Cek apakah ada reservasi aktif → auto-fill table_id
                          int? currentTableId = cartProvider.tableId;

                          if (currentTableId == null) {
                            final activeRes = await _getActiveReservation();
                            int? preSelectedId;
                            bool isNearby = false;

                            if (activeRes != null) {
                              final resStatus = activeRes['status']?.toString() ?? '';
                              final resDateStr = activeRes['reservation_date']?.toString();
                              
                              if (resDateStr != null) {
                                try {
                                  final resTime = DateTime.parse(resDateStr);
                                  final diff = resTime.difference(DateTime.now()).abs();
                                  isNearby = diff.inMinutes <= 60;

                                  if (resStatus == 'checked_in') {
                                    // 1. SUDAH CHECK-IN -> Langsung pakai meja tersebut (Otomatis)
                                    currentTableId = activeRes['table_id'] as int;
                                    cartProvider.setTableId(currentTableId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Anda sudah check-in. Pesanan dikirim ke meja Anda.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else if (isNearby) {
                                    // 2. BELUM CHECK-IN TAPI WAKTUNYA DEKAT -> Pre-select tapi tanya dulu
                                    preSelectedId = activeRes['table_id'] as int?;
                                  }
                                } catch (_) {
                                  // Jika parsing tanggal gagal, abaikan reservasi
                                }
                              }
                            }

                            // Jika belum auto-fill (karena belum check-in), tampilkan dialog
                            if (currentTableId == null && context.mounted) {
                                final now = DateTime.now();
                                final dateStr = DateFormat('yyyy-MM-dd').format(now);
                                final timeStr = DateFormat('HH:00').format(now);
                                
                                final tablesRes = await ApiClient().get('/tables/status?date=$dateStr&time=$timeStr');
                                final List<dynamic> allTables = tablesRes['data'] ?? [];

                                if (!context.mounted) return;

                                int? selectedId = preSelectedId;

                                final confirmedTableId = await showDialog<int>(
                                  context: context,
                                  builder: (context) {
                                    return StatefulBuilder(
                                      builder: (context, setStateDialog) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.charcoal,
                                          title: Text(preSelectedId != null ? 'Konfirmasi Meja Reservasi' : 'Pilih Meja Walk-in',
                                              style: const TextStyle(color: AppColors.caramelGold)),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    preSelectedId != null 
                                                      ? 'Anda punya reservasi di Meja $preSelectedId. Silakan konfirmasi atau pilih meja lain:'
                                                      : 'Silakan pilih meja kosong (Hijau) yang sedang Anda tempati:',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  JkTableGrid(
                                                    tables: allTables.cast<Map<String, dynamic>>(),
                                                    selectedTableId: selectedId,
                                                    onTableSelected: (id) {
                                                      setStateDialog(() => selectedId = id);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('BATAL', style: TextStyle(color: Colors.white54)),
                                            ),
                                            TextButton(
                                              onPressed: selectedId == null 
                                                ? null 
                                                : () => Navigator.pop(context, selectedId),
                                              child: Text('KONFIRMASI', 
                                                style: TextStyle(
                                                  color: selectedId == null ? Colors.white24 : AppColors.caramelGold
                                                )
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );

                                if (confirmedTableId != null) {
                                  currentTableId = confirmedTableId;
                                  cartProvider.setTableId(currentTableId);
                                } else {
                                  return; // Batal checkout
                                }
                            }
                          }
                          
                          if (!context.mounted || currentTableId == null) return;
                          
                          final orderData = await repo.createOrder(
                            currentTableId, // tableId from input
                            1, // customerId (will be overwritten by JWT in backend)
                            cartProvider.totalAmount, 
                            'midtrans', // paymentMethod
                            items,
                          );
                          
                          if (!context.mounted) return;
                          cartProvider.clearCart();

                          // Navigate to Midtrans payment screen
                          final snapRedirectUrl = orderData['snap_redirect_url'] as String?;
                          final orderId = (orderData['order'] as Map?)?['id'] as int? ?? 0;

                          if (snapRedirectUrl != null && snapRedirectUrl.isNotEmpty) {
                            if (context.mounted) {
                              if (kIsWeb) {
                                // Web: buka Midtrans di tab baru dulu
                                final uri = Uri.parse(snapRedirectUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                              if (!context.mounted) return;
                              // Lalu navigate ke screen konfirmasi
                              await Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MidtransPaymentScreen(
                                    snapUrl: snapRedirectUrl,
                                    orderId: orderId,
                                    onSuccess: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (_) => DigitalReceiptScreen(orderId: orderId)),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order berhasil dibuat!')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to place order: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.caramelGold),
      ),
    );
  }
}
