import 'package:flutter/material.dart';

// Stub for web platform — MidtransWebViewPage tidak digunakan di web
class MidtransWebViewPage extends StatelessWidget {
  final String snapUrl;
  final int orderId;
  final VoidCallback? onSuccess;

  const MidtransWebViewPage({
    super.key,
    required this.snapUrl,
    required this.orderId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
