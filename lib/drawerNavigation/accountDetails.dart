import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/anim/skeletonAnimation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onProfileUpdated;

  const AccountDetailsScreen({
    Key? key,
    this.userData,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  File? _pendingImageFile;

  List<Map<String, dynamic>> _campuses = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _nstpList = [];

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _mobileNumCtrl;
  late TextEditingController _emergencyNumCtrl;
  late TextEditingController _srCodeCtrl;
  late TextEditingController _yrSectionCtrl;

  int? _selectedCampusId;
  int? _selectedDepartmentId;
  int? _selectedCourseId;
  int? _selectedNstpId;
  int? _selectedUserCategory;
  int? _selectedGender;
  DateTime? _selectedBirthDay;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _middleNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _mobileNumCtrl = TextEditingController();
    _emergencyNumCtrl = TextEditingController();
    _srCodeCtrl = TextEditingController();
    _yrSectionCtrl = TextEditingController();

    if (widget.userData != null) {
      _userData = widget.userData;
      _populateFields();
    }
    _loadData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _mobileNumCtrl.dispose();
    _emergencyNumCtrl.dispose();
    _srCodeCtrl.dispose();
    _yrSectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.getUserData(),
      _apiService.fetchDropdowns(),
    ]);

    if (mounted) {
      final userRes = results[0];
      final dropRes = results[1];

      if (dropRes['success'] == true) {
        _campuses = List<Map<String, dynamic>>.from(dropRes['campuses'] ?? []);
        _departments = List<Map<String, dynamic>>.from(dropRes['departments'] ?? []);
        _courses = List<Map<String, dynamic>>.from(dropRes['courses'] ?? []);
        _nstpList = List<Map<String, dynamic>>.from(dropRes['nstp'] ?? []);
      }

      if (userRes['success'] == true) {
        _userData = userRes['user'] as Map<String, dynamic>;
        _populateFields();
      }

      setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    final u = _userData!;
    _firstNameCtrl.text = u['firstName'] ?? '';
    _middleNameCtrl.text = u['middleName'] ?? '';
    _lastNameCtrl.text = u['lastName'] ?? '';
    _addressCtrl.text = u['address'] ?? '';
    _mobileNumCtrl.text = u['mobileNum'] ?? '';
    _emergencyNumCtrl.text = u['emergencyNum'] ?? '';
    _srCodeCtrl.text = u['srCode'] ?? '';
    _yrSectionCtrl.text = u['yrSection'] ?? '';
    final rawCampus = u['campusId'] != null ? (u['campusId'] as num).toInt() : null;
    _selectedCampusId = (_campuses.any((c) => c['id'] == rawCampus)) ? rawCampus : null;
    final rawDept = u['departmentId'] != null ? (u['departmentId'] as num).toInt() : null;
    _selectedDepartmentId = (_departments.any((d) => d['id'] == rawDept)) ? rawDept : null;
    final rawCourse = u['courseId'] != null ? (u['courseId'] as num).toInt() : null;
    _selectedCourseId = (_courses.any((c) => c['id'] == rawCourse)) ? rawCourse : null;
    final rawNstp = u['nstpId'] != null ? (u['nstpId'] as num).toInt() : null;
    _selectedNstpId = (_nstpList.any((n) => n['id'] == rawNstp)) ? rawNstp : null;
    final rawCategory = u['userCategory'] != null ? (u['userCategory'] as num).toInt() : null;
    _selectedUserCategory = (rawCategory == 0 || rawCategory == 1) ? rawCategory : null;
    final rawGender = u['gender'] != null ? (u['gender'] as num).toInt() : null;
    _selectedGender = (rawGender == 0 || rawGender == 1) ? rawGender : null;
    if (u['birthDay'] != null && u['birthDay'].toString().isNotEmpty) {
      try {
        _selectedBirthDay = DateTime.parse(u['birthDay'].toString());
      } catch (_) {}
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;
      final file = File(picked.path);
      setState(() {
        _pendingImageFile = file;
        _isUploadingPhoto = true;
      });
      await _uploadProfilePhoto(file);
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to pick image.',
          backgroundColor: AppTheme.redPink,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _uploadProfilePhoto(File file) async {
    final result = await _apiService.uploadProfilePhoto(file);
    if (!mounted) return;
    if (result['success'] == true) {
      final newFileName = result['photo_url']?.toString() ?? '';
      setState(() {
        _isUploadingPhoto = false;
        _pendingImageFile = null;
        if (_userData != null && newFileName.isNotEmpty) {
          _userData!['photo_url'] = newFileName;
        }
      });
      widget.onProfileUpdated?.call();
      Fluttertoast.showToast(
        msg: 'Profile photo updated.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      setState(() {
        _isUploadingPhoto = false;
        _pendingImageFile = null;
      });
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Failed to upload photo.',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
    }
  }

  void _showFullScreenImage() {
    final imageProvider = _resolveProfileImage();
    if (imageProvider == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
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
              'Change Profile Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppTheme.redPink,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final result = await _apiService.updateUserProfile(
      firstName: _firstNameCtrl.text.trim(),
      middleName: _middleNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      mobileNum: _mobileNumCtrl.text.trim(),
      emergencyNum: _emergencyNumCtrl.text.trim(),
      campusId: _selectedCampusId,
      departmentId: _selectedDepartmentId,
      courseId: _selectedCourseId,
      userCategory: _selectedUserCategory,
      birthDay: _selectedBirthDay != null
          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDay!)
          : null,
      gender: _selectedGender,
      nstpId: _selectedNstpId,
      srCode: _srCodeCtrl.text.trim(),
      yrSection: _yrSectionCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Profile updated successfully.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        widget.onProfileUpdated?.call();
        await _loadData();
        setState(() => _isEditing = false);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to update profile.',
          backgroundColor: AppTheme.redPink,
          textColor: Colors.white,
        );
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  ImageProvider? _resolveProfileImage() {
    if (_pendingImageFile != null) return FileImage(_pendingImageFile!);
    final raw = _userData?['photo_url'];
    if (raw == null) return null;
    final url = raw.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return NetworkImage('${ApiService.apiUrl}profileImage/$url');
  }

  bool get _isVerified => (_userData?['isVerified'] ?? 0) == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? const AccountDetailsSkeleton()
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _isEditing ? _buildEditForm() : _buildViewMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.redPink,
      foregroundColor: AppTheme.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          if (_isEditing) {
            setState(() => _isEditing = false);
            _populateFields();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        if (!_isEditing)
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.white),
            label: const Text('Edit', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
          )
        else
          TextButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _populateFields();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.white.withOpacity(0.85), fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHeader(),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final imageProvider = _resolveProfileImage();
    final signupType = (_userData?['signup_type'] ?? 0) as int;
    final createdAt = _userData?['created_at']?.toString() ?? '';

    return Container(
      color: AppTheme.redPink,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _isEditing
                    ? (_isUploadingPhoto ? null : _showImageSourceSheet)
                    : (_isUploadingPhoto ? null : _showFullScreenImage),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isEditing
                              ? AppTheme.white
                              : AppTheme.white.withOpacity(0.6),
                          width: _isEditing ? 3.5 : 3,
                        ),
                        color: AppTheme.white.withOpacity(0.2),
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? Container(
                          color: AppTheme.white.withOpacity(0.2),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: AppTheme.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        )
                            : imageProvider != null
                            ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                            : _avatarFallback(),
                      ),
                    ),
                    if (_isEditing && !_isUploadingPhoto)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.35),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.white,
                          size: 26,
                        ),
                      ),
                  ],
                ),
              ),
              if (!_isEditing)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _isVerified ? Colors.green.shade400 : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.white, width: 2),
                  ),
                  child: Icon(
                    _isVerified ? Icons.verified_rounded : Icons.close_rounded,
                    size: 14,
                    color: AppTheme.white,
                  ),
                ),
            ],
          ),
          if (_isEditing && !_isUploadingPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tap to change photo',
                style: TextStyle(
                  color: AppTheme.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim(),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData?['email'] ?? '',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(
                signupType == 1 ? 'Google Sign-In' : 'Email Registered',
                signupType == 1 ? Icons.g_mobiledata : Icons.email_outlined,
              ),
              const SizedBox(width: 8),
              if (createdAt.isNotEmpty)
                _buildBadge('Joined ${_formatDate(createdAt)}', Icons.calendar_today_outlined),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppTheme.white.withOpacity(0.2),
      child: const Icon(Icons.person_rounded, size: 44, color: AppTheme.white),
    );
  }

  Widget _buildViewMode() {
    final u = _userData ?? {};
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('Personal Information', [
            _buildInfoTile(Icons.person_outline_rounded, 'First Name', u['firstName']),
            _buildInfoTile(Icons.person_outline_rounded, 'Middle Name', u['middleName']),
            _buildInfoTile(Icons.person_outline_rounded, 'Last Name', u['lastName']),
            _buildInfoTile(Icons.cake_outlined, 'Birthday', _formatDate(u['birthDay']?.toString())),
            _buildInfoTile(
              Icons.wc_outlined,
              'Gender',
              u['gender'] != null
                  ? (u['gender'].toString() == '0' ? 'Male' : 'Female')
                  : null,
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('Contact Information', [
            _buildInfoTile(Icons.phone_outlined, 'Mobile Number', u['mobileNum']),
            _buildInfoTile(Icons.emergency_outlined, 'Emergency Number', u['emergencyNum']),
            _buildInfoTile(Icons.location_on_outlined, 'Address', u['address']),
          ]),
          const SizedBox(height: 16),
          _buildSection('Academic Information', [
            _buildInfoTile(Icons.school_outlined, 'Campus', u['campusName']),
            _buildInfoTile(Icons.domain_outlined, 'Department', u['departmentName']),
            _buildInfoTile(Icons.book_outlined, 'Course', u['courseName']),
            _buildInfoTile(
              Icons.category_outlined,
              'Category',
              u['userCategory'] != null
                  ? (u['userCategory'].toString() == '0' ? 'Student' : 'Alumni')
                  : null,
            ),
            _buildInfoTile(Icons.badge_outlined, 'SR-Code', u['srCode']),
            _buildInfoTile(Icons.group_outlined, 'Year & Section', u['yrSection']),
            _buildInfoTile(Icons.military_tech_outlined, 'NSTP', u['nstpType']),
          ]),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.redPink,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, dynamic value) {
    final display = (value == null || value.toString().trim().isEmpty) ? '—' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.redPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppTheme.redPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray.withOpacity(0.45),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: display == '—'
                          ? AppTheme.darkGray.withOpacity(0.3)
                          : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEditSection('Personal Information', [
              _buildTextField(
                controller: _firstNameCtrl,
                label: 'First Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              _buildTextField(
                controller: _middleNameCtrl,
                label: 'Middle Name',
                icon: Icons.person_outline_rounded,
              ),
              _buildTextField(
                controller: _lastNameCtrl,
                label: 'Last Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              _buildDatePicker(),
              _buildDropdownField<int>(
                label: 'Gender',
                icon: Icons.wc_outlined,
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Male')),
                  DropdownMenuItem(value: 1, child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
            ]),
            const SizedBox(height: 16),
            _buildEditSection('Contact Information', [
              _buildTextField(
                controller: _mobileNumCtrl,
                label: 'Mobile Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _emergencyNumCtrl,
                label: 'Emergency Number',
                icon: Icons.emergency_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _addressCtrl,
                label: 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
            ]),
            const SizedBox(height: 16),
            _buildEditSection('Academic Information', [
              _buildDropdownField<int>(
                label: 'Campus',
                icon: Icons.school_outlined,
                value: _selectedCampusId,
                items: _campuses
                    .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name'].toString()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCampusId = v),
              ),
              _buildDropdownField<int>(
                label: 'Department',
                icon: Icons.domain_outlined,
                value: _selectedDepartmentId,
                items: _departments
                    .map((d) => DropdownMenuItem<int>(
                  value: d['id'] as int,
                  child: Text(d['name'].toString()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDepartmentId = v),
              ),
              _buildDropdownField<int>(
                label: 'Course',
                icon: Icons.book_outlined,
                value: _selectedCourseId,
                items: _courses
                    .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name'].toString()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourseId = v),
              ),
              _buildDropdownField<int>(
                label: 'Category',
                icon: Icons.category_outlined,
                value: _selectedUserCategory,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Student')),
                  DropdownMenuItem(value: 1, child: Text('Alumni')),
                ],
                onChanged: (v) => setState(() => _selectedUserCategory = v),
              ),
              _buildTextField(
                controller: _srCodeCtrl,
                label: 'SR-Code',
                icon: Icons.badge_outlined,
              ),
              _buildTextField(
                controller: _yrSectionCtrl,
                label: 'Year & Section',
                icon: Icons.group_outlined,
              ),
              _buildDropdownField<int>(
                label: 'NSTP',
                icon: Icons.military_tech_outlined,
                value: _selectedNstpId,
                items: _nstpList
                    .map((n) => DropdownMenuItem<int>(
                  value: n['id'] as int,
                  child: Text(n['name'].toString()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedNstpId = v),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.redPink,
                  foregroundColor: AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.redPink,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 19, color: AppTheme.darkGray.withOpacity(0.5)),
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.redPink, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: TextStyle(
            fontSize: 13.5,
            color: AppTheme.darkGray.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 19, color: AppTheme.darkGray.withOpacity(0.5)),
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.redPink, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: TextStyle(
            fontSize: 13.5,
            color: AppTheme.darkGray.withOpacity(0.6),
          ),
        ),
        style: const TextStyle(
          fontSize: 14.5,
          color: AppTheme.darkGray,
          fontFamily: AppTheme.fontFamily,
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray.withOpacity(0.4)),
        dropdownColor: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildDatePicker() {
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 5, now.month, now.day);
    final defaultInitial = DateTime(now.year - 18, now.month, now.day);
    final initial = (_selectedBirthDay != null && _selectedBirthDay!.isBefore(lastDate))
        ? _selectedBirthDay!
        : defaultInitial;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1940),
              lastDate: lastDate,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.redPink,
                      onPrimary: AppTheme.white,
                      onSurface: AppTheme.darkGray,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: AppTheme.redPink),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedBirthDay = picked);
            }
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkGray.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, size: 19, color: AppTheme.darkGray.withOpacity(0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthDay != null
                        ? DateFormat('MMMM d, yyyy').format(_selectedBirthDay!)
                        : 'Birthday',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: _selectedBirthDay != null
                          ? AppTheme.darkGray
                          : AppTheme.darkGray.withOpacity(0.45),
                    ),
                  ),
                ),
                Icon(Icons.edit_calendar_outlined, size: 18, color: AppTheme.redPink.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}