import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/imageViewer.dart';
import 'package:civicall/googleMap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:civicall/drawerNavigation/userVerification.dart';
import 'package:url_launcher/url_launcher.dart';

class EngagementDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> engagement;
  final int? currentUserId;
  final VoidCallback? onUpdated;

  const EngagementDetailsScreen({
    Key? key,
    required this.engagement,
    required this.currentUserId,
    this.onUpdated,
  }) : super(key: key);

  @override
  State<EngagementDetailsScreen> createState() => _EngagementDetailsScreenState();
}

class _EngagementDetailsScreenState extends State<EngagementDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _engagement;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isJoined = false;
  bool _isJoinLoading = true;
  int _participantCount = 0;
  int _isAttend = 0;
  int _isCancel = 0;

  File? _newImage;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _campuses = [];

  int? _editCategoryId;
  String? _editCategoryName;
  Set<int> _editCampusIds = {};

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _facilitatorCtrl = TextEditingController();
  final _facilitatorContactCtrl = TextEditingController();

  double? _editLat;
  double? _editLng;
  DateTime? _editStart;
  DateTime? _editEnd;

  @override
  void initState() {
    super.initState();
    _engagement = Map<String, dynamic>.from(widget.engagement);
    _loadDropdowns();
    _loadParticipantStatus();
  }
  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _objectiveCtrl.dispose();
    _instructionCtrl.dispose();
    _locationCtrl.dispose();
    _targetCtrl.dispose();
    _pointsCtrl.dispose();
    _facilitatorCtrl.dispose();
    _facilitatorContactCtrl.dispose();
    super.dispose();
  }

  bool get _isEnded {
    final endStr = _engagement['endSchedule'] as String?;
    if (endStr == null || endStr.isEmpty) return false;
    final end = DateTime.tryParse(endStr);
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  bool get _isNearEnd {
    if (_isEnded) return false;
    final endStr = _engagement['endSchedule'] as String?;
    if (endStr == null || endStr.isEmpty) return false;
    final end = DateTime.tryParse(endStr);
    if (end == null) return false;
    final difference = end.difference(DateTime.now()).inDays;
    return difference <= 2;
  }

  Future<void> _loadDropdowns() async {
    final catRes = await _apiService.fetchEngagementCategories();
    final campRes = await _apiService.fetchCampus();
    if (mounted) {
      setState(() {
        if (catRes['success'] == true) {
          _categories = List<Map<String, dynamic>>.from(catRes['categories'] ?? []);
        }
        if (campRes['success'] == true) {
          _campuses = List<Map<String, dynamic>>.from(campRes['campuses'] ?? []);
        }
      });
    }
  }
  Future<void> _loadParticipantStatus() async {
    final engagementId = _engagement['engagementId'] as int?;
    if (engagementId == null) return;
    final res = await _apiService.getParticipants(engagementId: engagementId);
    if (mounted) {
      setState(() {
        _isJoined = (res['isJoined'] as int? ?? 0) == 1;
        _participantCount = res['total'] as int? ?? 0;
      });
    }
    await _loadUserAttendanceStatus(engagementId);
    setState(() {
      _isJoinLoading = false;
    });
  }

  Future<void> _loadUserAttendanceStatus(int engagementId) async {
    final scheduleRes = await _apiService.getMySchedule();
    if (scheduleRes['success'] != true) return;
    final schedules = List<Map<String, dynamic>>.from(scheduleRes['schedules'] ?? []);
    final myEntry = schedules.firstWhere(
          (s) => s['engagementId'] == engagementId,
      orElse: () => {},
    );
    if (myEntry.isNotEmpty) {
      setState(() {
        _isAttend = myEntry['isAttend'] as int? ?? 0;
        _isCancel = myEntry['isCancel'] as int? ?? 0;
      });
    } else {
      setState(() {
        _isAttend = 0;
        _isCancel = 0;
      });
    }
  }

  String get _attendanceDisplayStatus {
    if (!_isJoined) return 'not_joined';
    if (_isCancel == 1) return 'cancelled';
    if (_isAttend == 1) return 'attended';
    if (_isEnded) return 'not_attended';
    return 'upcoming';
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

  Future<bool> _hasScheduleConflict() async {
    final myScheduleRes = await _apiService.getMySchedule();
    if (myScheduleRes['success'] != true) return false;

    final schedules = List<Map<String, dynamic>>.from(myScheduleRes['schedules'] ?? []);
    final activeSchedules = schedules.where((s) => s['isCancel'] == 0).toList();
    if (activeSchedules.isEmpty) return false;

    final newStart = DateTime.tryParse(_engagement['startSchedule'] as String? ?? '');
    final newEnd = DateTime.tryParse(_engagement['endSchedule'] as String? ?? '');
    if (newStart == null || newEnd == null) return false;

    for (final s in activeSchedules) {
      final existingStart = DateTime.tryParse(s['startSchedule'] as String? ?? '');
      final existingEnd = DateTime.tryParse(s['endSchedule'] as String? ?? '');
      if (existingStart == null || existingEnd == null) continue;

      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _handleJoin(BuildContext context) async {
    if (_isEnded) {
      _showSnack('This engagement has already ended.', isError: true);
      return;
    }
    final userRes = await _apiService.getUserData();
    if (!mounted) return;
    final isVerified = userRes['success'] == true && (userRes['user']?['isVerified'] ?? 0) == 1;
    if (!isVerified) {
      _showUnverifiedJoinDialog(context);
      return;
    }

    final bool hasConflict = await _hasScheduleConflict();
    if (hasConflict) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.redPink, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Schedule Conflict', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGray), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'This engagement conflicts with another engagement you have already joined.\nAre you sure you want to proceed?',
                style: TextStyle(fontSize: 13.5, color: AppTheme.darkGray.withOpacity(0.65), height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: AppTheme.darkGray.withOpacity(0.5))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Join Anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: const Color(0xFF2E7D5E).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF2E7D5E), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Join Engagement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGray), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Do you want to participate in "${_engagement['titleEngagement'] ?? ''}"?',
              style: TextStyle(fontSize: 13.5, color: AppTheme.darkGray.withOpacity(0.65), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.darkGray.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Join Now'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isJoinLoading = true);
    final res = await _apiService.joinEngagement(engagementId: _engagement['engagementId'] as int);
    if (!mounted) return;
    if (res['message'] == 'not_verified') {
      setState(() => _isJoinLoading = false);
      _showUnverifiedJoinDialog(context);
      return;
    }
    if (res['success'] == true) {
      await _loadParticipantStatus();
      setState(() {
        _isJoined = true;
        _isCancel = 0;
        _isAttend = 0;
      });
      _showSnack('Successfully joined the engagement!');
    } else {
      setState(() => _isJoinLoading = false);
      _showSnack(res['message'] ?? 'Failed to join.', isError: true);
    }
  }

  Future<void> _handleCancel(BuildContext context) async {
    if (_isEnded) {
      _showSnack('Cannot cancel after the engagement has ended.', isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_outlined, color: AppTheme.redPink, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Cancel Participation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGray), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to cancel your participation in "${_engagement['titleEngagement'] ?? ''}"?',
              style: TextStyle(fontSize: 13.5, color: AppTheme.darkGray.withOpacity(0.65), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: AppTheme.darkGray.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isJoinLoading = true);
    final res = await _apiService.cancelEngagement(engagementId: _engagement['engagementId'] as int);
    if (!mounted) return;
    if (res['success'] == true) {
      await _loadParticipantStatus();
      setState(() {
        _isJoined = false;
        _isCancel = 1;
      });
      _showSnack('Participation cancelled.');
    } else {
      setState(() => _isJoinLoading = false);
      _showSnack(res['message'] ?? 'Failed to cancel.', isError: true);
    }
  }

  void _showUnverifiedJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_outlined, color: AppTheme.redPink, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Verification Required', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGray), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'You need to verify your account before you can join an engagement.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.darkGray.withOpacity(0.65), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Maybe Later', style: TextStyle(color: AppTheme.darkGray.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserVerificationScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  void _showParticipantsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ParticipantsBottomSheet(
        engagementId: _engagement['engagementId'] as int,
        apiService: _apiService,
      ),
    );
  }
  void _enterEditMode() {
    _titleCtrl.text = _engagement['titleEngagement'] ?? '';
    _descCtrl.text = _engagement['description'] ?? '';
    _objectiveCtrl.text = _engagement['objective'] ?? '';
    _instructionCtrl.text = _engagement['instruction'] ?? '';
    _locationCtrl.text = _engagement['locationAddress'] ?? '';
    _targetCtrl.text = (_engagement['targetParty'] ?? 0).toString();
    _pointsCtrl.text = (_engagement['activityPoints'] ?? 0).toString();
    _facilitatorCtrl.text = _engagement['facilitatorName'] ?? '';
    _facilitatorContactCtrl.text = _engagement['facilitatorContact'] ?? '';
    _editLat = _engagement['latitude'] as double?;
    _editLng = _engagement['longitude'] as double?;
    _editCategoryId = _engagement['categoryId'] as int?;
    _editCategoryName = _engagement['categoryName'] as String?;
    _newImage = null;

    final campusStr = _engagement['campus'] as String? ?? '';
    _editCampusIds = campusStr.split(',').where((s) => s.isNotEmpty).map((s) => int.tryParse(s) ?? 0).where((i) => i > 0).toSet();

    final startStr = _engagement['startSchedule'] as String?;
    final endStr = _engagement['endSchedule'] as String?;
    try { _editStart = startStr != null && startStr.isNotEmpty ? DateTime.parse(startStr) : null; } catch (_) {}
    try { _editEnd = endStr != null && endStr.isNotEmpty ? DateTime.parse(endStr) : null; } catch (_) {}

    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _newImage = null;
    });
  }

  bool _validateEditForm() {
    if (_editCategoryId == null) {
      _showSnack('Please select a category.', isError: true);
      return false;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Title is required.', isError: true);
      return false;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showSnack('Description is required.', isError: true);
      return false;
    }
    if (_objectiveCtrl.text.trim().isEmpty) {
      _showSnack('Objective is required.', isError: true);
      return false;
    }
    if (_instructionCtrl.text.trim().isEmpty) {
      _showSnack('Instructions are required.', isError: true);
      return false;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      _showSnack('Location address is required.', isError: true);
      return false;
    }
    if (_editLat == null || _editLng == null) {
      _showSnack('Please pin the location on the map.', isError: true);
      return false;
    }
    if (_editCampusIds.isEmpty) {
      _showSnack('Please select at least one target campus.', isError: true);
      return false;
    }
    final target = int.tryParse(_targetCtrl.text.trim());
    if (target == null || target <= 0) {
      _showSnack('Target participants must be a positive number.', isError: true);
      return false;
    }
    if (_editStart == null) {
      _showSnack('Start date and time are required.', isError: true);
      return false;
    }
    if (_editEnd == null) {
      _showSnack('End date and time are required.', isError: true);
      return false;
    }
    if (_editEnd!.isBefore(_editStart!)) {
      _showSnack('End date must be after start date.', isError: true);
      return false;
    }
    final points = int.tryParse(_pointsCtrl.text.trim());
    if (points == null || points <= 0) {
      _showSnack('Activity points must be a positive number.', isError: true);
      return false;
    }
    if (_facilitatorCtrl.text.trim().isEmpty) {
      _showSnack('Facilitator name is required.', isError: true);
      return false;
    }
    if (_facilitatorContactCtrl.text.trim().isEmpty) {
      _showSnack('Facilitator contact is required.', isError: true);
      return false;
    }
    final hasExistingImage = (_engagement['engagementImage'] as String? ?? '').isNotEmpty;
    if (!hasExistingImage && _newImage == null) {
      _showSnack('An engagement photo is required.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _saveEdit() async {
    if (!_validateEditForm()) return;
    setState(() => _isSaving = true);

    final startStr = _editStart != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_editStart!) : '';
    final endStr = _editEnd != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_editEnd!) : '';
    final campusStr = _editCampusIds.join(',');

    final res = await _apiService.updateEngagement(
      engagementId: _engagement['engagementId'] as int,
      categoryId: _editCategoryId ?? 0,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      objective: _objectiveCtrl.text.trim(),
      instruction: _instructionCtrl.text.trim(),
      locationAddress: _locationCtrl.text.trim(),
      latitude: _editLat ?? 0.0,
      longitude: _editLng ?? 0.0,
      startSchedule: startStr,
      endSchedule: endStr,
      campus: campusStr,
      targetParty: int.tryParse(_targetCtrl.text) ?? 0,
      activityPoints: int.tryParse(_pointsCtrl.text) ?? 0,
      facilitatorName: _facilitatorCtrl.text.trim(),
      facilitatorContact: _facilitatorContactCtrl.text.trim(),
      imageFile: _newImage,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      setState(() {
        _engagement['titleEngagement'] = _titleCtrl.text.trim();
        _engagement['description'] = _descCtrl.text.trim();
        _engagement['objective'] = _objectiveCtrl.text.trim();
        _engagement['instruction'] = _instructionCtrl.text.trim();
        _engagement['locationAddress'] = _locationCtrl.text.trim();
        _engagement['targetParty'] = int.tryParse(_targetCtrl.text) ?? 0;
        _engagement['activityPoints'] = int.tryParse(_pointsCtrl.text) ?? 0;
        _engagement['facilitatorName'] = _facilitatorCtrl.text.trim();
        _engagement['facilitatorContact'] = _facilitatorContactCtrl.text.trim();
        _engagement['latitude'] = _editLat ?? 0.0;
        _engagement['longitude'] = _editLng ?? 0.0;
        _engagement['startSchedule'] = startStr;
        _engagement['endSchedule'] = endStr;
        _engagement['campus'] = campusStr;
        _engagement['categoryId'] = _editCategoryId ?? _engagement['categoryId'];
        _engagement['categoryName'] = _editCategoryName ?? _engagement['categoryName'];
        if (res['engagementImage'] != null) {
          _engagement['engagementImage'] = res['engagementImage'];
        }
        _isEditing = false;
        _newImage = null;
      });
      _showSnack('Engagement updated successfully!');
      widget.onUpdated?.call();
    } else {
      _showSnack(res['message'] ?? 'Update failed.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: isError ? AppTheme.redPink : const Color(0xFF2E7D5E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('MMMM d, yyyy hh:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final init = isStart ? (_editStart ?? now) : (_editEnd ?? _editStart ?? now);
    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.redPink)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.redPink)),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _editStart = combined;
        if (_editEnd != null && _editEnd!.isBefore(combined)) _editEnd = null;
      } else {
        _editEnd = combined;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) setState(() => _newImage = File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkGray.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Change Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _imageSourceBtn(Icons.camera_alt_rounded, 'Camera', AppTheme.redPink, () { Navigator.pop(context); _pickImage(ImageSource.camera); })),
                const SizedBox(width: 12),
                Expanded(child: _imageSourceBtn(Icons.photo_library_rounded, 'Gallery', const Color(0xFF1565C0), () { Navigator.pop(context); _pickImage(ImageSource.gallery); })),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildClickableContactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    if (value == '—' || value.trim().isEmpty) {
      return _buildDetailRow(icon, label, value, color);
    }

    final String trimmed = value.trim();
    final bool isEmail = trimmed.contains('@') && trimmed.contains('.');
    final bool isPhone = RegExp(r'^[\d\s\+\(\)\-]+$').hasMatch(trimmed);

    return GestureDetector(
      onTap: () async {
        if (isEmail) {
          final Uri emailUri = Uri(
            scheme: 'mailto',
            path: trimmed,
            queryParameters: {
              'subject': 'Inquiry from CiviCall App',
            },
          );
          if (await canLaunchUrl(emailUri)) {
            await launchUrl(emailUri);
          } else {
            _showSnack('No email app found', isError: true);
          }
        } else if (isPhone) {
          final Uri phoneUri = Uri(scheme: 'tel', path: trimmed.replaceAll(RegExp(r'\s+'), ''));
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          } else {
            _showSnack('Unable to make call', isError: true);
          }
        } else {
          _showSnack('No valid contact method detected', isError: true);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: AppTheme.redPink.withOpacity(0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _imageSourceBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.darkGray.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.category_outlined, color: AppTheme.redPink, size: 18)),
                        const SizedBox(width: 12),
                        const Text('Select Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.darkGray.withOpacity(0.08)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final id = cat['categoryId'] as int;
                    final name = cat['categoryName'] as String;
                    final isSelected = _editCategoryId == id;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.redPink.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppTheme.redPink.withOpacity(0.25)) : null,
                      ),
                      child: ListTile(
                        onTap: () { setState(() { _editCategoryId = id; _editCategoryName = name; }); Navigator.pop(context); },
                        leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: isSelected ? AppTheme.redPink.withOpacity(0.12) : AppTheme.darkGray.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.volunteer_activism_outlined, color: isSelected ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.45), size: 19)),
                        title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppTheme.redPink : AppTheme.darkGray, fontSize: 14)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.redPink, size: 20) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCampusPicker() {
    showDialog(
      context: context,
      builder: (ctx) {
        Set<int> tempSelected = Set.from(_editCampusIds);
        return StatefulBuilder(
          builder: (ctx, setS) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(color: AppTheme.redPink, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                    child: Row(
                      children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.school_rounded, color: Colors.white, size: 18)),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Target Campus', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _campuses.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (_, i) {
                        final campus = _campuses[i];
                        final id = campus['campusId'] as int;
                        final name = campus['campusName'] as String;
                        return CheckboxListTile(
                          value: tempSelected.contains(id),
                          onChanged: (val) { setS(() { if (val == true) { tempSelected.add(id); } else { tempSelected.remove(id); } }); },
                          title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.darkGray)),
                          activeColor: AppTheme.redPink,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ElevatedButton(
                      onPressed: () { setState(() => _editCampusIds = tempSelected); Navigator.pop(ctx); },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redPink, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = (_engagement['verificationStatus'] as int? ?? 0) == 1;
    final bool isOwner = (_engagement['uploaderId'] as int?) == widget.currentUserId;
    final bool canEdit = isOwner && !isVerified;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F9),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isVerified, canEdit),
            SliverToBoxAdapter(
              child: _isEditing
                  ? _buildEditForm()
                  : _buildDetailsView(isVerified, isOwner),
            ),
          ],
        ),
        bottomNavigationBar: _isEditing ? _buildEditBottomBar() : null,
      ),
    );
  }

  Widget _buildSliverAppBar(bool isVerified, bool canEdit) {
    final String? imageFile = _engagement['engagementImage'] as String?;
    final String imageUrl = (imageFile != null && imageFile.isNotEmpty)
        ? '${ApiService.apiUrl}civicall_add_engagement.php/../engagementImage/$imageFile'
        : '';
    final bool hasImage = imageUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.redPink,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (canEdit && !_isEditing)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
              onPressed: _enterEditMode,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            _isEditing && _newImage != null
                ? Image.file(_newImage!, fit: BoxFit.cover)
                : hasImage
                ? GestureDetector(
              onTap: () => showFullScreenImage(context, NetworkImage(imageUrl)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholderBg(),
              ),
            )
                : _imagePlaceholderBg(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.redPink,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text('Change Photo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_isEditing)
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusChip((_engagement['verificationStatus'] as int? ?? 0) == 1),
                    if (_isEnded) ...[
                      const SizedBox(height: 8),
                      _buildEndedChip(),
                    ] else if (_isNearEnd) ...[
                      const SizedBox(height: 8),
                      _buildNearEndChip(),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholderBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.redPink, AppTheme.redPink.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.volunteer_activism_outlined, color: Colors.white.withOpacity(0.3), size: 72),
      ),
    );
  }

  Widget _buildStatusChip(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFF2E7D5E) : const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified_rounded : Icons.pending_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(isVerified ? 'Verified' : 'Pending Verification', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildEndedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, color: Colors.white, size: 14),
          SizedBox(width: 5),
          Text('Ended', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildNearEndChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
          SizedBox(width: 5),
          Text('Ending Soon', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDetailsView(bool isVerified, bool isOwner) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryAndTitle(),
          const SizedBox(height: 20),
          _buildInfoCard(Icons.schedule_rounded, 'Schedule', [
            _buildDetailRow(Icons.play_circle_outline_rounded, 'Start', _formatDate(_engagement['startSchedule'] as String?), const Color(0xFF2E7D5E)),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.stop_circle_outlined, 'End', _formatDate(_engagement['endSchedule'] as String?), const Color(0xFF6A1B9A)),
          ]),
          const SizedBox(height: 12),
          _buildLocationCard(),
          const SizedBox(height: 12),
          if ((_engagement['description'] as String? ?? '').isNotEmpty)
            _buildTextCard(Icons.description_outlined, 'Description', _engagement['description'] ?? ''),
          if ((_engagement['objective'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTextCard(Icons.flag_outlined, 'Objective', _engagement['objective'] ?? ''),
          ],
          if ((_engagement['instruction'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTextCard(Icons.list_alt_outlined, 'Instructions', _engagement['instruction'] ?? ''),
          ],
          const SizedBox(height: 12),
          _buildInfoCard(Icons.people_outline_rounded, 'Participation Details', [
            _buildDetailRow(Icons.group_outlined, 'Target Participants', '${_engagement['targetParty'] ?? 0}', AppTheme.darkGray),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.star_outline_rounded, 'Activity Points', '${_engagement['activityPoints'] ?? 0}', const Color(0xFFF57C00)),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(Icons.person_outline_rounded, 'Facilitator', [
            _buildDetailRow(Icons.badge_outlined, 'Name', _engagement['facilitatorName'] ?? '—', AppTheme.darkGray),
            const SizedBox(height: 8),
            _buildClickableContactRow(
              icon: Icons.contact_phone_outlined,
              label: 'Contact',
              value: _engagement['facilitatorContact'] ?? '—',
              color: const Color(0xFF1565C0),
            ),
          ]),
          const SizedBox(height: 12),
          _buildCampusCard(),
          if (!isVerified && isOwner) ...[
            const SizedBox(height: 16),
            _buildOwnerNotice(),
          ],
          if (isVerified) ...[
            const SizedBox(height: 12),
            _buildParticipantsTile(context),
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ],
      ),
    );
  }
  Widget _buildCategoryAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.redPink.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined, color: AppTheme.redPink, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _engagement['categoryName'] as String? ?? 'General',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.redPink),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _engagement['titleEngagement'] ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.darkGray, height: 1.25),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, color: AppTheme.redPink, size: 17),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: AppTheme.darkGray.withOpacity(0.07)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkGray.withOpacity(0.45))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextCard(IconData icon, String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: AppTheme.redPink, size: 17)),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: TextStyle(fontSize: 14, color: AppTheme.darkGray.withOpacity(0.75), height: 1.55)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final double lat = (_engagement['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (_engagement['longitude'] as num?)?.toDouble() ?? 0.0;
    final bool hasCoords = lat != 0.0 || lng != 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.location_on_outlined, color: Color(0xFF1565C0), size: 17)),
                const SizedBox(width: 10),
                const Text('Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _engagement['locationAddress'] as String? ?? '—',
              style: TextStyle(fontSize: 14, color: AppTheme.darkGray.withOpacity(0.75), height: 1.45),
            ),
            if (hasCoords) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => LocationViewDialog(lat: lat, lng: lng)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 7),
                      Text('View on Map', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampusCard() {
    final String campusStr = _engagement['campus'] as String? ?? '';
    final List<String> campusIds = campusStr.split(',').where((s) => s.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.school_rounded, color: AppTheme.redPink, size: 17)),
                const SizedBox(width: 10),
                const Text('Target Campuses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: campusIds.isEmpty
                  ? [Text('—', style: TextStyle(color: AppTheme.darkGray.withOpacity(0.5)))]
                  : campusIds.map((id) {
                final campus = _campuses.firstWhere((c) => c['campusId'].toString() == id, orElse: () => {'campusName': 'Campus $id'});
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.redPink.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.redPink.withOpacity(0.18)),
                  ),
                  child: Text(campus['campusName'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.redPink)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildParticipantsTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _showParticipantsList(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.group_rounded, color: Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Participants', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
                    const SizedBox(height: 2),
                    _isJoinLoading
                        ? Text('Loading...', style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.45)))
                        : Text('$_participantCount joined', style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.55))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.darkGray.withOpacity(0.35), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (_isJoinLoading) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.redPink))),
      );
    }

    if (_isEnded) {
      final status = _attendanceDisplayStatus;
      if (_isJoined && (status == 'attended' || status == 'not_attended' || status == 'cancelled')) {
        final color = _statusColor(status);
        final icon = _statusIcon(status);
        final label = _statusLabel(status);
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        );
      }
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Engagement Ended',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
          ),
        ),
      );
    }

    if (_isJoined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () => _handleCancel(context),
          icon: const Icon(Icons.cancel_outlined, size: 20),
          label: const Text('Cancel Participation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.redPink,
            side: const BorderSide(color: AppTheme.redPink, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _handleJoin(context),
        icon: const Icon(Icons.volunteer_activism_rounded, size: 20),
        label: const Text('Join Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D5E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
  Widget _buildOwnerNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This engagement is pending admin verification. It is only visible to you until approved.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFFE65100), fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditSectionHeader(Icons.edit_note_rounded, 'Edit Engagement', 'Make changes below'),
          const SizedBox(height: 20),
          _buildEditCard('Basic Info', Icons.info_outline_rounded, [
            _editDropdownTile('Category', _editCategoryName ?? 'Select Category', Icons.category_outlined, _showCategoryPicker, required: true),
            const SizedBox(height: 14),
            _editField('Title', _titleCtrl, Icons.title_rounded, maxLines: 1, required: true),
            const SizedBox(height: 14),
            _editField('Description', _descCtrl, Icons.description_outlined, maxLines: 4, required: true),
            const SizedBox(height: 14),
            _editField('Objective', _objectiveCtrl, Icons.flag_outlined, maxLines: 3, required: true),
            const SizedBox(height: 14),
            _editField('Instructions', _instructionCtrl, Icons.list_alt_outlined, maxLines: 3, required: true),
          ]),
          const SizedBox(height: 14),
          _buildEditCard('Schedule', Icons.schedule_rounded, [
            _editDateTile('Start Date & Time', _editStart, () => _pickDateTime(true), const Color(0xFF2E7D5E), required: true),
            const SizedBox(height: 12),
            _editDateTile('End Date & Time', _editEnd, () => _pickDateTime(false), const Color(0xFF6A1B9A), required: true),
          ]),
          const SizedBox(height: 14),
          _buildEditCard('Location', Icons.location_on_outlined, [
            _editField('Address', _locationCtrl, Icons.location_on_outlined, maxLines: 2, required: true),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await showDialog<LatLng>(
                  context: context,
                  builder: (_) => LocationPickerDialog(initialLat: _editLat, initialLng: _editLng),
                );
                if (result != null) setState(() { _editLat = result.latitude; _editLng = result.longitude; });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Color(0xFF1565C0), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pin Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                          Text(
                            _editLat != null && _editLng != null ? '${_editLat!.toStringAsFixed(5)}, ${_editLng!.toStringAsFixed(5)}' : 'Tap to select on map',
                            style: TextStyle(fontSize: 11.5, color: const Color(0xFF1565C0).withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF1565C0), size: 18),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _buildEditCard('Participation', Icons.people_outline_rounded, [
            _editField('Target Participants', _targetCtrl, Icons.group_outlined, keyboardType: TextInputType.number, maxLines: 1, required: true),
            const SizedBox(height: 14),
            _editField('Activity Points', _pointsCtrl, Icons.star_outline_rounded, keyboardType: TextInputType.number, maxLines: 1, required: true),
          ]),
          const SizedBox(height: 14),
          _buildEditCard('Facilitator', Icons.person_outline_rounded, [
            _editField('Facilitator Name', _facilitatorCtrl, Icons.badge_outlined, maxLines: 1, required: true),
            const SizedBox(height: 14),
            _editField('Contact Number', _facilitatorContactCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone, maxLines: 1, required: true),
          ]),
          const SizedBox(height: 14),
          _buildEditCard('Target Campus', Icons.school_rounded, [
            _editDropdownTile(
              'Campuses',
              _editCampusIds.isEmpty ? 'Select campuses' : '${_editCampusIds.length} campus(es) selected',
              Icons.school_outlined,
              _showCampusPicker,
              required: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildEditSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE84757), AppTheme.redPink], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: AppTheme.redPink.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.darkGray)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.45))),
          ],
        ),
      ],
    );
  }

  Widget _buildEditCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 30, height: 30, decoration: BoxDecoration(color: AppTheme.redPink.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: AppTheme.redPink, size: 16)),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
            if (required) ...[
              const SizedBox(width: 3),
              const Text('*', style: TextStyle(color: AppTheme.redPink, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppTheme.darkGray, fontFamily: 'Lato'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.5), fontFamily: 'Lato'),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.darkGray.withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.redPink, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _editDropdownTile(String label, String value, IconData icon, VoidCallback onTap, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
            if (required) ...[
              const SizedBox(width: 3),
              const Text('*', style: TextStyle(color: AppTheme.redPink, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkGray.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.darkGray.withOpacity(0.4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.darkGray.withOpacity(0.5))),
                      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.darkGray)),
                    ],
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: AppTheme.darkGray.withOpacity(0.4), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _editDateTile(String label, DateTime? dateTime, VoidCallback onTap, Color color, {bool required = false}) {
    final String display = dateTime != null ? DateFormat('MMMM d, yyyy hh:mm a').format(dateTime) : 'Tap to select';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
            if (required) ...[
              const SizedBox(width: 3),
              const Text('*', style: TextStyle(color: AppTheme.redPink, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
                      Text(display, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dateTime != null ? AppTheme.darkGray : AppTheme.darkGray.withOpacity(0.4))),
                    ],
                  ),
                ),
                Icon(Icons.edit_calendar_rounded, color: color.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancelEdit,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppTheme.darkGray.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGray, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.redPink.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ParticipantsBottomSheet extends StatefulWidget {
  final int engagementId;
  final ApiService apiService;

  const _ParticipantsBottomSheet({required this.engagementId, required this.apiService});

  @override
  State<_ParticipantsBottomSheet> createState() => _ParticipantsBottomSheetState();
}

class _ParticipantsBottomSheetState extends State<_ParticipantsBottomSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _participants = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.apiService.getParticipants(engagementId: widget.engagementId);
    if (mounted) {
      setState(() {
        _participants = List<Map<String, dynamic>>.from(res['participants'] ?? []);
        _total = res['total'] as int? ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.darkGray.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.group_rounded, color: Color(0xFF1565C0), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Participants', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkGray)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.09), borderRadius: BorderRadius.circular(20)),
                    child: Text('$_total joined', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppTheme.darkGray.withOpacity(0.07)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.redPink, strokeWidth: 2))
                  : _participants.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off_rounded, size: 46, color: AppTheme.darkGray.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text('No participants yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.darkGray.withOpacity(0.4))),
                  ],
                ),
              )
                  : ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _participants.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: AppTheme.darkGray.withOpacity(0.06)),
                itemBuilder: (_, i) {
                  final p = _participants[i];
                  final photoUrl = p['photo_url'] as String?;
                  final name = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
                  final campus = p['campusName'] as String? ?? '—';
                  ImageProvider? img;
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
                      img = NetworkImage(photoUrl);
                    } else {
                      img = NetworkImage('${ApiService.apiUrl}profileImage/$photoUrl');
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (img != null) {
                              showFullScreenImage(context, img!);
                            }
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.darkGray.withOpacity(0.1), width: 1.5),
                              color: AppTheme.redPink.withOpacity(0.08),
                            ),
                            child: ClipOval(
                              child: img != null
                                  ? Image(
                                image: img!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppTheme.redPink, size: 24),
                              )
                                  : const Icon(Icons.person_rounded, color: AppTheme.redPink, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.isEmpty ? 'Unknown' : name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.darkGray)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 12, color: AppTheme.darkGray.withOpacity(0.45)),
                                  const SizedBox(width: 4),
                                  Text(campus, style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.55))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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