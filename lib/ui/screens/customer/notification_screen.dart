import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/jk_glass_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (_notifications.isEmpty) setState(() => _isLoading = true);
    try {
      final res = await ApiClient().get('/notifications');
      if (mounted) {
        setState(() {
          _notifications = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.caramelGold))
          : _notifications.isEmpty
              ? const Center(child: Text('Tidak ada notifikasi', style: TextStyle(color: Colors.white24)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final date = DateTime.parse(n['created_at']);
                    final timeStr = DateFormat('dd MMM, HH:mm').format(date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JkGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.caramelGold.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(
                                n['type'] == 'promo' ? Icons.local_offer : (n['type'] == 'order' ? Icons.shopping_bag : Icons.notifications),
                                color: AppColors.caramelGold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(n['body'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text(timeStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
