import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/reservation_repository.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';
import '../../widgets/jk_horizontal_calendar.dart';
import '../../widgets/jk_time_grid.dart';
import '../../widgets/jk_guest_selector.dart';

import 'reservation_summary_screen.dart';

class CustomerReservationScreen extends StatefulWidget {
  const CustomerReservationScreen({super.key});

  @override
  State<CustomerReservationScreen> createState() => _CustomerReservationScreenState();
}

class _CustomerReservationScreenState extends State<CustomerReservationScreen> {
  late ReservationRepository _reservationRepository;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  int _guestCount = 2;
  bool _isChecking = false;


  @override
  void initState() {
    super.initState();
    _reservationRepository = ReservationRepository(apiClient: ApiClient());
  }

  void _submitReservation() async {
    FocusScope.of(context).unfocus();
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu terlebih dahulu')),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final resData = await _reservationRepository.createReservation(
        dateStr,
        _selectedTime!,
        _guestCount,
        0, // Pass 0 to auto-allocate
      );

      final bookingId = resData['booking_id'] ?? 'JK-RES-${resData['id'] ?? resData['reservation_id']}';
      final qrCode = resData['barcode'] ?? resData['qr_code'] ?? bookingId;
      final assignedTableId = resData['table_id'] != null ? int.tryParse(resData['table_id'].toString()) ?? 0 : 0;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationSummaryScreen(
              date: _selectedDate,
              time: _selectedTime!,
              guests: _guestCount,
              tableId: assignedTableId > 0 ? assignedTableId : null,
              qrCode: qrCode,
              bookingId: bookingId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JABAT KOPI RESERVATION',
          style: TextStyle(
            color: AppColors.caramelGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT DATE', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
            const SizedBox(height: 16),
            JkHorizontalCalendar(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 32),
            Text('SELECT TIME', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
            const SizedBox(height: 16),
            JkTimeGrid(
              selectedTime: _selectedTime,
              onTimeSelected: (time) {
                setState(() => _selectedTime = time);
              },
            ),
            const SizedBox(height: 32),
            Text('JUMLAH ORANG', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
            const SizedBox(height: 4),
            const Text(
              'Untuk rombongan lebih dari 6 orang, harap hubungi staf kami.',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            JkGlassCard(
              padding: const EdgeInsets.all(24),
              child: JkGuestSelector(
                guestCount: _guestCount,
                onCountChanged: (count) => setState(() => _guestCount = count),
              ),
            ),
            const SizedBox(height: 24),

            const Opacity(
              opacity: 0.5,
              child: Center(
                child: Text(
                  'With booking, you agree to our terms and conditions.',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
            const SizedBox(height: 32),
            JkPrimaryButton(
              label: 'KONFIRMASI RESERVASI',
              isLoading: _isChecking,
              onPressed: _selectedTime == null ? null : _submitReservation,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
