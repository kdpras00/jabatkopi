import 'package:flutter/material.dart';

class QrMockScreen extends StatefulWidget {
  const QrMockScreen({super.key});

  @override
  State<QrMockScreen> createState() => _QrMockScreenState();
}

class _QrMockScreenState extends State<QrMockScreen> {
  final _tableIdController = TextEditingController();

  void _submitTableId() {
    final tableId = _tableIdController.text;
    if (tableId.isNotEmpty) {
      // TODO: Navigate to Menu Screen with this Table ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulated QR Scan for Table ID: $tableId')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code (Mock)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              'Masukkan Table ID secara manual (Simulasi QR Scanner):',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tableIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Table ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.table_restaurant),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitTableId,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Simulasikan Scan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tableIdController.dispose();
    super.dispose();
  }
}
