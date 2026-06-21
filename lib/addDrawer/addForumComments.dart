import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';

class AddForumCommentScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onCommentPosted;

  const AddForumCommentScreen({
    Key? key,
    required this.post,
    this.onCommentPosted,
  }) : super(key: key);

  @override
  State<AddForumCommentScreen> createState() => _AddForumCommentScreenState();
}

class _AddForumCommentScreenState extends State<AddForumCommentScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const int _maxChars = 500;

  bool _isSubmitting = false;

  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  late AnimationController _postBtnAnim;
  late Animation<double> _postBtnScale;
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

    _entranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entranceFade = CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOutCubic));

    _commentController.addListener(_onTextChanged);
    _loadUser();
    _entranceAnim.forward();
  }

  Future<void> _loadUser() async {
    final userRes = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        if (userRes['success'] == true) {
          _userData = userRes['user'] as Map<String, dynamic>?;
        }
        _isLoadingUser = false;
      });
    }
  }

  void _onTextChanged() {
    setState(() {});
    _syncPostButton();
  }

  void _syncPostButton() {
    if (_commentController.text.trim().isNotEmpty) {
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

  String get _posterFullName {
    final first = (widget.post['firstName'] ?? '').toString().trim();
    final last = (widget.post['lastName'] ?? '').toString().trim();
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Unknown User' : name;
  }

  String get _posterMessage => (widget.post['message'] ?? '').toString();

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _focusNode.dispose();
    _postBtnAnim.dispose();
    _entranceAnim.dispose();
    super.dispose();
  }

  bool get _canPost => _commentController.text.trim().isNotEmpty;

  Future<void> _submitComment() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    final forumId = widget.post['forumId'] as int;

    final res = await _apiService.addForumComment(
      forumId: forumId,
      commentText: _commentController.text.trim(),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnack(
        message: 'Comment posted!',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF1E9E6B),
      );
      widget.onCommentPosted?.call();
      Navigator.pop(context, res);
    } else {
      _showSnack(
        message: res['message'] ?? 'Failed to post comment.',
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
                      padding: const EdgeInsets.only(top: 16, bottom: 120),
                      child: Column(
                        children: [
                          _buildOriginalPostCard(),
                          const SizedBox(height: 12),
                          _buildComposerCard(),
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
        bottom: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.redPink,
            AppTheme.redPink.withOpacity(0.85),
          ],
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
                  'Add Comment',
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
                  'Share your thoughts on this post',
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

  Widget _buildOriginalPostCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkGray.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.redPink.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to $_posterFullName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray.withOpacity(0.55),
                  ),
                ),
                if (_posterMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _posterMessage,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkGray.withOpacity(0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
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
        controller: _commentController,
        focusNode: _focusNode,
        autofocus: true,
        maxLines: null,
        minLines: 4,
        maxLength: _maxChars,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        style: TextStyle(
          fontSize: _commentController.text.isEmpty ? 19 : 16,
          color: AppTheme.darkGray,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Write a comment...',
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
    final length = _commentController.text.length;
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

  Widget _buildBottomPostButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ScaleTransition(
        scale: _postBtnScale,
        child: AnimatedOpacity(
          opacity: _canPost ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _canPost && !_isSubmitting ? _submitComment : null,
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
                    _isSubmitting ? 'Posting...' : 'Post Comment',
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