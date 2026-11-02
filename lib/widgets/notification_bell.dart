import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.account,
    required this.onPressed,
    this.iconSize = 26,
    this.buttonSize = 32,
    this.backgroundColor = const Color(0xFF0B2E3B),
  });

  final AuthenticatedUser account;
  final VoidCallback onPressed;
  final double iconSize;
  final double buttonSize;
  final Color backgroundColor;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final NotificationService _notificationService;

  Timer? _timer;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    _notificationService = NotificationService(
      apiClient: ApiClient(),
      token: widget.account.token,
    );

    _loadUnreadCount();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadUnreadCount(),
    );
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await _notificationService.getNotifications();

      if (!mounted) return;

      setState(() {
        _unreadCount = result.unreadCount;
      });
    } catch (_) {
      // Pertahankan jumlah terakhir jika server tidak tersedia.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _unreadCount > 0
          ? 'Notifikasi belum dibaca: $_unreadCount'
          : 'Notifikasi',
      onPressed: widget.onPressed,
      color: Colors.white,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(
        width: widget.buttonSize,
        height: widget.buttonSize,
      ),
      padding: EdgeInsets.zero,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: widget.iconSize,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -7,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 17,
                  minHeight: 17,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5282B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.backgroundColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}