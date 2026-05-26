import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/jk_primary_button.dart';
import 'order_tracking_screen.dart';
import 'home_screen.dart';

class DigitalReceiptScreen extends StatefulWidget {
  final int orderId;

  const DigitalReceiptScreen({super.key, required this.orderId});

  @override
  State<DigitalReceiptScreen> createState() => _DigitalReceiptScreenState();
}

class _DigitalReceiptScreenState extends State<DigitalReceiptScreen> {
  late OrderRepository _orderRepo;
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository(apiClient: ApiClient());
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final order = await _orderRepo.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: const Text('STRUK PEMBAYARAN'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Gagal memuat struk pesanan', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchOrderDetails,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Kartu Struk Termal Kasir (Mirip Struk Fisik Kasir)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9), // Kertas struk kasir putih terang
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontFamily: 'Courier', // Gaya font monospace kasir
                            color: Color(0xFF333333),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Header Toko
                              const Text(
                                'Jabat Kopi',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 4),
                              const Text('Bugel, Karawaci / 0877-8008-6677', style: TextStyle(fontSize: 11)),
                              const Text('Jl. Aria Wangsakara No.2, Bugel', style: TextStyle(fontSize: 10)),
                              const Text('Karawaci, Tangerang, Banten 15114', style: TextStyle(fontSize: 10)),
                              const Text('NPWP : 01.336.238.9-054.000', style: TextStyle(fontSize: 11)),
                              const SizedBox(height: 12),
                              const _DashedDivider(),
                              const SizedBox(height: 8),

                              // Info Bon & Kasir
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Bon JK-ORDER-${_order!.id}'),
                                  Text('Meja: ${_order!.tableId}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Metode: ${_order!.paymentMethod.toUpperCase()}',
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Kasir: ${_order!.staffName.toUpperCase()}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const _DashedDivider(),
                              const SizedBox(height: 12),

                              // Rincian Item Belanja
                              if (_order!.items.isEmpty)
                                const Text('Menu Paket Lengkap')
                              else
                                ..._order!.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.menuName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('   ${item.qty} x ${NumberFormat('#,###').format(item.price)}'),
                                            Text(NumberFormat('#,###').format(item.qty * item.price)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                              const SizedBox(height: 8),
                              const _DashedDivider(),
                              const SizedBox(height: 12),

                              // Perhitungan Total
                              _buildReceiptRow('Total Item', '${_order!.items.fold<int>(0, (sum, item) => sum + item.qty)}'),
                              _buildReceiptRow('Subtotal', NumberFormat('#,###').format(_order!.totalAmount / 1.1)),
                              _buildReceiptRow('PPN (10%)', NumberFormat('#,###').format(_order!.totalAmount - (_order!.totalAmount / 1.1))),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL BELANJA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    'Rp ${NumberFormat('#,###').format(_order!.totalAmount)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TUNAI / DIGITAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Rp ${NumberFormat('#,###').format(_order!.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('KEMBALIAN'),
                                  Text('Rp 0'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const _DashedDivider(),
                              const SizedBox(height: 12),

                              // Tanggal & Footer Member
                              Text('Tgl. ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())} V.2026.3.0', style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 8),
                              Text('MEMBER : ${_order!.customerName.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const _DashedDivider(),
                              const SizedBox(height: 12),

                              // Catatan Pesan
                              const Text('STRUK INI ADALAH BUKTI SAH PEMBELIAN', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              const Text('HARAP DITUNJUKKAN KEPADA BARISTA SAAT PENGAMBILAN', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              const SizedBox(height: 12),
                              const Text('KRITIK&SARAN: 0877-8008-6677', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              const Text('SMS/WA: 0877-8008-6677', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Tombol Aksi
                      JkPrimaryButton(
                        label: 'LIHAT STATUS PESANAN',
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: _order!.id)),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('KEMBALI KE BERANDA', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (dashWidth * 2)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black38),
              ),
            );
          }),
        );
      },
    );
  }
}
