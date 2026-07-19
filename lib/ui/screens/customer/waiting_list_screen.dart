import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/waiting_list_repository.dart';
import '../../widgets/jk_glass_card.dart';
import '../../widgets/jk_primary_button.dart';

class WaitingListScreen extends StatefulWidget {
  const WaitingListScreen({super.key});

  @override
  State<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends State<WaitingListScreen> with SingleTickerProviderStateMixin {
  final WaitingListRepository _repository = WaitingListRepository(apiClient: ApiClient());
  
  Map<String, dynamic>? _myStatus;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Timer? _pollingTimer;
  
  int _partySize = 2;
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fetchStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchStatus(isPolling: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus({bool isPolling = false}) async {
    if (!isPolling && mounted) setState(() => _isLoading = true);
    try {
      final status = await _repository.getMyStatus();
      if (mounted) {
        final wasWaiting = _myStatus != null && _myStatus!['status'] == 'waiting';
        final isNowNotified = status != null && status['status'] == 'notified';
        
        setState(() => _myStatus = status);

        // Jika FCM gagal masuk karena diblokir Xiaomi, ini adalah *fallback* pasti-masuk via polling 15 detik!
        if (wasWaiting && isNowNotified) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1A1210), // Coffee theme
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('PANGGILAN ANTREAN', style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
                ],
              ),
              content: const Text(
                'Meja Anda sudah siap! Silakan menuju kasir sekarang.',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OKE, SAYA KESANA', style: TextStyle(color: AppColors.caramelGold)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Ignore polling errors to prevent spam
    } finally {
      if (mounted && !isPolling) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinWaitingList() async {
    if (mounted) setState(() => _isSubmitting = true);
    try {
      // ponytail: skipping full error handling for FCM token missing, fallback to null
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      final result = await _repository.joinWaitingList(
        _partySize,
        notes: _notesController.text.trim(),
        fcmToken: token,
      );
      
      if (mounted) {
        setState(() => _myStatus = result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil bergabung dalam antrean!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal bergabung: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelWaitingList(int id) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await _repository.cancelMyWaitingList(id);
      if (mounted) {
        setState(() => _myStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Antrean berhasil dibatalkan.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tunggu', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _myStatus != null && ['waiting', 'notified'].contains(_myStatus!['status'])
                  ? _buildActiveStatus()
                  : _buildJoinForm(),
            ),
    );
  }

  Widget _buildJoinForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.caramelGold),
          const SizedBox(height: 16),
          const Text(
            'Kafe Sedang Penuh',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.softCream),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jangan khawatir, gabung dalam daftar tunggu dan kami akan memberi tahu Anda via notifikasi saat meja sudah siap.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          JkGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jumlah Orang', style: TextStyle(color: AppColors.softCream, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCircleBtn(Icons.remove, () {
                      if (_partySize > 1) setState(() => _partySize--);
                    }),
                    Expanded(
                      child: Text(
                        '$_partySize Orang',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.caramelGold),
                      ),
                    ),
                    _buildCircleBtn(Icons.add, () {
                      if (_partySize < 20) setState(() => _partySize++);
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Catatan (Opsional)', style: TextStyle(color: AppColors.softCream, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Misal: butuh kursi tinggi, dekat jendela...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          JkPrimaryButton(
            label: 'GABUNG DAFTAR TUNGGU',
            isLoading: _isSubmitting,
            onPressed: _joinWaitingList,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.softCream),
      ),
    );
  }

  Widget _buildActiveStatus() {
    final status = _myStatus!['status'];
    final isNotified = status == 'notified';
    final qNumber = _myStatus!['queue_number'] ?? '-';
    final position = _myStatus!['position'] ?? 0;
    final estMinutes = _myStatus!['estimated_wait_minutes'] ?? 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isNotified)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: const Icon(Icons.notifications_active, size: 80, color: Colors.greenAccent),
                  );
                },
              )
            else
              const Icon(Icons.hourglass_bottom, size: 80, color: AppColors.caramelGold),
            
            const SizedBox(height: 24),
            Text(
              isNotified ? 'MEJA ANDA SIAP!' : 'ANDA DALAM ANTREAN',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: isNotified ? Colors.greenAccent : AppColors.softCream,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            JkGlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text('NOMOR ANTREAN', style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    '#$qNumber',
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.caramelGold),
                  ),
                  if (!isNotified) ...[
                    const Divider(height: 32, color: AppColors.borderGrey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('POSISI', '$position', 'Di Depan Anda'),
                        Container(width: 1, height: 40, color: AppColors.borderGrey),
                        _buildStat('ESTIMASI', '~${estMinutes}m', 'Waktu Tunggu'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            if (isNotified)
              const Text(
                'Silakan menuju ke kasir atau temui staf kami sekarang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              )
            else
              TextButton.icon(
                onPressed: () => _cancelWaitingList(_myStatus!['id']),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text('BATALKAN ANTREAN', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value, String subtitle) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.softCream, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
