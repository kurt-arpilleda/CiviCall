import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/anim/skeletonAnimation.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> refresh() async {
    await _loadNotifications(silent: true);
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final res = await _apiService.getNotifications();

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _notifications =
        List<Map<String, dynamic>>.from(res['notifications'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load notifications.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePullRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadNotifications(silent: true);
    if (mounted) setState(() => _isRefreshing = false);
  }

  int get _unreadCount =>
      _notifications.where((n) => (n['notificationStatus'] ?? 0) == 0).length;

  Future<void> _markAsRead(int notifId) async {
    final index = _notifications.indexWhere((n) => n['notifId'] == notifId);
    if (index == -1 || _notifications[index]['notificationStatus'] != 0) return;

    setState(() {
      _notifications[index]['notificationStatus'] = 1;
    });

    final res = await _apiService.markNotificationRead(notifId: notifId);
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() {
        _notifications[index]['notificationStatus'] = 0;
      });
    }
  }

  Future<void> _openNotificationDetail(Map<String, dynamic> notif) {
    final notifId = notif['notifId'] as int;
    if ((notif['notificationStatus'] ?? 0) == 0) {
      _markAsRead(notifId);
    }
    final notifName = (notif['notifName'] ?? 'Notification').toString();
    final detail = (notif['notificationDetail'] ?? '').toString();
    final dateTime = (notif['dateTime'] ?? '').toString();
    final style = _styleForType(notifName);
    final Color accentColor = style['color'] as Color;
    final IconData iconData = style['icon'] as IconData;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: accentColor, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notifName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeAgo(dateTime),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.darkGray.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppTheme.darkGray.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.redPink,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;
    final previous = List<Map<String, dynamic>>.from(_notifications);

    setState(() {
      for (final n in _notifications) {
        n['notificationStatus'] = 1;
      }
    });

    final res = await _apiService.markAllNotificationsRead();
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() {
        _notifications = previous;
      });
    }
  }

  Future<void> _removeNotification(int notifId) async {
    final index = _notifications.indexWhere((n) => n['notifId'] == notifId);
    if (index == -1) return;
    final removed = _notifications[index];

    setState(() {
      _notifications.removeAt(index);
    });

    final res = await _apiService.removeNotification(notifId: notifId);
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() {
        _notifications.insert(index, removed);
      });
    }
  }

  String _timeAgo(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months}mo';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years}y';
      }
    } catch (_) {
      return 'just now';
    }
  }

  Map<String, dynamic> _styleForType(String notifName) {
    final name = notifName.toLowerCase();
    if (name.contains('forum')) {
      return {'icon': Icons.forum_rounded, 'color': const Color(0xFF6A1B9A)};
    } else if (name.contains('engagement') || name.contains('volunteer')) {
      return {
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFF2E7D5E)
      };
    } else if (name.contains('schedule') || name.contains('event')) {
      return {
        'icon': Icons.event_available_rounded,
        'color': const Color(0xFF1565C0)
      };
    } else if (name.contains('verif')) {
      return {
        'icon': Icons.verified_user_rounded,
        'color': AppTheme.redPink
      };
    } else if (name.contains('leaderboard') || name.contains('point')) {
      return {
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFB8860B)
      };
    } else if (name.contains('news')) {
      return {
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF37474F)
      };
    }
    return {
      'icon': Icons.notifications_rounded,
      'color': AppTheme.redPink
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _unreadCount > 0
                  ? '$_unreadCount unread notification${_unreadCount == 1 ? '' : 's'}'
                  : 'You\'re all caught up',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray.withOpacity(0.6),
              ),
            ),
          ),
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.redPink,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeletonList();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppTheme.redPink,
      onRefresh: _handlePullRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return _buildNotificationCard(notif);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final notifId = notif['notifId'] as int;
    final isUnread = (notif['notificationStatus'] ?? 0) == 0;
    final notifName = (notif['notifName'] ?? 'Notification').toString();
    final detail = (notif['notificationDetail'] ?? '').toString();
    final dateTime = (notif['dateTime'] ?? '').toString();
    final style = _styleForType(notifName);
    final Color accentColor = style['color'] as Color;
    final IconData iconData = style['icon'] as IconData;

    return Dismissible(
      key: ValueKey('notif_$notifId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppTheme.redPink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.white),
      ),
      onDismissed: (_) => _removeNotification(notifId),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNotificationDetail(notif),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread ? accentColor.withOpacity(0.05) : AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? accentColor.withOpacity(0.18)
                  : AppTheme.darkGray.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkGray.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: accentColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notifName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight:
                              isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.darkGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(dateTime),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.darkGray.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.darkGray.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGray.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 42, height: 42, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 120, height: 13, borderRadius: 6),
                  const SizedBox(height: 8),
                  SkeletonBox(
                      width: MediaQuery.of(context).size.width * 0.55,
                      height: 11,
                      borderRadius: 6),
                  const SizedBox(height: 6),
                  SkeletonBox(
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: 11,
                      borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.redPink.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 40,
                    color: AppTheme.redPink.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We\'ll let you know when something\narrives.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkGray.withOpacity(0.4),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 40, color: AppTheme.darkGray.withOpacity(0.3)),
                const SizedBox(height: 14),
                Text(
                  _error ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.darkGray.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadNotifications(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.redPink,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}