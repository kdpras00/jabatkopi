import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import 'payment_instruction_screen.dart';
import 'order_tracking_screen.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  final int? tableId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String orderType;
  final String? pickupTime;

  const CustomerCheckoutScreen({
    super.key,
    required this.tableId,
    required this.items,
    required this.totalAmount,
    this.orderType = 'dine_in',
    this.pickupTime,
  });

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  String? _selectedMethod;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentCategories = [
    {
      'title': 'Bank Transfer',
      'methods': [
        {
          'id': 'bank_transfer_bca',
          'name': 'Bank BCA',
          'logo': 'assets/images/bca.png',
        },
        {
          'id': 'bank_transfer_bni',
          'name': 'Bank BNI',
          'logo': 'assets/images/bni.png',
        },
        {
          'id': 'bank_transfer_bri',
          'name': 'Bank BRI',
          'logo': 'assets/images/bri.png',
        },
        {
          'id': 'bank_transfer_mandiri',
          'name': 'Bank MANDIRI',
          'logo': 'assets/images/mandiri.png',
        },
        {
          'id': 'bank_transfer_permata',
          'name': 'Bank PERMATA',
          'logo': 'assets/images/permata.png',
        },
      ]
    },
    {
      'title': 'Outlet Ritels',
      'fee': 'Rp5.000',
      'methods': [
        {
          'id': 'cstore_alfamart',
          'name': 'Alfamart',
          'logo': 'assets/images/alfamart.png',
        },
        {
          'id': 'cstore_indomaret',
          'name': 'Indomaret',
          'logo': 'assets/images/indomaret.png',
        }
      ]
    },
    {
      'title': 'e-Wallet',
      'fee': 'Rp250',
      'methods': [
        {
          'id': 'gopay',
          'name': 'GoPay',
          'logo': 'assets/images/gopay.png',
        },
        {
          'id': 'shopeepay',
          'name': 'ShopeePay',
          'logo': 'assets/images/shopeepay.png',
        },
      ]
    },
    {
      'title': 'QRIS',
      'fee': 'Rp250',
      'methods': [
        {
          'id': 'qris',
          'name': 'QRIS',
          'logo': 'assets/images/qris.png',
        }
      ]
    }
  ];

  Future<void> _handlePayment() async {
    FocusScope.of(context).unfocus();
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih metode pembayaran terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = OrderRepository(apiClient: ApiClient());
      final orderData = await repo.createOrder(
        widget.tableId,
        _selectedMethod!,
        widget.items,
        orderType: widget.orderType,
        pickupTime: widget.pickupTime,
      );

      final orderMap = orderData['order'] as Map?;
      final orderId = int.tryParse(orderMap?['id']?.toString() ?? '0') ?? 0;
      final rawPaymentDetails = orderData['payment_details'];
      final paymentDetails = (rawPaymentDetails is Map)
          ? Map<String, dynamic>.from(rawPaymentDetails)
          : <String, dynamic>{};

      // Clear cart provider upon successful order creation
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clearCart();
      }

      if (mounted) {
        if (_selectedMethod == 'cash') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: orderId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentInstructionScreen(
                orderId: orderId,
                paymentMethod: _selectedMethod!,
                paymentDetails: paymentDetails,
                totalAmount: widget.totalAmount,
                snapUrl: orderData['snap_redirect_url'] as String?,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // DEBUG: Tampilkan error asli untuk troubleshooting
        final errStr = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: $errStr'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paymentCategories.length,
              itemBuilder: (context, catIndex) {
                final category = _paymentCategories[catIndex];
                final methods = category['methods'] as List<dynamic>;
                final fee = category['fee'] as String?;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.softCream,
                            ),
                          ),
                          if (fee != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fee,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    JkGlassCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: methods.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: AppColors.borderGrey,
                        ),
                        itemBuilder: (context, methodIndex) {
                          final method = methods[methodIndex];
                          final id = method['id'] as String;
                          final name = method['name'] as String;
                          final logoUrl = method['logo'] as String;
                          final isSelected = _selectedMethod == id;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedMethod = id;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Logo container
                                  Container(
                                    width: 80,
                                    height: 40,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? AppColors.caramelGold : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset(
                                      logoUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            name.split(' ').last,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.softCream,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  // Radio button
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.caramelGold : Colors.white24,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(
                                              Icons.circle,
                                              size: 12,
                                              color: AppColors.caramelGold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Bottom Summary
          JkGlassCard(
            borderRadius: 0,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tampilkan info tipe pesanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tipe Pesanan',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        widget.orderType == 'dine_in'
                            ? '🍽️ Dine In${widget.tableId != null && widget.tableId != 0 ? " (Meja ${widget.tableId})" : ""}'
                            : widget.orderType == 'pickup'
                                ? '📦 Pickup${widget.pickupTime != null ? " jam ${widget.pickupTime}" : ""}'
                                : '🥡 Takeaway',
                        style: const TextStyle(color: AppColors.caramelGold, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya jasa',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        '-',
                        style: TextStyle(color: AppColors.softCream, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total pembayaran',
                        style: TextStyle(color: AppColors.softCream, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(widget.totalAmount.toInt())}',
                        style: const TextStyle(
                          color: AppColors.softCream,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  JkPrimaryButton(
                    label: 'BAYAR SEKARANG',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handlePayment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
