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

  File? _pickedImage;
  bool _isSubmitting = false;
  bool _hasText = false;

  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  late AnimationController _postBtnAnim;
  late Animation<double> _postBtnScale;
  late AnimationController _imageAnim;
  late Animation<double> _imageFade;

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

    _messageController.addListener(_onTextChanged);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final res = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        if (res['success'] == true) {
          _userData = res['user'] as Map<String, dynamic>?;
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
      _messageController.text.trim().isNotEmpty || _pickedImage != null;

  Future<void> _submitPost() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    final res = await _apiService.createForumPost(
      message: _messageController.text.trim(),
      imageFile: _pickedImage,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnack(
        message: 'Your post is live!',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF2E7D5E),
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
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        elevation: 8,
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
        backgroundColor: const Color(0xFFF2F3F7),
        body: Column(
          children: [
            _buildHeader(topPad),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 12,
                    left: 0,
                    right: 0,
                    bottom: bottomInset > 0 ? bottomInset + 70 : 90,
                  ),
                  child: Column(
                    children: [
                      _buildComposerCard(),
                      if (_pickedImage != null) _buildImagePreviewCard(),
                      const SizedBox(height: 12),
                      _buildAddToPostBar(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomPostButton(bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 10,
        left: 8,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.redPink,
        boxShadow: [
          BoxShadow(
            color: AppTheme.redPink.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Create Post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }

  Widget _buildComposerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorRow(),
          _buildTextField(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  width: 110,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    : Text(
                  _fullName.isNotEmpty ? _fullName : 'You',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkGray,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGray.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 11,
                        color: AppTheme.darkGray.withOpacity(0.55),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Campus Community',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGray.withOpacity(0.55),
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

  Widget _buildAvatar() {
    final img = _profileImage;
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.redPink.withOpacity(0.25),
              width: 2,
            ),
            color: AppTheme.redPink.withOpacity(0.1),
          ),
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
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047),
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
      color: AppTheme.redPink.withOpacity(0.12),
      child: const Icon(
        Icons.person_rounded,
        size: 26,
        color: AppTheme.redPink,
      ),
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        controller: _messageController,
        focusNode: _focusNode,
        autofocus: true,
        maxLines: null,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: TextStyle(
          fontSize: _messageController.text.isEmpty ? 20 : 16,
          color: AppTheme.darkGray,
          height: 1.55,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          hintStyle: TextStyle(
            fontSize: 20,
            color: AppTheme.darkGray.withOpacity(0.25),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard() {
    return FadeTransition(
      opacity: _imageFade,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
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
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
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
                bottom: 10,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15), width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.zoom_in_rounded,
                              color: Colors.white, size: 12),
                          SizedBox(width: 5),
                          Text(
                            'Tap to preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
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
              ? tint.withOpacity(0.85)
              : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Add to your post',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray.withOpacity(0.45),
                letterSpacing: 0.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _addToPostTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF43A047),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _addToPostTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFF1565C0),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _addToPostTile(
                  icon: Icons.tag_rounded,
                  label: 'Tag',
                  color: const Color(0xFF8E24AA),
                  onTap: () {},
                ),
                _addToPostTile(
                  icon: Icons.emoji_emotions_rounded,
                  label: 'Feeling',
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
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
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

  Widget _buildBottomPostButton(double bottomInset) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, bottomInset > 0 ? bottomInset + 6 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.darkGray.withOpacity(0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ScaleTransition(
        scale: _postBtnScale,
        child: AnimatedOpacity(
          opacity: _canPost ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _canPost && !_isSubmitting ? _submitPost : null,
            child: Container(
              height: 52,
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
                    AppTheme.darkGray.withOpacity(0.25),
                    AppTheme.darkGray.withOpacity(0.25),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canPost
                    ? [
                  BoxShadow(
                    color: AppTheme.redPink.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.redPink,
                      AppTheme.redPink.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 22,
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
          const SizedBox(height: 24),
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