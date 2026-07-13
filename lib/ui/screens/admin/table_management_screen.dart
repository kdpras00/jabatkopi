import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_logout_button.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  List<dynamic> _tables = [];
  bool _isLoading = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchTables();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchTables());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTables() async {
    if (_tables.isEmpty) setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('/admin/tables');
      if (mounted) {
        setState(() {
          _tables = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTableStatus(int tableId, String newStatus) async {
    try {
      await ApiClient().put('/admin/tables/$tableId/status', {'status': newStatus});
      _fetchTables();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update meja: $e')),
        );
      }
    }
  }

  void _showAddTableBottomSheet() {
    FocusManager.instance.primaryFocus?.unfocus();

    final int nextNumber = _tables.length + 1;
    final qrController = TextEditingController(text: 'JK-TABLE-$nextNumber');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TAMBAH MEJA BARU',
                  style: TextStyle(
                    color: AppColors.caramelGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Meja baru akan otomatis berstatus Tersedia.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Icon preview
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.caramelGold.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant, color: AppColors.caramelGold, size: 40),
                        SizedBox(height: 4),
                        Text('MEJA', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Table identifier field
                _buildTextField('Nomor Meja', qrController, Icons.tag),
                const SizedBox(height: 8),
                const Text(
                  'Nomor atau kode unik untuk identifikasi meja (misal: JK-TABLE-7)',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 32),

                JkPrimaryButton(
                  label: 'Tambah Meja',
                  isLoading: isSubmitting,
                  onPressed: () async {
                    if (qrController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode referensi tidak boleh kosong')),
                      );
                      return;
                    }
                    setModalState(() => isSubmitting = true);
                    try {
                      await ApiClient().post('/admin/tables', {
                        'qr_code_ref': qrController.text.trim(),
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _fetchTables();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Meja berhasil ditambahkan!')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal tambah meja: $e')),
                      );
                    } finally {
                      setModalState(() => isSubmitting = false);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.caramelGold, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    return status == 'available' ? Colors.greenAccent : Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tables'),
        actions: const [
          JkLogoutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTableBottomSheet,
        backgroundColor: AppColors.caramelGold,
        child: const Icon(Icons.add, color: AppColors.charcoal),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _tables.isEmpty
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary row
                      Row(
                        children: [
                          _buildSummaryCard('Total Meja', '${_tables.length}', Icons.table_restaurant, AppColors.caramelGold),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            'Tersedia',
                            '${_tables.where((t) => t['status'] == 'available').length}',
                            Icons.check_circle,
                            Colors.greenAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            'Terisi',
                            '${_tables.where((t) => t['status'] == 'occupied').length}',
                            Icons.cancel,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Daftar Meja',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _tables.length,
                          itemBuilder: (context, index) {
                            final table = _tables[index];
                            final status = table['status'] as String? ?? 'available';
                            final tableId = table['id'] as int;
                            final qrRef = table['qr_code_ref'] as String? ?? '';
                            final isAvailable = status == 'available';

                            return JkGlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(Icons.table_restaurant, color: _statusColor(status), size: 32),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isAvailable ? Icons.check_circle : Icons.cancel,
                                              color: _statusColor(status),
                                              size: 10,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Meja $tableId',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(qrRef, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () => _updateTableStatus(tableId, isAvailable ? 'occupied' : 'available'),
                                      style: TextButton.styleFrom(
                                        backgroundColor: isAvailable
                                            ? Colors.redAccent
                                            : Colors.green,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        isAvailable ? 'Set Terisi' : 'Set Tersedia',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: JkGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.table_restaurant, size: 80, color: AppColors.caramelGold.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text('Belum Ada Data Meja', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Tekan tombol + untuk menambah meja baru.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
