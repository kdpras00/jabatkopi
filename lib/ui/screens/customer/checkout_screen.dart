import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import 'payment_instruction_screen.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  final int tableId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;

  const CustomerCheckoutScreen({
    super.key,
    required this.tableId,
    required this.items,
    required this.totalAmount,
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
      'title': 'QR Code',
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
        1, // Customer ID (will be overwritten by JWT in backend OrderHandler)
        widget.totalAmount,
        _selectedMethod!,
        widget.items,
      );

      final orderId = (orderData['order'] as Map?)?['id'] as int? ?? 0;
      final paymentDetails = orderData['payment_details'] as Map<String, dynamic>? ?? {};

      // Clear cart provider upon successful order creation
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clearCart();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentInstructionScreen(
              orderId: orderId,
              paymentMethod: _selectedMethod!,
              paymentDetails: paymentDetails,
              totalAmount: widget.totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyError = 'Gagal memproses pesanan Anda. Silakan coba beberapa saat lagi.';
        final errStr = e.toString();
        if (errStr.contains('tidak mencukupi') || errStr.contains('stok') || errStr.contains('Stok')) {
          userFriendlyError = errStr.replaceAll('Exception: ', '').replaceAll('Exception', '');
        } else if (errStr.contains('SocketException') || errStr.contains('ClientException') || errStr.contains('XMLHttpRequest')) {
          userFriendlyError = 'Koneksi internet bermasalah. Silakan periksa kembali jaringan Anda dan coba lagi.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError),
            backgroundColor: Colors.red,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
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
                          color: AppColors.glassBorder,
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
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        'Rp ${widget.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
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
