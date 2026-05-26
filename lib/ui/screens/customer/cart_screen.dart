import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import 'checkout_screen.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  /// Cek reservasi aktif customer hari ini (status checked_in saja)
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
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'Keranjang Anda kosong',
                    style: TextStyle(fontSize: 18, color: AppColors.softCream),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan menu favorit Anda',
                    style: TextStyle(fontSize: 13, color: Colors.white38),
                  ),
                ],
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
                                  Text(item.menu.category,
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                                  onTap: () => cartProvider.updateQuantity(item.menu.id, item.quantity - 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        const Text('Subtotal', style: TextStyle(color: Colors.white70)),
                        Text('Rp ${cartProvider.subtotal.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (10%)', style: TextStyle(color: Colors.white70)),
                        Text('Rp ${cartProvider.tax.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.glassBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Rp ${cartProvider.totalAmount.toInt()}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    JkPrimaryButton(
                      label: 'LANJUT CHECKOUT',
                      onPressed: () async {
                        try {
                          final items = cartProvider.items.map((item) => {
                            'menu_id': item.menu.id,
                            'qty': item.quantity,
                            'subtotal': item.totalPrice,
                          }).toList();

                          int? currentTableId = cartProvider.tableId;

                          if (currentTableId == null) {
                            // 1. Cek apakah customer sudah check-in reservasi hari ini
                            final checkedInRes = await _getCheckedInReservation();

                            if (checkedInRes != null) {
                              // Sudah check-in → pakai meja dari reservasi secara otomatis
                              final tId = checkedInRes['table_id'] as int;
                              currentTableId = tId;
                              cartProvider.setTableId(tId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Check-in aktif. Pesanan dikirim ke ${checkedInRes['table_ref']}.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              currentTableId = 0;
                            }
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerCheckoutScreen(
                                tableId: currentTableId ?? 0,
                                items: items,
                                totalAmount: cartProvider.totalAmount,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            String msg = 'Gagal melanjutkan ke checkout. Silakan coba lagi.';
                            final err = e.toString();
                            if (err.contains('SocketException') || err.contains('ClientException') || err.contains('XMLHttpRequest')) {
                              msg = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
