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
import '../../widgets/jk_table_grid.dart';
import '../../../core/services/notification_service.dart';
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

  // Table selection state
  List<Map<String, dynamic>> _availableTables = [];
  int? _selectedTableId;
  bool _isLoadingTables = false;

  @override
  void initState() {
    super.initState();
    _reservationRepository = ReservationRepository(apiClient: ApiClient());
    _loadTables();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService().initialize();
    await NotificationService().requestPermission();
  }

  Future<void> _loadTables() async {
    if (_selectedTime == null) {
      setState(() {
        _availableTables = [];
        _selectedTableId = null;
      });
      return;
    }

    setState(() => _isLoadingTables = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await ApiClient().get('/tables/status?date=$dateStr&time=$_selectedTime');
      final List<dynamic> data = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _availableTables = data.cast<Map<String, dynamic>>();
          
          if (_selectedTableId != null) {
            final selectedTable = _availableTables.firstWhere(
              (t) => t['id'] == _selectedTableId,
              orElse: () => {},
            );
            if (selectedTable.isEmpty || selectedTable['display_status'] != 'available') {
              _selectedTableId = null;
            }
          }
          
          _isLoadingTables = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTables = false);
    }
  }

  void _submitReservation() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu terlebih dahulu')),
      );
      return;
    }
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih meja terlebih dahulu')),
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
        0, // will be overwritten by JWT in backend
        _selectedTableId!,
      );

      // Ambil booking_id dan barcode dari response backend yang sudah diperbaiki
      final bookingId = resData['booking_id'] ?? 'JK-RES-${resData['reservation_id']}';
      final qrCode = resData['barcode'] ?? resData['qr_code'] ?? bookingId;

      // Tampilkan notifikasi Android/iOS
      await NotificationService().showReservationNotification(
        bookingId,
        '$dateStr $_selectedTime',
        _selectedTableId!,
        _guestCount,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationSummaryScreen(
              date: _selectedDate,
              time: _selectedTime!,
              guests: _guestCount,
              tableId: _selectedTableId!,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECT DATE', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
                const SizedBox(height: 16),
                JkHorizontalCalendar(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() => _selectedDate = date);
                    _loadTables();
                  },
                ),
                const SizedBox(height: 32),
                Text('SELECT TIME', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
                const SizedBox(height: 16),
                JkTimeGrid(
                  selectedTime: _selectedTime,
                  onTimeSelected: (time) {
                    setState(() => _selectedTime = time);
                    _loadTables();
                  },
                ),
                const SizedBox(height: 32),
                Text('GUESTS', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
                const SizedBox(height: 16),
                JkGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: JkGuestSelector(
                    guestCount: _guestCount,
                    onCountChanged: (count) => setState(() => _guestCount = count),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── PILIH MEJA ───
                Text('PILIH MEJA', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.caramelGold)),
                const SizedBox(height: 16),
                _isLoadingTables
                    ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
                    : JkTableGrid(
                        tables: _availableTables,
                        selectedTableId: _selectedTableId,
                        onTableSelected: (id) => setState(() => _selectedTableId = id),
                      ),
                const SizedBox(height: 24),

                // Info banner
                if (_selectedTableId != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.caramelGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.caramelGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.caramelGold, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Saat Anda datang dan memesan, meja $_selectedTableId akan otomatis terdeteksi dari reservasi ini.',
                            style: const TextStyle(color: AppColors.caramelGold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                const Opacity(
                  opacity: 0.5,
                  child: Center(
                    child: Text(
                      'With booking, you agree to our terms and conditions.',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.charcoal.withOpacity(0),
                    AppColors.charcoal,
                  ],
                ),
              ),
              child: JkPrimaryButton(
                label: 'KONFIRMASI RESERVASI',
                isLoading: _isChecking,
                onPressed: (_availableTables.isEmpty || _selectedTableId == null) ? null : _submitReservation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
