import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';

class ReservationVerificationScreen extends StatefulWidget {
  const ReservationVerificationScreen({super.key});

  @override
  State<ReservationVerificationScreen> createState() => _ReservationVerificationScreenState();
}

class _ReservationVerificationScreenState extends State<ReservationVerificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _reservations = [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
    // Auto-sync setiap 10 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchReservations());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReservations() async {
    // Hanya tampilkan loading spinner di fetch pertama
    if (_reservations.isEmpty) setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('/admin/reservations');
      if (mounted) {
        setState(() {
          _reservations = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmArrival(int id) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiClient().put('/admin/reservations/$id/arrive', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Status reservasi diupdate: Hadir/Tiba!'), backgroundColor: Colors.green),
        );
        _fetchReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  /// Stage 8: Tandai reservasi selesai → meja otomatis dibebaskan kembali
  Future<void> _completeReservation(int id) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiClient().put('/admin/reservations/$id/complete', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reservasi selesai! Meja kembali tersedia.'), backgroundColor: Colors.blueAccent),
        );
        _fetchReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter list if search text exists
    final query = _searchController.text.trim().toUpperCase();
    final filteredReservations = _reservations.where((res) {
      final bookingId = (res['booking_id'] ?? '').toString().toUpperCase();
      final tableId = (res['table_id'] ?? '').toString();
      return bookingId.contains(query) || tableId.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Reservasi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(24),
            child: JkGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari ID Meja / Booking (e.g. 1 atau JK-RES-2)...',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: AppColors.caramelGold),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Reservation List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
                : filteredReservations.isEmpty
                    ? Center(
                        child: Text(
                          query.isNotEmpty ? 'Meja / Booking ID tidak ditemukan' : 'Belum ada reservasi untuk hari ini',
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filteredReservations.length,
                        itemBuilder: (context, index) {
                          final res = filteredReservations[index];
                          final id = res['id'] as int;
                          final bookingId = res['booking_id'] ?? 'N/A';
                          final customerName = res['customer_name'] ?? 'Guest';
                          final tableId = res['table_id'] ?? 0;
                          final pax = res['pax'] ?? 0;
                          final resDate = DateTime.parse(res['reservation_date']).toLocal();
                          final now = DateTime.now();
                          final status = (res['status'] ?? 'booked').toString().toLowerCase();

                          // Logika Expired Super Ketat:
                          // 1. Cek apakah tanggalnya sudah lewat hari (kemarin atau sebelumnya)
                          final isDifferentDay = now.year > resDate.year || 
                                              (now.year == resDate.year && now.month > resDate.month) ||
                                              (now.year == resDate.year && now.month == resDate.month && now.day > resDate.day);
                          
                          // 2. Cek apakah sudah telat lebih dari 30 menit di hari yang sama
                          final isLateToday = now.isAfter(resDate.add(const Duration(minutes: 30)));

                          // 3. Gabungkan: Jika masih 'booked' tapi sudah beda hari ATAU sudah telat jamnya
                          final isExpired = (status == 'booked' || status == 'pending') && (isDifferentDay || isLateToday);
                          final fullDateStr = DateFormat('EEEE, d MMM yyyy').format(resDate);
                          final timeStr = DateFormat('HH:mm').format(resDate);

                          final isCheckedIn = status == 'checked_in';
                          final isCompleted = status == 'completed';
                          final isCancelled = status == 'cancelled' || status == 'no_show';

                          Color statusColor;
                          String statusLabel;
                          if (isExpired) {
                            statusColor = Colors.redAccent;
                            statusLabel = 'KEDALUWARSA / TELAT';
                          } else if (isCheckedIn) {
                            statusColor = Colors.green;
                            statusLabel = 'TELAH TIBA';
                          } else if (isCompleted) {
                            statusColor = Colors.blueAccent;
                            statusLabel = 'SELESAI';
                          } else if (isCancelled) {
                            statusColor = Colors.red;
                            statusLabel = status.toUpperCase();
                          } else {
                            statusColor = Colors.orangeAccent;
                            statusLabel = status.toUpperCase();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: JkGlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Booking ID & Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(bookingId,
                                              style: const TextStyle(
                                                  color: AppColors.caramelGold, 
                                                  fontWeight: FontWeight.w900, 
                                                  fontSize: 20,
                                                  letterSpacing: 1)),
                                          const SizedBox(height: 4),
                                          Text(fullDateStr.toUpperCase(), 
                                            style: TextStyle(color: AppColors.softCream.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(color: AppColors.borderGrey, height: 1),
                                  const SizedBox(height: 20),
                                  
                                  // Customer Name
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.caramelGold.withValues(alpha: 0.1),
                                        radius: 18,
                                        child: const Icon(Icons.person, color: AppColors.caramelGold, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(customerName,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Details Grid-like row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoItem(Icons.table_restaurant, 'Meja $tableId'),
                                      _buildInfoItem(Icons.people, '$pax Orang'),
                                      _buildInfoItem(Icons.access_time, timeStr),
                                    ],
                                  ),
                                  
                                  // Action Buttons
                                  if (!isCheckedIn && !isCompleted && !isCancelled && !isExpired) ...[
                                    const SizedBox(height: 24),
                                    JkPrimaryButton(
                                      label: 'Konfirmasi Kehadiran',
                                      isLoading: _isActionLoading,
                                      onPressed: () => _confirmArrival(id),
                                    ),
                                  ],
                                  if (isCheckedIn) ...[
                                    const SizedBox(height: 24),
                                    JkPrimaryButton(
                                      label: 'Selesai & Bebaskan Meja',
                                      isLoading: _isActionLoading,
                                      onPressed: () => _completeReservation(id),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.caramelGold.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}

