import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:intl/intl.dart';

class ScheduleCalendarScreen extends StatefulWidget {
  const ScheduleCalendarScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final response = await _apiService.getMySchedule();
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          _schedules = List<Map<String, dynamic>>.from(response['schedules'] ?? []);
        }
        _isLoading = false;
      });
    }
  }

  String _statusOf(Map<String, dynamic> s) {
    if (s['isCancel'] == 1) return 'cancelled';
    if (s['isAttend'] == 1) return 'attended';
    final end = DateTime.tryParse(s['endSchedule'] ?? '');
    if (end != null && end.isBefore(DateTime.now())) return 'not_attended';
    return 'upcoming';
  }

  Map<DateTime, List<Map<String, dynamic>>> get _eventsByDay {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final s in _schedules) {
      final start = DateTime.tryParse(s['startSchedule'] ?? '');
      if (start == null) continue;
      final key = DateTime(start.year, start.month, start.day);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDay[key] ?? [];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'attended':
        return const Color(0xFF1D9E75);
      case 'cancelled':
        return const Color(0xFFD53A47);
      case 'not_attended':
        return const Color(0xFFBA7517);
      default:
        return const Color(0xFF378ADD);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'attended':
        return 'Attended';
      case 'cancelled':
        return 'Cancelled';
      case 'not_attended':
        return 'Not attended';
      default:
        return 'Upcoming';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'attended':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'not_attended':
        return Icons.remove_circle_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  void _onDayTap(DateTime day) {
    final events = _eventsForDay(day);
    if (events.isEmpty) {
      setState(() => _selectedDay = day);
      return;
    }
    setState(() => _selectedDay = day);
    if (events.length == 1) {
      _showEventDetail(events.first);
    } else {
      _showDayEvents(day, events);
    }
  }

  void _showDayEvents(DateTime day, List<Map<String, dynamic>> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayEventsSheet(
        day: day,
        events: events,
        statusOf: _statusOf,
        statusColor: _statusColor,
        statusLabel: _statusLabel,
        statusIcon: _statusIcon,
        onTap: _showEventDetail,
      ),
    );
  }

  void _showEventDetail(Map<String, dynamic> schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(
        schedule: schedule,
        status: _statusOf(schedule),
        statusColor: _statusColor(_statusOf(schedule)),
        statusLabel: _statusLabel(_statusOf(schedule)),
        statusIcon: _statusIcon(_statusOf(schedule)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.redPink,
        foregroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'Schedule Calendar',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSchedules,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.redPink),
      )
          : Column(
        children: [
          _CalendarHeader(
            focusedMonth: _focusedMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          _CalendarGrid(
            focusedMonth: _focusedMonth,
            selectedDay: _selectedDay,
            eventsByDay: _eventsByDay,
            statusOf: _statusOf,
            statusColor: _statusColor,
            onDayTap: _onDayTap,
          ),
          _Legend(),
          const SizedBox(height: 8),
          Expanded(
            child: _UpcomingList(
              schedules: _schedules,
              statusOf: _statusOf,
              statusColor: _statusColor,
              statusLabel: _statusLabel,
              statusIcon: _statusIcon,
              onTap: _showEventDetail,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarHeader({
    required this.focusedMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.redPink,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy').format(focusedMonth),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.white, size: 22),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<DateTime, List<Map<String, dynamic>>> eventsByDay;
  final String Function(Map<String, dynamic>) statusOf;
  final Color Function(String) statusColor;
  final void Function(DateTime) onDayTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.eventsByDay,
    required this.statusOf,
    required this.statusColor,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final startOffset = (firstDay.weekday % 7);
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          children: [
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d == 'Sun'
                            ? AppTheme.redPink.withOpacity(0.8)
                            : const Color(0xFF888780),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 2,
                childAspectRatio: 0.85,
              ),
              itemCount: startOffset + lastDay.day,
              itemBuilder: (_, index) {
                if (index < startOffset) return const SizedBox();
                final day = DateTime(
                  focusedMonth.year,
                  focusedMonth.month,
                  index - startOffset + 1,
                );
                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;
                final isSelected = selectedDay != null &&
                    day.year == selectedDay!.year &&
                    day.month == selectedDay!.month &&
                    day.day == selectedDay!.day;
                final key = DateTime(day.year, day.month, day.day);
                final events = eventsByDay[key] ?? [];
                final isSunday = day.weekday == DateTime.sunday;

                return GestureDetector(
                  onTap: () => onDayTap(day),
                  child: _DayCell(
                    day: day.day,
                    isToday: isToday,
                    isSelected: isSelected,
                    isSunday: isSunday,
                    events: events,
                    statusOf: statusOf,
                    statusColor: statusColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isSunday;
  final List<Map<String, dynamic>> events;
  final String Function(Map<String, dynamic>) statusOf;
  final Color Function(String) statusColor;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isSunday,
    required this.events,
    required this.statusOf,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = isSunday ? const Color(0xFFD53A47) : const Color(0xFF333333);

    if (isSelected) {
      bgColor = AppTheme.redPink;
      textColor = AppTheme.white;
    } else if (isToday) {
      bgColor = AppTheme.redPink.withOpacity(0.12);
      textColor = AppTheme.redPink;
    }

    final dotColors = events.take(3).map((e) => statusColor(statusOf(e))).toList();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
            ),
          ),
          if (dotColors.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dotColors
                  .map(
                    (c) => Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.white : c,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Upcoming', Color(0xFF378ADD)),
      ('Attended', Color(0xFF1D9E75)),
      ('Not attended', Color(0xFFBA7517)),
      ('Cancelled', Color(0xFFD53A47)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (item) => Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.$2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888780),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            .toList(),
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  final String Function(Map<String, dynamic>) statusOf;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final IconData Function(String) statusIcon;
  final void Function(Map<String, dynamic>) onTap;

  const _UpcomingList({
    required this.schedules,
    required this.statusOf,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No engagements joined yet',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'All schedules',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: schedules.length,
            itemBuilder: (_, i) {
              final s = schedules[i];
              final status = statusOf(s);
              final color = statusColor(status);
              final start = DateTime.tryParse(s['startSchedule'] ?? '');
              return GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 70,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['titleEngagement'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (start != null)
                                Text(
                                  DateFormat('EEE, MMM d • h:mm a').format(start),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888780),
                                  ),
                                ),
                              if ((s['locationAddress'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 11,
                                        color: Colors.grey.shade400),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        s['locationAddress'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon(status), size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel(status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayEventsSheet extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> events;
  final String Function(Map<String, dynamic>) statusOf;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final IconData Function(String) statusIcon;
  final void Function(Map<String, dynamic>) onTap;

  const _DayEventsSheet({
    required this.day,
    required this.events,
    required this.statusOf,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(day),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        DateFormat('MMMM d, yyyy').format(day),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888780),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.redPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${events.length} event${events.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.redPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (_, i) {
                  final s = events[i];
                  final status = statusOf(s);
                  final color = statusColor(status);
                  final start = DateTime.tryParse(s['startSchedule'] ?? '');
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onTap(s);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon(status), size: 20, color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['titleEngagement'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                if (start != null)
                                  Text(
                                    DateFormat('h:mm a').format(start),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            statusLabel(status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
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
}

class _EventDetailSheet extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final String status;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;

  const _EventDetailSheet({
    required this.schedule,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(schedule['startSchedule'] ?? '');
    final end = DateTime.tryParse(schedule['endSchedule'] ?? '');

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['titleEngagement'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if ((schedule['categoryName'] ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: schedule['categoryName'],
                    ),
                  if (start != null)
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Start',
                      value: DateFormat('EEE, MMM d, yyyy • h:mm a').format(start),
                    ),
                  if (end != null)
                    _InfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'End',
                      value: DateFormat('EEE, MMM d, yyyy • h:mm a').format(end),
                    ),
                  if ((schedule['locationAddress'] ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: schedule['locationAddress'],
                    ),
                  if ((schedule['facilitatorName'] ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Facilitator',
                      value: schedule['facilitatorName'],
                    ),
                  if ((schedule['facilitatorContact'] ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Contact',
                      value: schedule['facilitatorContact'],
                    ),
                  if ((schedule['activityPoints'] ?? 0) > 0)
                    _InfoRow(
                      icon: Icons.stars_rounded,
                      label: 'Activity points',
                      value: '${schedule['activityPoints']} pts',
                    ),
                  if ((schedule['description'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionLabel(label: 'Description'),
                    _TextBlock(text: schedule['description']),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF888780)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888780),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF888780),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;

  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF333333),
          height: 1.5,
        ),
      ),
    );
  }
}