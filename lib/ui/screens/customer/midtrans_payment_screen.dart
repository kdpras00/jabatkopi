import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/theme/app_colors.dart';

// Mobile-only: conditionally import WebViewController
import 'midtrans_payment_screen_mobile.dart'
    if (dart.library.html) 'midtrans_payment_screen_web.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String snapUrl;
  final int orderId;
  final VoidCallback? onSuccess;

  const MidtransPaymentScreen({
    super.key,
    required this.snapUrl,
    required this.orderId,
    this.onSuccess,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  late final OrderRepository _orderRepo;
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _orderRepo = OrderRepository(apiClient: ApiClient());
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll backend every 3 seconds to check if Midtrans webhook marked status as 'processing' or 'completed'
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isChecking || !mounted || widget.orderId <= 0) return;
      _isChecking = true;
      try {
        final order = await _orderRepo.getOrderDetails(widget.orderId);
        if (!mounted) return;
        
        if (order.status == 'processing' || order.status == 'completed' || order.status == 'preparing') {
          _pollingTimer?.cancel();
          if (widget.onSuccess != null) {
            widget.onSuccess!.call();
          } else if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (_) {
        // Silently ignore polling errors
      } finally {
        _isChecking = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web: tampilkan konfirmasi manual + status menunggu otomatis karena WebView tidak tersedia di web Flutter
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          title: const Text('PEMBAYARAN'),
          centerTitle: true,
          backgroundColor: AppColors.darkGrey,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.caramelGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment, size: 64, color: AppColors.caramelGold),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Menunggu Pembayaran...',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Halaman pembayaran telah dibuka di tab/jendela baru.\nSistem sedang mendeteksi pembayaran Anda secara otomatis.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.caramelGold),
                const SizedBox(height: 32),

                TextButton(
                  onPressed: () {
                    _pollingTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text('Batalkan', style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile: gunakan native WebView + polling otomatis di latar belakang
    return MidtransWebViewPage(
      snapUrl: widget.snapUrl,
      orderId: widget.orderId,
      onSuccess: () {
        _pollingTimer?.cancel();
        widget.onSuccess?.call();
      },
    );
  }
}
