import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import 'digital_receipt_screen.dart';

class PaymentInstructionScreen extends StatefulWidget {
  final int orderId;
  final String paymentMethod;
  final Map<String, dynamic> paymentDetails;
  final double totalAmount;
  final String? snapUrl;

  const PaymentInstructionScreen({
    super.key,
    required this.orderId,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.totalAmount,
    this.snapUrl,
  });

  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  bool _isLoading = false;
  late Map<String, dynamic> _currentDetails;

  @override
  void initState() {
    super.initState();
    _currentDetails = widget.paymentDetails;
  }

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = OrderRepository(apiClient: ApiClient());
      final details = await repo.getOrderDetails(widget.orderId);

      if (details.status == 'processing' || details.status == 'completed' || details.status == 'preparing' || details.status == 'ready') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DigitalReceiptScreen(orderId: widget.orderId),
            ),
          );
        }
        return;
      }

      // If still pending, refresh the payment details in case they loaded later
      final rawDetailsRes = await ApiClient().get('/orders/${widget.orderId}/details');
      final newDetails = rawDetailsRes['data']?['payment_details'] as Map<String, dynamic>?;
      if (newDetails != null && mounted) {
        setState(() {
          _currentDetails = newDetails;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran belum diterima. Silakan selesaikan pembayaran Anda.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyError = 'Gagal mengecek status pembayaran. Silakan coba beberapa saat lagi.';
        final errStr = e.toString();
        if (errStr.contains('SocketException') || errStr.contains('ClientException') || errStr.contains('XMLHttpRequest')) {
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getMethodName() {
    switch (widget.paymentMethod) {
      case 'bank_transfer_bca':
        return 'Virtual Account BCA';
      case 'bank_transfer_bni':
        return 'Virtual Account BNI';
      case 'bank_transfer_bri':
        return 'Virtual Account BRI';
      case 'bank_transfer_permata':
        return 'Virtual Account Permata';
      case 'bank_transfer_mandiri':
        return 'Mandiri Bill Payment (E-Channel)';
      case 'cstore_alfamart':
        return 'Gerai Retail Alfamart';
      case 'cstore_indomaret':
        return 'Gerai Retail Indomaret';
      case 'gopay':
        return 'GoPay';
      case 'shopeepay':
        return 'ShopeePay';
      case 'qris':
        return 'QRIS';
      default:
        return 'Pembayaran Online';
    }
  }

  List<String> _getInstructions() {
    switch (widget.paymentMethod) {
      case 'bank_transfer_bca':
      case 'bank_transfer_bni':
      case 'bank_transfer_bri':
      case 'bank_transfer_permata':
        return [
          'Salin nomor Virtual Account yang tertera di atas.',
          'Buka aplikasi mobile banking Anda atau kunjungi ATM terdekat.',
          'Pilih menu Transaksi Lainnya > Transfer > Ke Rekening Virtual Account.',
          'Masukkan nomor Virtual Account yang telah disalin.',
          'Periksa detail pembayaran, pastikan total tagihan sesuai.',
          'Masukkan PIN Anda dan selesaikan transaksi.'
        ];
      case 'bank_transfer_mandiri':
        return [
          'Salin Kode Biller (${_currentDetails['biller_code'] ?? '89898'}) dan Bill Key/Nomor Mandiri VA.',
          'Masuk ke Mandiri Online / Livin\' by Mandiri.',
          'Pilih menu "Bayar" > Cari/Pilih "Multi Payment".',
          'Masukkan Kode Biller, lalu masukkan Bill Key/Nomor Mandiri VA.',
          'Konfirmasi transaksi Anda. Pastikan nominal pembayaran sudah tepat.',
          'Masukkan PIN transaksi Anda untuk menyelesaikan.'
        ];
      case 'cstore_alfamart':
        return [
          'Salin Kode Pembayaran yang tertera di atas.',
          'Kunjungi gerai Alfamart terdekat.',
          'Katakan kepada kasir bahwa Anda ingin melakukan pembayaran Midtrans/Jabat Kopi.',
          'Tunjukkan atau sebutkan Kode Pembayaran kepada kasir.',
          'Bayar nominal uang sesuai tagihan kepada kasir.',
          'Simpan struk bukti pembayaran dari Alfamart.'
        ];
      case 'cstore_indomaret':
        return [
          'Salin Kode Pembayaran yang tertera di atas.',
          'Kunjungi gerai Indomaret terdekat.',
          'Katakan kepada kasir bahwa Anda ingin melakukan pembayaran Midtrans/Jabat Kopi.',
          'Tunjukkan atau sebutkan Kode Pembayaran kepada kasir.',
          'Bayar nominal uang sesuai tagihan kepada kasir.',
          'Simpan struk bukti pembayaran dari Indomaret.'
        ];
      case 'qris':
        return [
          'Simpan atau screenshot kode QRIS yang ditampilkan di atas.',
          'Buka aplikasi e-Wallet pilihan Anda (DANA, LinkAja, OVO, GoPay, BCA Mobile, dll).',
          'Pilih menu "Scan" atau "Bayar" di aplikasi tersebut.',
          'Unggah gambar QRIS dari galeri atau pindai langsung.',
          'Konfirmasi nominal pembayaran yang otomatis muncul.',
          'Masukkan PIN e-Wallet Anda dan selesaikan pembayaran.'
        ];
      case 'gopay':
        return [
          'Pindai kode QR di atas menggunakan aplikasi Gojek Anda atau klik tombol "Buka GoPay" jika Anda berada di perangkat mobile.',
          'Periksa nominal belanja Anda di aplikasi Gojek.',
          'Masukkan PIN GoPay Anda untuk menyelesaikan transaksi.'
        ];
      case 'shopeepay':
        return [
          'Klik tombol "Buka ShopeePay" di bawah.',
          'Aplikasi Shopee akan otomatis terbuka dan mengarahkan Anda ke halaman pembayaran ShopeePay.',
          'Periksa nominal belanja Anda, lalu tekan Bayar.',
          'Masukkan PIN ShopeePay Anda untuk menyelesaikan transaksi.'
        ];
      default:
        return [
          'Ikuti petunjuk pembayaran yang diberikan oleh gateway pembayaran.',
          'Pastikan nominal transfer sesuai dengan total tagihan.',
          'Setelah sukses, simpan bukti pembayaran.'
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.paymentMethod;
    final vaNumber = _currentDetails['va_number'] as String?;
    final billKey = _currentDetails['bill_key'] as String?;
    final billerCode = _currentDetails['biller_code'] as String?;
    final paymentCode = _currentDetails['payment_code'] as String?;
    final qrUrl = _currentDetails['qr_url'] as String?;
    final deeplinkUrl = _currentDetails['deeplink_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruksi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total amount card
            JkGlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'TOTAL TAGIHAN',
                    style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${widget.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: const TextStyle(
                      color: AppColors.caramelGold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Metode: ${_getMethodName()}',
                    style: const TextStyle(color: AppColors.softCream, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Credentials card (Dynamic depending on method)
            JkGlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Bank Transfer (BCA, BNI, BRI, Permata)
                  if ((method == 'bank_transfer_bca' || method == 'bank_transfer_bni' || method == 'bank_transfer_bri' || method == 'bank_transfer_permata') && vaNumber != null) ...[
                    const Text(
                      'NOMOR VIRTUAL ACCOUNT',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SelectableText(
                              vaNumber,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softCream,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.caramelGold),
                          onPressed: () => _copyToClipboard(vaNumber, 'Nomor VA'),
                        ),
                      ],
                    ),
                  ],

                  // 2. Mandiri E-Channel
                  if (method == 'bank_transfer_mandiri' && billKey != null && billerCode != null) ...[
                    const Text(
                      'KODE BILLER',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SelectableText(
                              billerCode,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softCream,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.caramelGold, size: 20),
                          onPressed: () => _copyToClipboard(billerCode, 'Kode Biller'),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.borderGrey),
                    const Text(
                      'BILL KEY / NOMOR VA',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SelectableText(
                              billKey,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softCream,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.caramelGold, size: 20),
                          onPressed: () => _copyToClipboard(billKey, 'Bill Key'),
                        ),
                      ],
                    ),
                  ],

                  // 3. Alfamart & Indomaret
                  if ((method == 'cstore_alfamart' || method == 'cstore_indomaret') && paymentCode != null) ...[
                    Text(
                      method == 'cstore_alfamart' ? 'KODE PEMBAYARAN ALFAMART' : 'KODE PEMBAYARAN INDOMARET',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SelectableText(
                              paymentCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softCream,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.caramelGold),
                          onPressed: () => _copyToClipboard(paymentCode, 'Kode Pembayaran'),
                        ),
                      ],
                    ),
                  ],

                  // 4. QRIS / GoPay QR Code
                  if ((method == 'qris' || method == 'gopay') && qrUrl != null) ...[
                    Text(
                      method == 'gopay' ? 'PINDAI KODE GOPAY DI BAWAH' : 'PINDAI KODE QRIS DI BAWAH',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.network(
                        qrUrl,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 220,
                            height: 220,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text(
                                'Gagal memuat kode QR.\nSilakan coba lagi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      method == 'gopay'
                          ? 'Pindai kode QR di atas menggunakan aplikasi Gojek Anda.'
                          : 'Mendukung pembayaran via ShopeePay, DANA, GoPay, OVO, LinkAja, & Mobile Banking.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],

                  // 5. GoPay / ShopeePay Deeplink
                  if ((method == 'shopeepay' || method == 'gopay') && deeplinkUrl != null) ...[
                    Text(
                      method == 'gopay' ? 'GOPAY DEEPLINK' : 'SHOPEEPAY DEEPLINK',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: method == 'gopay' ? const Color(0xFF00AED6) : const Color(0xFFEE4D2D), // GoPay Blue or Shopee Orange
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(method == 'gopay' ? 'Buka GoPay' : 'Buka ShopeePay'),
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(deeplinkUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          // Ignore
                        }
                      },
                    ),
                  ],

                  // 6. Midtrans Snap URL Fallback
                  if (widget.snapUrl != null && widget.snapUrl!.isNotEmpty) ...[
                    const Text(
                      'LINK PEMBAYARAN MIDTRANS',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramelGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: const Icon(Icons.payment),
                      label: const Text('BUKA HALAMAN PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(widget.snapUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          // Ignore
                        }
                      },
                    ),
                  ]
                  // Loading placeholder if credentials not yet retrieved and no snap url
                  else if (vaNumber == null && billKey == null && paymentCode == null && qrUrl == null && deeplinkUrl == null) ...[
                    const CircularProgressIndicator(color: AppColors.caramelGold),
                    const SizedBox(height: 12),
                    const Text(
                      'Sedang mengambil data pembayaran dari Midtrans...',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instruction steps card
            JkGlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARA PEMBAYARAN',
                    style: TextStyle(
                      color: AppColors.caramelGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._getInstructions().asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.caramelGold,
                            ),
                            child: Center(
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                color: AppColors.softCream,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Actions
            JkPrimaryButton(
              label: 'SAYA SUDAH BAYAR',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _checkPaymentStatus,
            ),
          ],
        ),
      ),
    );
  }
}
