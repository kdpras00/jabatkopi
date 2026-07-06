import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';

class ReservationSummaryScreen extends StatelessWidget {
  final DateTime date;
  final String time;
  final int guests;
  final int? tableId; 
  final String qrCode;
  final String bookingId;
  final String? staffNote; 
  const ReservationSummaryScreen({
    super.key,
    required this.date,
    required this.time,
    required this.guests,
    required this.tableId,
    required this.qrCode,
    required this.bookingId,
    this.staffNote,
  });

  @override
  Widget build(BuildContext context) {
    final tableAssigned = tableId != null && tableId! > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Reservasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            JkGlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'RESERVASI MEJA',
                    style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookingId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold),
                  ),
                  const SizedBox(height: 32),

                  // Meja — ditunjukkan berbeda jika belum diassign
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white10,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          tableAssigned ? 'MEJA' : 'MEJA BELUM DITENTUKAN',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (tableAssigned)
                          Text(
                            '$tableId',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.caramelGold),
                          )
                        else ...[
                          const Icon(Icons.schedule, color: AppColors.caramelGold, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Staf akan menyiapkan meja\nsaat Anda tiba di cafe',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildDetailRow('Tanggal', DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date)),
                  const Divider(color: AppColors.borderGrey, height: 32),
                  _buildDetailRow('Waktu', time),
                  const Divider(color: AppColors.borderGrey, height: 32),
                  _buildDetailRow('Jumlah Orang', '$guests Orang'),
                  const SizedBox(height: 32),

                  // ─── CATATAN DARI STAF (read-only untuk customer) ───
                  if (staffNote != null && staffNote!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined, color: AppColors.caramelGold, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CATATAN DARI STAF',
                                  style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.caramelGold, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  staffNote!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Info check-in
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.caramelGold.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.caramelGold, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tunjukkan Booking ID atau QR Code ini kepada staf saat Anda tiba. Staf akan melakukan check-in dan menyiapkan meja Anda.',
                            style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.softCream.withValues(alpha: 0.6))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
