import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_virtual_pager_disc.dart';
import 'digital_receipt_screen.dart';
import 'home_screen.dart';
import '../../../core/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/js_helper.dart'
    if (dart.library.js) '../../../core/utils/js_helper_web.dart' as jsh;

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
  bool _isCancelling = false;

  // Virtual Pager state variables
  bool _buzzerAllowed = false;
  bool _buzzerSilenced = false;
  bool _buzzerActive = false;
  Timer? _buzzerTimer;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository(apiClient: ApiClient());
    _fetchOrder();
    // Polling berkala ke backend Go GORM setiap 10 detik untuk pembaruan real-time
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchOrder());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _buzzerTimer?.cancel();
    super.dispose();
  }

  void _startBuzzerLoop() {
    if (_buzzerTimer != null || _buzzerSilenced || !_buzzerAllowed) return;
    
    setState(() {
      _buzzerActive = true;
    });

    // Ring sound and vibrate immediately once
    HapticFeedback.vibrate();
    jsh.playWebBeep();

    _buzzerTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      HapticFeedback.vibrate();
      jsh.playWebBeep();
    });
  }

  void _stopBuzzer() {
    _buzzerTimer?.cancel();
    _buzzerTimer = null;
    setState(() {
      _buzzerActive = false;
      _buzzerSilenced = true;
    });
  }

  Future<void> _checkAndRequestBuzzerPermission() async {
    if (_buzzerAllowed || _buzzerSilenced) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: AppColors.caramelGold),
            const SizedBox(width: 8),
            const Text('Notifikasi Pager Antrean', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Aktifkan getaran dan suara pager agar Anda tahu persis kapan kopi siap diambil di meja barista?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('LEWATI', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('AKTIFKAN', style: TextStyle(color: AppColors.caramelGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (mounted && result == true) {
      setState(() {
        _buzzerAllowed = true;
      });
      if (_order?.status == 'ready') {
        _startBuzzerLoop();
      }
    }
  }

  Future<void> _fetchOrder() async {
    try {
      final order = await _orderRepo.getOrderDetails(widget.orderId);
      if (mounted) {
        final firstLoad = _order == null;
        setState(() {
          _order = order;
          _isLoading = false;
        });

        // Trigger pager alarm if status is ready
        if (order.status == 'ready' && !_buzzerSilenced) {
          if (_buzzerAllowed) {
            _startBuzzerLoop();
          } else if (firstLoad) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndRequestBuzzerPermission();
            });
          }
        } else if (order.status == 'completed' || order.status == 'cancelled') {
          _stopBuzzer();
        }

        if (firstLoad && order.status != 'ready') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndRequestBuzzerPermission();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_order == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil data. Periksa koneksi internet Anda.')),
          );
        }
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text('Batalkan Pesanan?', style: TextStyle(color: AppColors.caramelGold)),
        content: const Text('Pesanan yang dibatalkan tidak dapat dikembalikan.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('TIDAK', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YA, BATALKAN', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isCancelling = true);
    try {
      await _orderRepo.cancelOrder(widget.orderId);
      // clear cart tableId if any
      if (mounted) {
        context.read<CartProvider>().clearTableId();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibatalkan.'), backgroundColor: Colors.green),
        );
        await _fetchOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _order?.status == 'cancelled';
    final isReady = _order?.status == 'ready' && !_buzzerSilenced;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: Text(isReady ? 'Panggilan Antrean' : 'Status Pesanan'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey,
        actions: [
          if (_order?.status == 'pending')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _isCancelling ? null : _cancelOrder,
                child: _isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      )
                    : const Text(
                        'Batalkan',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _order == null
              ? const Center(child: Text('Pesanan tidak ditemukan', style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (isReady) ...[
                        JkVirtualPagerDisc(
                          isActive: _buzzerActive,
                          onSilence: _stopBuzzer,
                        ),
                      ] else ...[
                        Icon(
                          isCancelled ? Icons.cancel_outlined : Icons.coffee,
                          size: 80,
                          color: isCancelled ? Colors.redAccent : AppColors.caramelGold,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pesanan #JK-ORDER-${widget.orderId}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        if (isCancelled)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                            ),
                            child: const Text('DIBATALKAN', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
                          )
                        else
                          Text('Meja ${_order!.tableId ?? 'Belum Ditentukan'}', style: const TextStyle(color: AppColors.caramelGold, fontSize: 16)),
                        const SizedBox(height: 40),

                        if (!isCancelled) ...[
                          _buildStatusStep(
                            context,
                            title: 'Pesanan Diterima',
                            subtitle: 'Pesanan Anda telah masuk ke sistem',
                            isCompleted: _order!.status != 'cancelled',
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
                        ],
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
                          label: 'Lihat Struk Digital',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DigitalReceiptScreen(orderId: widget.orderId)),
                            );
                          },
                        ),
                      ],
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
                color: isCompleted ? AppColors.caramelGold : AppColors.borderGrey,
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
                    color: AppColors.softCream.withValues(alpha: 0.6),
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
