import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import 'digital_receipt_screen.dart';
import 'home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderRepository _orderRepo;
  OrderModel? _order;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository(apiClient: ApiClient());
    _fetchOrder();
    // Polling berkala ke backend Go GORM setiap 3 detik untuk pembaruan real-time
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchOrder());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    try {
      final order = await _orderRepo.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && _order == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: const Text('STATUS PESANAN'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _order == null
              ? const Center(child: Text('Pesanan tidak ditemukan', style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.coffee, size: 80, color: AppColors.caramelGold),
                      const SizedBox(height: 16),
                      Text(
                        'Pesanan #JK-ORDER-${widget.orderId}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text('Meja ${_order!.tableId}', style: const TextStyle(color: AppColors.caramelGold, fontSize: 16)),
                      const SizedBox(height: 40),
                      
                      _buildStatusStep(
                        context,
                        title: 'Pesanan Diterima',
                        subtitle: 'Pesanan Anda telah masuk ke sistem',
                        isCompleted: true,
                        isActive: _order!.status == 'pending' || _order!.status == 'processing',
                      ),
                      _buildStatusStep(
                        context,
                        title: 'Sedang Disiapkan',
                        subtitle: 'Barista sedang meracik kopi Anda',
                        isCompleted: _order!.status == 'preparing' || _order!.status == 'ready' || _order!.status == 'completed',
                        isActive: _order!.status == 'preparing',
                      ),
                      _buildStatusStep(
                        context,
                        title: 'Siap Diambil',
                        subtitle: 'Ambil pesanan Anda di meja kasir/barista',
                        isCompleted: _order!.status == 'ready' || _order!.status == 'completed',
                        isActive: _order!.status == 'ready',
                      ),
                      _buildStatusStep(
                        context,
                        title: 'Selesai',
                        subtitle: 'Selamat menikmati kopi Anda!',
                        isCompleted: _order!.status == 'completed',
                        isActive: _order!.status == 'completed',
                      ),
                      const SizedBox(height: 40),

                      JkGlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(color: Colors.white54, fontSize: 16)),
                            Text(
                              'Rp ${_order!.totalAmount.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.caramelGold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      JkPrimaryButton(
                        label: 'LIHAT STRUK DIGITAL',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DigitalReceiptScreen(orderId: widget.orderId)),
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

  Widget _buildStatusStep(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.caramelGold : Colors.transparent,
                  border: Border.all(color: AppColors.caramelGold, width: 2),
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: AppColors.charcoal)
                    : null,
              ),
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? AppColors.caramelGold : AppColors.glassBorder,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? AppColors.caramelGold : (isCompleted ? Colors.white : AppColors.softCream),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.softCream.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
