import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';

class ReservationSummaryScreen extends StatelessWidget {
  final DateTime date;
  final String time;
  final int guests;
  final int tableId;
  final String qrCode;
  final String bookingId;

  const ReservationSummaryScreen({
    super.key,
    required this.date,
    required this.time,
    required this.guests,
    required this.tableId,
    required this.qrCode,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            JkGlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'TABLE RESERVATION',
                    style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookingId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.caramelGold),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.caramelGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.caramelGold, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ID MEJA',
                          style: TextStyle(fontSize: 14, color: AppColors.softCream.withOpacity(0.8), letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$tableId',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.caramelGold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildDetailRow('Date', DateFormat('EEEE, dd MMM yyyy').format(date)),
                  const Divider(color: AppColors.glassBorder, height: 32),
                  _buildDetailRow('Time', time),
                  const Divider(color: AppColors.glassBorder, height: 32),
                  _buildDetailRow('Table', 'Meja $tableId'),
                  const Divider(color: AppColors.glassBorder, height: 32),
                  _buildDetailRow('Guests', '$guests People'),
                  const SizedBox(height: 32),
                  const Text(
                    'Silakan sebutkan ID Meja atau Booking ID kepada barista saat Anda tiba.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            JkPrimaryButton(
              label: 'BACK TO HOME',
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
        Text(label, style: TextStyle(color: AppColors.softCream.withOpacity(0.6))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

