import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/imageViewer.dart';
import 'package:civicall/googleMap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddEngagementScreen extends StatefulWidget {
  const AddEngagementScreen({Key? key}) : super(key: key);

  @override
  State<AddEngagementScreen> createState() => _AddEngagementScreenState();
}

class _AddEngagementScreenState extends State<AddEngagementScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnim;

  int _currentPage = 0;
  static const int _totalPages = 4;
  bool _isSubmitting = false;

  Map<String, dynamic>? _userData;
  File? _pickedImage;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _campuses = [];

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  Set<int> _selectedCampusIds = {};
  int? _userCampusId;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();
  final _locationAddressCtrl = TextEditingController();
  final _targetParticipantsCtrl = TextEditingController();
  final _activityPointsCtrl = TextEditingController();
  final _facilitatorNameCtrl = TextEditingController();
  final _facilitatorContactCtrl = TextEditingController();

  double? _latitude;
  double? _longitude;
  DateTime? _startDate;
  DateTime? _endDate;

  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1 / _totalPages)
        .animate(CurvedAnimation(parent: _progressAnimController, curve: Curves.easeInOut));
    _progressAnimController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _objectiveCtrl.dispose();
    _instructionCtrl.dispose();
    _locationAddressCtrl.dispose();
    _targetParticipantsCtrl.dispose();
    _activityPointsCtrl.dispose();
    _facilitatorNameCtrl.dispose();
    _facilitatorContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userRes = await _apiService.getUserData();
    if (userRes['success'] == true && mounted) {
      final user = userRes['user'] as Map<String, dynamic>;
      setState(() {
        _userData = user;
        _userCampusId = user['campusId'] as int?;
        if (_userCampusId != null) _selectedCampusIds.add(_userCampusId!);
        final first = (user['firstName'] ?? '').toString().trim();
        final last = (user['lastName'] ?? '').toString().trim();
        _facilitatorNameCtrl.text = '$first $last'.trim();
      });
    }
    await _loadCategories();
    await _loadCampuses();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _apiService.fetchEngagementCategories();
      if (res['success'] == true && mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(res['categories'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCampuses() async {
    final res = await _apiService.fetchCampus();
    if (res['success'] == true && mounted) {
      setState(() {
        _campuses = List<Map<String, dynamic>>.from(res['campuses'] ?? []);
      });
    }
  }

  void _animateProgress(int toPage) {
    final target = (toPage + 1) / _totalPages;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(CurvedAnimation(parent: _progressAnimController, curve: Curves.easeInOut));
    _progressAnimController.forward(from: 0);
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    _animateProgress(page);
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool _validatePage1() {
    if (_pickedImage == null) {
      _showError('Please upload an engagement photo.');
      return false;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category.');
      return false;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Engagement title is required.');
      return false;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showError('Description is required.');
      return false;
    }
    if (_objectiveCtrl.text.trim().isEmpty) {
      _showError('Objective is required.');
      return false;
    }
    if (_instructionCtrl.text.trim().isEmpty) {
      _showError('Instructions are required.');
      return false;
    }
    return true;
  }

  bool _validatePage2() {
    if (_locationAddressCtrl.text.trim().isEmpty) {
      _showError('Location address is required.');
      return false;
    }
    if (_latitude == null || _longitude == null) {
      _showError('Please pin the location on the map.');
      return false;
    }
    if (_selectedCampusIds.isEmpty) {
      _showError('Please select at least one target campus.');
      return false;
    }
    final target = int.tryParse(_targetParticipantsCtrl.text.trim());
    if (target == null || target <= 0) {
      _showError('Target participants must be a positive number.');
      return false;
    }
    return true;
  }

  bool _validatePage3() {
    if (_startDate == null) {
      _showError('Please select a start date and time.');
      return false;
    }
    if (_startDate!.isBefore(DateTime.now())) {
      _showError('Start date & time must be in the future.');
      return false;
    }
    if (_endDate == null) {
      _showError('Please select an end date and time.');
      return false;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date & time must be after the start date & time.');
      return false;
    }
    final points = int.tryParse(_activityPointsCtrl.text.trim());
    if (points == null || points <= 0) {
      _showError('Activity points must be a positive number.');
      return false;
    }
    return true;
  }

  bool _validatePage4() {
    if (_facilitatorNameCtrl.text.trim().isEmpty) {
      _showError('Facilitator name is required.');
      return false;
    }
    if (_facilitatorContactCtrl.text.trim().isEmpty) {
      _showError('Facilitator contact is required.');
      return false;
    }
    return true;
  }

  void _nextPage() {
    bool isValid = false;
    if (_currentPage == 0) isValid = _validatePage1();
    else if (_currentPage == 1) isValid = _validatePage2();
    else if (_currentPage == 2) isValid = _validatePage3();
    else if (_currentPage == 3) isValid = _validatePage4();

    if (!isValid) return;

    if (_currentPage < _totalPages - 1) _goToPage(_currentPage + 1);
  }

  void _prevPage() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkGray.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Photo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a source for your engagement photo',
              style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _imageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    sublabel: 'Take a photo',
                    color: AppTheme.redPink,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _imageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    sublabel: 'Choose existing',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final initDate = isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final date = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.redPink),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.redPink),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (isStart) {
      if (combined.isBefore(now)) {
        _showError('Start date & time cannot be in the past.');
        return;
      }
      if (_endDate != null && combined.isAfter(_endDate!)) {
        _showError('Start date must be before the end date.');
        return;
      }
      setState(() {
        _startDate = combined;
        if (_endDate != null && _endDate!.isBefore(combined)) _endDate = null;
      });
    } else {
      if (_startDate == null) {
        _showError('Please select start date & time first.');
        return;
      }
      if (combined.isBefore(_startDate!)) {
        _showError('End date & time must be after the start date & time.');
        return;
      }
      setState(() {
        _endDate = combined;
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await showDialog<LatLng>(
      context: context,
      builder: (_) => LocationPickerDialog(
        initialLat: _latitude,
        initialLng: _longitude,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  void _showCampusDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        Set<int> tempSelected = Set.from(_selectedCampusIds);
        return StatefulBuilder(
          builder: (ctx, setS) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(
                      color: AppTheme.redPink,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Select Target Campus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _campuses.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (_, i) {
                        final campus = _campuses[i];
                        final id = campus['campusId'] as int;
                        final name = campus['campusName'] as String;
                        final isUserCampus = id == _userCampusId;
                        final isSelected = tempSelected.contains(id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: isUserCampus
                              ? null
                              : (val) {
                            setS(() {
                              if (val == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isUserCampus ? FontWeight.w700 : FontWeight.w500,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ),
                              if (isUserCampus)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.redPink.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Your Campus',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.redPink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          activeColor: AppTheme.redPink,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedCampusIds = tempSelected);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.redPink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Selection', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _submitEngagement() async {
    if (!_validatePage1()) return;
    if (!_validatePage2()) return;
    if (!_validatePage3()) return;
    if (!_validatePage4()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final campusStr = _selectedCampusIds.join(',');
      final startStr = _startDate != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate!)
          : '';
      final endStr = _endDate != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate!)
          : '';

      final res = await _apiService.addEngagement(
        categoryId: _selectedCategoryId ?? 0,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        objective: _objectiveCtrl.text.trim(),
        instruction: _instructionCtrl.text.trim(),
        locationAddress: _locationAddressCtrl.text.trim(),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        startSchedule: startStr,
        endSchedule: endStr,
        campus: campusStr,
        targetParty: int.tryParse(_targetParticipantsCtrl.text) ?? 0,
        activityPoints: int.tryParse(_activityPointsCtrl.text) ?? 0,
        facilitatorName: _facilitatorNameCtrl.text.trim(),
        facilitatorContact: _facilitatorContactCtrl.text.trim(),
        imageFile: _pickedImage,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Engagement posted successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D5E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        _showError(res['message'] ?? 'Failed to post engagement.');
      }
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AppTheme.redPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPhotoPreview() {
    if (_pickedImage != null) {
      showFullScreenImage(context, FileImage(_pickedImage!));
    }
  }

  void _showLocationPreview() {
    if (_latitude != null && _longitude != null) {
      showDialog(
        context: context,
        builder: (_) => LocationViewDialog(
          lat: _latitude!,
          lng: _longitude!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.redPink,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F9),
        body: Column(
          children: [
            _buildAppBar(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final stepTitles = ['Engagement Details', 'Location & Reach', 'Schedule & Points', 'Facilitator & Review'];
    final stepSubtitles = [
      'Basic info & photo',
      'Venue, map & campus',
      'Dates, timing & rewards',
      'Final check before submit',
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.redPink,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Add Engagement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepTitles[_currentPage],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        stepSubtitles[_currentPage],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
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
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Details', 'Location', 'Schedule', 'Review'];
    return Container(
      color: AppTheme.redPink,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentPage;
          final isDone = i < _currentPage;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: i <= _currentPage
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 30 : 24,
                            height: isActive ? 30 : 24,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.white
                                  : isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              boxShadow: isActive
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                                  : [],
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: AppTheme.redPink, size: 14)
                                  : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive ? AppTheme.redPink : Colors.white.withOpacity(0.7),
                                  fontSize: isActive ? 13 : 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (i < steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: i < _currentPage
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageUploader(),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                children: [
                  _buildDropdownCard(
                    label: 'Category',
                    icon: Icons.category_outlined,
                    hint: 'Select engagement category',
                    value: _selectedCategoryName,
                    required: true,
                    onTap: _showCategoryPicker,
                  ),
                  _buildDivider(),
                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'Engagement Title',
                    icon: Icons.title_rounded,
                    hint: 'e.g. Community Tree Planting Drive',
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Title is required' : null,
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _descCtrl,
                    label: 'Description',
                    icon: Icons.description_outlined,
                    hint: 'Describe the engagement activity in detail...',
                    maxLines: 3,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Description is required' : null,
                    required: true,
                  ),
                  _buildDivider(),
                  _buildTextField(
                    controller: _objectiveCtrl,
                    label: 'Objective',
                    icon: Icons.flag_outlined,
                    hint: 'What is the goal of this engagement?',
                    maxLines: 2,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Objective is required' : null,
                    required: true,
                  ),
                  _buildDivider(),
                  _buildTextField(
                    controller: _instructionCtrl,
                    label: 'Instructions',
                    icon: Icons.list_alt_rounded,
                    hint: 'Provide step-by-step instructions for participants...',
                    maxLines: 3,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Instructions are required' : null,
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _locationAddressCtrl,
                    label: 'Location Address',
                    icon: Icons.place_outlined,
                    hint: 'e.g. Barangay Hall, Calamba, Laguna',
                    maxLines: 2,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Location address is required' : null,
                    required: true,
                  ),
                  _buildDivider(),
                  _buildLocationPinRow(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildCampusRow(),
                  _buildDivider(),
                  _buildTextField(
                    controller: _targetParticipantsCtrl,
                    label: 'Target Participants',
                    icon: Icons.group_outlined,
                    hint: 'How many volunteers needed?',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Required';
                      final val = int.tryParse(v!.trim());
                      if (val == null || val <= 0) return 'Must be a positive number';
                      return null;
                    },
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              child: Column(
                children: [
                  _buildDateRow(
                    label: 'Start Date & Time',
                    icon: Icons.event_available_outlined,
                    value: _startDate,
                    isStart: true,
                    required: true,
                  ),
                  _buildDivider(),
                  _buildDateRow(
                    label: 'End Date & Time',
                    icon: Icons.event_busy_outlined,
                    value: _endDate,
                    isStart: false,
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: _buildTextField(
                controller: _activityPointsCtrl,
                label: 'Activity Points',
                icon: Icons.star_outline_rounded,
                hint: 'Points earned after participating',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  final val = int.tryParse(v!.trim());
                  if (val == null || val <= 0) return 'Must be a positive number';
                  return null;
                },
                required: true,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _facilitatorNameCtrl,
                    label: "Facilitator's Name",
                    icon: Icons.badge_outlined,
                    hint: 'Full name of the facilitator',
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    required: true,
                  ),
                  _buildDivider(),
                  _buildTextField(
                    controller: _facilitatorContactCtrl,
                    label: "Facilitator's Contact / Email",
                    icon: Icons.contact_phone_outlined,
                    hint: 'Contact number or email address',
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildReviewCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppTheme.darkGray.withOpacity(0.08)),
    );
  }

  Widget _buildImageUploader() {
    return GestureDetector(
      onTap: _pickedImage == null ? _showImageSourceSheet : null,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pickedImage != null
                ? AppTheme.redPink.withOpacity(0.3)
                : AppTheme.darkGray.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _pickedImage != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: GestureDetector(
                onTap: () => showFullScreenImage(
                  context,
                  FileImage(_pickedImage!),
                ),
                child: Image.file(_pickedImage!, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _imageActionBtn(
                    icon: Icons.edit_rounded,
                    onTap: _showImageSourceSheet,
                    color: Colors.white,
                    bgColor: AppTheme.darkGray.withOpacity(0.75),
                  ),
                  const SizedBox(width: 6),
                  _imageActionBtn(
                    icon: Icons.close_rounded,
                    onTap: () => setState(() => _pickedImage = null),
                    color: Colors.white,
                    bgColor: AppTheme.redPink.withOpacity(0.9),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Tap to preview', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.redPink, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload Engagement Photo',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.darkGray, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Required — tap to capture or choose from gallery',
              style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageActionBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.darkGray.withOpacity(0.35), fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(icon, color: AppTheme.darkGray.withOpacity(0.45), size: 20),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.redPink, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGray,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*', style: TextStyle(color: AppTheme.redPink, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required IconData icon,
    required String hint,
    required String? value,
    bool required = false,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null
                    ? AppTheme.redPink.withOpacity(0.35)
                    : AppTheme.darkGray.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value != null ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.45),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                      color: value != null ? AppTheme.darkGray : AppTheme.darkGray.withOpacity(0.38),
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray.withOpacity(0.45), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPinRow() {
    final hasPinned = _latitude != null && _longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pin on Map',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkGray),
            ),
            const SizedBox(width: 3),
            const Text('*', style: TextStyle(color: AppTheme.redPink, fontSize: 13)),
            const SizedBox(width: 6),
            if (hasPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D5E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Pinned',
                  style: TextStyle(fontSize: 10, color: Color(0xFF2E7D5E), fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: hasPinned ? AppTheme.redPink.withOpacity(0.04) : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasPinned ? AppTheme.redPink.withOpacity(0.35) : AppTheme.darkGray.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasPinned ? AppTheme.redPink.withOpacity(0.12) : AppTheme.darkGray.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasPinned ? Icons.location_on_rounded : Icons.add_location_alt_outlined,
                    color: hasPinned ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.45),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasPinned
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location pinned',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkGray, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 11, color: AppTheme.darkGray.withOpacity(0.5)),
                      ),
                    ],
                  )
                      : Text(
                    'Tap to pin exact location on map',
                    style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.45)),
                  ),
                ),
                Icon(
                  hasPinned ? Icons.edit_location_alt_outlined : Icons.chevron_right_rounded,
                  color: hasPinned ? AppTheme.redPink.withOpacity(0.7) : AppTheme.darkGray.withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampusRow() {
    final selectedNames = _campuses
        .where((c) => _selectedCampusIds.contains(c['campusId'] as int))
        .map((c) => c['campusName'] as String)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Target Campus',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkGray),
            ),
            const SizedBox(width: 3),
            const Text('*', style: TextStyle(color: AppTheme.redPink, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCampusDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selectedNames.isNotEmpty ? AppTheme.redPink.withOpacity(0.04) : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedNames.isNotEmpty
                    ? AppTheme.redPink.withOpacity(0.35)
                    : AppTheme.darkGray.withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.school_outlined,
                  color: selectedNames.isNotEmpty ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.45),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: selectedNames.isEmpty
                      ? Text(
                    'Select target campus',
                    style: TextStyle(fontSize: 14, color: AppTheme.darkGray.withOpacity(0.38)),
                  )
                      : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedNames
                        .map((name) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.redPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.redPink, fontWeight: FontWeight.w600),
                      ),
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray.withOpacity(0.45), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow({
    required String label,
    required IconData icon,
    required DateTime? value,
    required bool isStart,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDateTime(isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: value != null ? AppTheme.redPink.withOpacity(0.04) : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null ? AppTheme.redPink.withOpacity(0.35) : AppTheme.darkGray.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value != null ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.45),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('MMM dd, yyyy  •  hh:mm a').format(value)
                        : 'Select date and time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                      color: value != null ? AppTheme.darkGray : AppTheme.darkGray.withOpacity(0.38),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded, color: AppTheme.darkGray.withOpacity(0.35), size: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    final fmt = DateFormat('MMM dd, yyyy  •  hh:mm a');
    final selectedCampusNames = _campuses
        .where((c) => _selectedCampusIds.contains(c['campusId'] as int))
        .map((c) => c['campusName'] as String)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppTheme.redPink,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submission Summary',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      'Review all details before submitting',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildReviewSection(
            sectionLabel: 'ENGAGEMENT',
            items: [
              _ReviewItem(icon: Icons.title_rounded, label: 'Title', value: _titleCtrl.text.trim()),
              _ReviewItem(icon: Icons.category_outlined, label: 'Category', value: _selectedCategoryName ?? '—'),
              _ReviewItem(icon: Icons.description_outlined, label: 'Description', value: _descCtrl.text.trim()),
              _ReviewItem(icon: Icons.flag_outlined, label: 'Objective', value: _objectiveCtrl.text.trim()),
              _ReviewItem(icon: Icons.list_alt_rounded, label: 'Instructions', value: _instructionCtrl.text.trim()),
              _ReviewItem(
                icon: Icons.image_outlined,
                label: 'Photo',
                value: _pickedImage != null ? 'Photo attached' : 'No photo',
                isSuccess: _pickedImage != null,
              ),
            ],
          ),
          _buildReviewSectionDivider(),
          _buildReviewSection(
            sectionLabel: 'LOCATION & REACH',
            items: [
              _ReviewItem(icon: Icons.place_outlined, label: 'Address', value: _locationAddressCtrl.text.trim()),
              _ReviewItem(
                icon: Icons.location_on_rounded,
                label: 'Coordinates',
                value: _latitude != null
                    ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                    : 'Not pinned',
                isSuccess: _latitude != null,
              ),
              _ReviewItem(icon: Icons.school_outlined, label: 'Campus', value: selectedCampusNames.isEmpty ? '—' : selectedCampusNames),
              _ReviewItem(
                icon: Icons.group_outlined,
                label: 'Target Participants',
                value: _targetParticipantsCtrl.text.trim().isEmpty ? '—' : _targetParticipantsCtrl.text.trim(),
              ),
            ],
          ),
          _buildReviewSectionDivider(),
          _buildReviewSection(
            sectionLabel: 'SCHEDULE & POINTS',
            items: [
              _ReviewItem(
                icon: Icons.event_available_outlined,
                label: 'Start',
                value: _startDate != null ? fmt.format(_startDate!) : '—',
              ),
              _ReviewItem(
                icon: Icons.event_busy_outlined,
                label: 'End',
                value: _endDate != null ? fmt.format(_endDate!) : '—',
              ),
              _ReviewItem(
                icon: Icons.star_outline_rounded,
                label: 'Activity Points',
                value: _activityPointsCtrl.text.trim().isEmpty ? '—' : _activityPointsCtrl.text.trim(),
              ),
            ],
          ),
          _buildReviewSectionDivider(),
          _buildReviewSection(
            sectionLabel: 'FACILITATOR',
            items: [
              _ReviewItem(icon: Icons.badge_outlined, label: 'Name', value: _facilitatorNameCtrl.text.trim()),
              _ReviewItem(icon: Icons.contact_phone_outlined, label: 'Contact', value: _facilitatorContactCtrl.text.trim()),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildReviewSection({required String sectionLabel, required List<_ReviewItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            sectionLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.redPink.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildReviewRow(item)),
      ],
    );
  }

  Widget _buildReviewSectionDivider() {
    return Divider(height: 1, color: AppTheme.darkGray.withOpacity(0.07), indent: 16, endIndent: 16);
  }

  Widget _buildReviewRow(_ReviewItem item) {
    final isEmpty = item.value.trim().isEmpty || item.value == '—';
    final bool canTap = (item.label == 'Photo' && _pickedImage != null) ||
        (item.label == 'Coordinates' && _latitude != null && _longitude != null);

    Widget rowContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isEmpty
                  ? AppTheme.darkGray.withOpacity(0.05)
                  : item.isSuccess == true
                  ? const Color(0xFF2E7D5E).withOpacity(0.1)
                  : AppTheme.redPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 14,
              color: isEmpty
                  ? AppTheme.darkGray.withOpacity(0.3)
                  : item.isSuccess == true
                  ? const Color(0xFF2E7D5E)
                  : AppTheme.redPink.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkGray.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? '—' : item.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? AppTheme.darkGray.withOpacity(0.28) : AppTheme.darkGray,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canTap)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.redPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      size: 12,
                      color: AppTheme.redPink,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (canTap) {
      return InkWell(
        onTap: () {
          if (item.label == 'Photo') {
            _showPhotoPreview();
          } else if (item.label == 'Coordinates') {
            _showLocationPreview();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: rowContent,
      );
    }
    return rowContent;
  }

  Widget _buildBottomNav() {
    final isLastPage = _currentPage == _totalPages - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  side: BorderSide(color: AppTheme.darkGray.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 17, color: AppTheme.darkGray),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: AppTheme.darkGray, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : (isLastPage ? _submitEngagement : _nextPage),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.redPink.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? 'Submit Engagement' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    if (_categories.isEmpty) {
      _showError('Categories not loaded yet. Please wait.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.darkGray.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.redPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.category_outlined, color: AppTheme.redPink, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Category',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
                            ),
                            Text(
                              'Choose the engagement type',
                              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                    final isSelected = _selectedCategoryId == id;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.redPink.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.redPink.withOpacity(0.25))
                            : null,
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = id;
                            _selectedCategoryName = name;
                          });
                          Navigator.pop(context);
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.redPink.withOpacity(0.12)
                                : AppTheme.darkGray.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.volunteer_activism_outlined,
                            color: isSelected ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.45),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.redPink : AppTheme.darkGray,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.redPink, size: 20)
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
}

class _ReviewItem {
  final IconData icon;
  final String label;
  final String value;
  final bool? isSuccess;
  const _ReviewItem({required this.icon, required this.label, required this.value, this.isSuccess});
}