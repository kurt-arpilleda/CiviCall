import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/imageViewer.dart';

class AddForumScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const AddForumScreen({Key? key, this.onPostCreated}) : super(key: key);

  @override
  State<AddForumScreen> createState() => _AddForumScreenState();
}

class _AddForumScreenState extends State<AddForumScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const int _maxChars = 1000;

  File? _pickedImage;
  bool _isSubmitting = false;
  bool _hasText = false;

  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  List<Map<String, dynamic>> _campuses = [];
  Set<int> _selectedCampusIds = {};
  int? _userCampusId;

  late AnimationController _postBtnAnim;
  late Animation<double> _postBtnScale;
  late AnimationController _imageAnim;
  late Animation<double> _imageFade;
  late AnimationController _entranceAnim;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _postBtnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _postBtnScale = CurvedAnimation(parent: _postBtnAnim, curve: Curves.elasticOut);

    _imageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _imageFade = CurvedAnimation(parent: _imageAnim, curve: Curves.easeOut);

    _entranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entranceFade = CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOutCubic));

    _messageController.addListener(_onTextChanged);
    _loadUserAndCampuses();
    _entranceAnim.forward();
  }

  Future<void> _loadUserAndCampuses() async {
    final userRes = await _apiService.getUserData();
    final campusRes = await _apiService.fetchCampus();

    if (mounted) {
      setState(() {
        if (userRes['success'] == true) {
          _userData = userRes['user'] as Map<String, dynamic>?;
          _userCampusId = _userData?['campusId'] as int?;
          if (_userCampusId != null) {
            _selectedCampusIds.add(_userCampusId!);
          }
        }
        if (campusRes['success'] == true) {
          _campuses = List<Map<String, dynamic>>.from(campusRes['campuses'] ?? []);
        }
        _isLoadingUser = false;
      });
    }
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      _syncPostButton();
    } else {
      setState(() {});
    }
  }

  void _syncPostButton() {
    if (_hasText || _pickedImage != null) {
      _postBtnAnim.forward();
    } else {
      _postBtnAnim.reverse();
    }
  }

  String get _fullName {
    if (_userData == null) return '';
    final first = (_userData!['firstName'] ?? '').toString().trim();
    final last = (_userData!['lastName'] ?? '').toString().trim();
    return '$first $last'.trim();
  }

  String get _campusName {
    final raw = (_userData?['campusName'] ?? '').toString().trim();
    return raw.isNotEmpty ? raw : 'Campus Community';
  }

  bool get _isVerifiedUser => (_userData?['isVerified'] ?? 0) == 1;

  ImageProvider? get _profileImage {
    final raw = _userData?['photo_url'];
    if (raw == null) return null;
    final url = raw.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return NetworkImage('${ApiService.apiUrl}profileImage/$url');
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _focusNode.dispose();
    _postBtnAnim.dispose();
    _imageAnim.dispose();
    _entranceAnim.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 88);
    if (picked != null && mounted) {
      setState(() {
        _pickedImage = File(picked.path);
      });
      _imageAnim.forward(from: 0);
      _syncPostButton();
    }
  }

  void _removeImage() {
    _imageAnim.reverse().then((_) {
      if (mounted) {
        setState(() => _pickedImage = null);
        _syncPostButton();
      }
    });
  }

  bool get _canPost =>
      (_messageController.text.trim().isNotEmpty || _pickedImage != null) &&
          _selectedCampusIds.isNotEmpty;

  Future<void> _submitPost() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    final campusStr = _selectedCampusIds.join(',');

    final res = await _apiService.createForumPost(
      message: _messageController.text.trim(),
      campus: campusStr,
      imageFile: _pickedImage,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnack(
        message: 'Your post is live!',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF1E9E6B),
      );
      widget.onPostCreated?.call();
      Navigator.pop(context);
    } else {
      _showSnack(
        message: res['message'] ?? 'Failed to share post.',
        icon: Icons.error_outline_rounded,
        color: AppTheme.redPink,
      );
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  void _showImagePicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ImagePickerSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  void _showCampusPicker() {
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
                        _syncPostButton();
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;
    final topPad = mq.padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F9),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(topPad),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 120,
                      ),
                      child: Column(
                        children: [
                          _buildGuidelineStrip(),
                          const SizedBox(height: 12),
                          _buildComposerCard(),
                          if (_pickedImage != null) _buildImagePreviewCard(),
                          const SizedBox(height: 12),
                          _buildAddToPostBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset > 0 ? bottomInset + 12 : 24,
              child: _buildBottomPostButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 10,
        left: 6,
        right: 18,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.redPink, AppTheme.redPink.withOpacity(0.88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.redPink.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Create Post',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Share something with your campus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildGuidelineStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.redPink.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.redPink.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.campaign_rounded,
              size: 15,
              color: AppTheme.redPink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keep posts respectful and relevant to your community.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray.withOpacity(0.65),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorRow(),
          _buildTextField(),
          _buildCharCounter(),
          _buildCampusSelector(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingUser
                    ? Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )
                    : Row(
                  children: [
                    Flexible(
                      child: Text(
                        _fullName.isNotEmpty ? _fullName : 'You',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkGray,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (_isVerifiedUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppTheme.redPink.withOpacity(0.85),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                _isLoadingUser
                    ? Container(
                  width: 90,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.redPink.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: AppTheme.redPink.withOpacity(0.75),
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          _campusName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.redPink.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.darkGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 12,
                  color: AppTheme.darkGray.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Public',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final img = _profileImage;
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.redPink.withOpacity(0.9),
                AppTheme.redPink.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: _isLoadingUser
                  ? Container(color: Colors.grey.shade200)
                  : img != null
                  ? Image(
                image: img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
              )
                  : _avatarFallback(),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFF1E9E6B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppTheme.redPink.withOpacity(0.1),
      child: Icon(
        Icons.person_rounded,
        size: 26,
        color: AppTheme.redPink.withOpacity(0.8),
      ),
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _messageController,
        focusNode: _focusNode,
        autofocus: true,
        maxLines: null,
        minLines: 4,
        maxLength: _maxChars,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        style: TextStyle(
          fontSize: _messageController.text.isEmpty ? 19 : 16,
          color: AppTheme.darkGray,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: "What's happening in your community?",
          hintStyle: TextStyle(
            fontSize: 18,
            color: AppTheme.darkGray.withOpacity(0.28),
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCharCounter() {
    final length = _messageController.text.length;
    final nearLimit = length > _maxChars - 60;
    if (length == 0) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$length/$_maxChars',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: nearLimit
                ? AppTheme.redPink
                : AppTheme.darkGray.withOpacity(0.32),
          ),
        ),
      ),
    );
  }

  Widget _buildCampusSelector() {
    final selectedNames = _campuses
        .where((c) => _selectedCampusIds.contains(c['campusId'] as int))
        .map((c) => c['campusName'] as String)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Target Campus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGray.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.redPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showCampusPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selectedNames.isNotEmpty
                    ? AppTheme.redPink.withOpacity(0.04)
                    : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedNames.isNotEmpty
                      ? AppTheme.redPink.withOpacity(0.35)
                      : AppTheme.darkGray.withOpacity(0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: selectedNames.isNotEmpty
                        ? AppTheme.redPink
                        : AppTheme.darkGray.withOpacity(0.45),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: selectedNames.isEmpty
                        ? Text(
                      'Select target campus',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkGray.withOpacity(0.38),
                      ),
                    )
                        : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedNames
                          .map((name) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.redPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.redPink,
                              fontWeight: FontWeight.w600),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.darkGray.withOpacity(0.45),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewCard() {
    return FadeTransition(
      opacity: _imageFade,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => showFullScreenImage(
                  context,
                  FileImage(_pickedImage!),
                ),
                child: Image.file(
                  _pickedImage!,
                  width: double.infinity,
                  height: 270,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 84,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 64,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _glassIconBtn(
                      icon: Icons.edit_rounded,
                      onTap: _showImagePicker,
                    ),
                    const SizedBox(width: 8),
                    _glassIconBtn(
                      icon: Icons.close_rounded,
                      onTap: _removeImage,
                      tint: AppTheme.redPink,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 6),
                      Text(
                        'Tap to preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? tint,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tint != null
              ? tint.withOpacity(0.88)
              : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  Widget _buildAddToPostBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 8),
            child: Text(
              'ADD TO YOUR POST',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.4),
                letterSpacing: 0.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(
              children: [
                _addToPostTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF1E9E6B),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _addToPostTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFF1565C0),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _addToPostTile(
                  icon: Icons.school_rounded,
                  label: 'Campus',
                  color: AppTheme.redPink,
                  onTap: _showCampusPicker,
                ),
                _addToPostTile(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  color: const Color(0xFFF57C00),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addToPostTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.16),
                      color.withOpacity(0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGray.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPostButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ScaleTransition(
        scale: _postBtnScale,
        child: AnimatedOpacity(
          opacity: _canPost ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _canPost && !_isSubmitting ? _submitPost : null,
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _canPost
                    ? const LinearGradient(
                  colors: [
                    AppTheme.redPink,
                    Color(0xFFE8636E),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : LinearGradient(
                  colors: [
                    AppTheme.darkGray.withOpacity(0.22),
                    AppTheme.darkGray.withOpacity(0.22),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _canPost
                    ? [
                  BoxShadow(
                    color: AppTheme.redPink.withOpacity(0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting)
                    const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _isSubmitting ? 'Sharing...' : 'Share Post',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImagePickerSheet({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.darkGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.redPink,
                      AppTheme.redPink.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  Text(
                    'Choose a source for your photo',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.darkGray.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _SheetOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  sublabel: 'Take a new photo',
                  color: AppTheme.redPink,
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SheetOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  sublabel: 'Pick from library',
                  color: const Color(0xFF1565C0),
                  onTap: onGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppTheme.darkGray.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.darkGray.withOpacity(0.08),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGray.withOpacity(0.55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.18),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sublabel,
              style: TextStyle(
                color: color.withOpacity(0.5),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}