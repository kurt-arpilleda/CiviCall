import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/anim/skeletonAnimation.dart';
import 'package:civicall/imageViewer.dart';
import 'package:intl/intl.dart';
import 'package:civicall/anim/scroll_aware_header.dart';

class ForumCommentPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final ValueChanged<int>? onCommentCountChanged;
  final void Function(int upCount, int downCount, int? userVoteType)? onVoteChanged;

  const ForumCommentPostScreen({
    Key? key,
    required this.post,
    this.onCommentCountChanged,
    this.onVoteChanged,
  }) : super(key: key);

  @override
  State<ForumCommentPostScreen> createState() => _ForumCommentPostScreenState();
}

class _ForumCommentPostScreenState extends State<ForumCommentPostScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  bool _isVoting = false;
  int? _userVoteType;
  int _upCount = 0;
  int _downCount = 0;
  bool _hasText = false;

  final HeaderVisibilityController _headerVisibility = HeaderVisibilityController();
  static const double _appBarHeight = kToolbarHeight;

  @override
  void initState() {
    super.initState();
    _headerVisibility.attachTicker(this);
    _post = widget.post;
    _userVoteType = widget.post['userVoteType'] as int?;
    _upCount = widget.post['upCount'] as int? ?? 0;
    _downCount = widget.post['downCount'] as int? ?? 0;
    _commentController.addListener(_onTextChanged);
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _focusNode.dispose();
    _headerVisibility.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _loadComments({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final forumId = widget.post['forumId'] as int;
    final res = await _apiService.getForumComments(forumId: forumId);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _post = Map<String, dynamic>.from(res['post'] ?? widget.post);
        _comments = List<Map<String, dynamic>>.from(res['comments'] ?? []);
        _isLoading = false;
        if (!_isVoting) {
          _userVoteType = _post?['userVoteType'] as int?;
          _upCount = _post?['upCount'] as int? ?? _upCount;
          _downCount = _post?['downCount'] as int? ?? _downCount;
        }
      });
      final newCount = _post?['commentCount'] as int? ?? _comments.length;
      widget.onCommentCountChanged?.call(newCount);
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load comments.';
        _isLoading = false;
      });
    }
  }

  String _timeAgo(String? dateTimeStr) {
    if (dateTimeStr == null) return 'just now';
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  ImageProvider _resolveProfileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return NetworkImage(photoUrl);
    }
    return NetworkImage('${ApiService.apiUrl}profileImage/$photoUrl');
  }

  ImageProvider _resolveForumImage(String? imageFileName) {
    if (imageFileName == null || imageFileName.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    if (imageFileName.startsWith('http://') || imageFileName.startsWith('https://')) {
      return NetworkImage(imageFileName);
    }
    return NetworkImage('${ApiService.apiUrl}forumImages/$imageFileName');
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || _isSubmitting || _post == null) return;

    setState(() => _isSubmitting = true);
    _focusNode.unfocus();

    final forumId = _post!['forumId'] as int;
    final res = await _apiService.addForumComment(
      forumId: forumId,
      commentText: commentText,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      _commentController.clear();
      _showSnackBar('Comment posted!', isSuccess: true);
      await _loadComments(silent: true);
    } else {
      _showSnackBar(res['message'] ?? 'Failed to post comment.');
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _handleVote(int voteType) async {
    if (_isVoting || _post == null) return;

    final userRes = await _apiService.getUserData();
    if (!mounted) return;

    if (userRes['success'] != true) {
      _showSnackBar('Please login to vote.');
      return;
    }

    final isVerified = (userRes['user']?['isVerified'] ?? 0) == 1;
    if (!isVerified) {
      _showSnackBar('Only verified users can vote.');
      return;
    }

    final prevUserVote = _userVoteType;
    final prevUp = _upCount;
    final prevDown = _downCount;

    setState(() {
      _isVoting = true;
      if (prevUserVote == voteType) {
        _userVoteType = null;
        if (voteType == 1) {
          _upCount -= 1;
        } else {
          _downCount -= 1;
        }
      } else {
        if (prevUserVote == 1) _upCount -= 1;
        if (prevUserVote == 0) _downCount -= 1;
        _userVoteType = voteType;
        if (voteType == 1) {
          _upCount += 1;
        } else {
          _downCount += 1;
        }
      }
    });

    final forumId = _post!['forumId'] as int;
    final result = await _apiService.voteForumPost(
      forumId: forumId,
      voteType: voteType,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _upCount = result['upCount'] as int? ?? _upCount;
        _downCount = result['downCount'] as int? ?? _downCount;
        _userVoteType = result['userVote'] as int?;
        _isVoting = false;
      });
      widget.onVoteChanged?.call(_upCount, _downCount, _userVoteType);
    } else {
      setState(() {
        _upCount = prevUp;
        _downCount = prevDown;
        _userVoteType = prevUserVote;
        _isVoting = false;
      });
      _showSnackBar(result['message'] ?? 'Failed to vote.');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF1E9E6B) : AppTheme.redPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post ?? widget.post;
    final commentCount = post['commentCount'] as int? ?? _comments.length;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: HeaderVisibilityScope(
        controller: _headerVisibility,
        child: ValueListenableBuilder<double>(
          valueListenable: _headerVisibility,
          builder: (context, collapseFraction, _) {
            final headerHeight = topPadding + _appBarHeight;
            _headerVisibility.headerHeight = headerHeight;
            final hiddenOffset = headerHeight * collapseFraction;

            return Stack(
              children: [
                Positioned(
                  top: headerHeight - hiddenOffset,
                  left: 0,
                  right: 0,
                  bottom: 80 + bottomPadding,
                  child: _isLoading
                      ? _buildSkeletonView()
                      : _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                    color: AppTheme.redPink,
                    onRefresh: () => _loadComments(silent: true),
                    child: HeaderScrollListener(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        children: [
                          _buildPostCard(post),
                          const SizedBox(height: 14),
                          _buildCommentsHeader(commentCount),
                          const SizedBox(height: 8),
                          if (_comments.isEmpty)
                            _buildNoCommentsState()
                          else
                            ..._comments.map((c) => _CommentTile(
                              comment: c,
                              timeAgo: _timeAgo(c['createdAt'] as String?),
                              profileImageProvider: _resolveProfileImage(c['photo_url'] as String?),
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -hiddenOffset,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (1.0 - collapseFraction * 1.15).clamp(0.0, 1.0),
                    child: _buildAppBar(topPadding),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildCommentInput(bottomPadding),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      height: topPadding + _appBarHeight,
      decoration: const BoxDecoration(
        color: AppTheme.redPink,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCommentInput(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.darkGray.withOpacity(0.08), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray.withOpacity(0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
              maxLines: null,
              maxLength: 500,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submitComment,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hasText && !_isSubmitting
                    ? AppTheme.redPink
                    : AppTheme.darkGray.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                Icons.send_rounded,
                color: _hasText ? Colors.white : AppTheme.darkGray.withOpacity(0.35),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      children: const [
        _PostCardSkeleton(),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonBox(width: 120, height: 14, borderRadius: 6),
        ),
        SizedBox(height: 12),
        _CommentTileSkeleton(),
        _CommentTileSkeleton(),
        _CommentTileSkeleton(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.redPink.withOpacity(0.6),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load this post',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGray.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadComments,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCommentsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.redPink.withOpacity(0.12),
                  AppTheme.redPink.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mode_comment_outlined,
              color: AppTheme.redPink.withOpacity(0.55),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkGray.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to share your thoughts.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.darkGray.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsHeader(int commentCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.mode_comment_outlined,
            size: 16,
            color: AppTheme.darkGray.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            commentCount == 1 ? '1 Comment' : '${_formatCount(commentCount)} Comments',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkGray.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final firstName = post['firstName'] as String? ?? '';
    final lastName = post['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final campusName = (post['campusName'] as String? ?? '').trim();
    final message = post['message'] as String? ?? '';
    final hasImage = post['image'] != null && post['image'].toString().isNotEmpty;
    final profileImageProvider = _resolveProfileImage(post['photo_url'] as String?);
    final forumImageProvider = _resolveForumImage(post['image'] as String?);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.darkGray.withOpacity(0.08), width: 1),
          bottom: BorderSide(color: AppTheme.darkGray.withOpacity(0.08), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    try {
                      showFullScreenImage(context, profileImageProvider);
                    } catch (_) {}
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.redPink.withOpacity(0.18),
                        width: 1.5,
                      ),
                      color: AppTheme.redPink.withOpacity(0.08),
                    ),
                    child: ClipOval(
                      child: Image(
                        image: profileImageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.redPink.withOpacity(0.08),
                          child: Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: AppTheme.redPink.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'Unknown User' : fullName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkGray,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _timeAgo(post['createdAt'] as String?),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.darkGray.withOpacity(0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.darkGray.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.school_outlined,
                            size: 12,
                            color: AppTheme.redPink.withOpacity(0.55),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              campusName.isNotEmpty ? campusName : 'Campus Community',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.redPink.withOpacity(0.75),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
            ),
          if (hasImage) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                try {
                  showFullScreenImage(context, forumImageProvider);
                } catch (_) {}
              },
              child: Image(
                image: forumImageProvider,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 280,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 40,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.darkGray.withOpacity(0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                _VoteButton(
                  icon: Icons.arrow_circle_up_rounded,
                  isActive: _userVoteType == 1,
                  count: _upCount,
                  formatCount: _formatCount,
                  onTap: () => _handleVote(1),
                  isLoading: _isVoting,
                  color: const Color(0xFF2E7D5E),
                ),
                const SizedBox(width: 6),
                _VoteButton(
                  icon: Icons.arrow_circle_down_rounded,
                  isActive: _userVoteType == 0,
                  count: _downCount,
                  formatCount: _formatCount,
                  onTap: () => _handleVote(0),
                  isLoading: _isVoting,
                  color: AppTheme.redPink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final int count;
  final String Function(int) formatCount;
  final VoidCallback onTap;
  final bool isLoading;
  final Color color;

  const _VoteButton({
    required this.icon,
    required this.isActive,
    required this.count,
    required this.formatCount,
    required this.onTap,
    required this.isLoading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : AppTheme.darkGray.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? color : AppTheme.darkGray.withOpacity(0.4),
            ),
            const SizedBox(width: 5),
            Text(
              formatCount(count),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? color : AppTheme.darkGray.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String timeAgo;
  final ImageProvider profileImageProvider;

  const _CommentTile({
    required this.comment,
    required this.timeAgo,
    required this.profileImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = comment['firstName'] as String? ?? '';
    final lastName = comment['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final campusName = (comment['campusName'] as String? ?? '').trim();
    final commentText = comment['commentText'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkGray.withOpacity(0.06), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              try {
                showFullScreenImage(context, profileImageProvider);
              } catch (_) {}
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.redPink.withOpacity(0.18),
                  width: 1.3,
                ),
                color: AppTheme.redPink.withOpacity(0.08),
              ),
              child: ClipOval(
                child: Image(
                  image: profileImageProvider,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.redPink.withOpacity(0.08),
                    child: Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: AppTheme.redPink.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName.isEmpty ? 'Unknown User' : fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.darkGray.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (campusName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 11,
                        color: AppTheme.redPink.withOpacity(0.55),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        campusName,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.redPink.withOpacity(0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  commentText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.darkGray,
                    height: 1.4,
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

class _PostCardSkeleton extends StatelessWidget {
  const _PostCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.darkGray.withOpacity(0.08), width: 1),
          bottom: BorderSide(color: AppTheme.darkGray.withOpacity(0.08), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 140, height: 14, borderRadius: 6),
                      SizedBox(height: 6),
                      SkeletonBox(width: 90, height: 11, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
            const SizedBox(height: 6),
            const SkeletonBox(width: 200, height: 14, borderRadius: 6),
            const SizedBox(height: 10),
            const SkeletonBox(width: double.infinity, height: 280, borderRadius: 0),
          ],
        ),
      ),
    );
  }
}

class _CommentTileSkeleton extends StatelessWidget {
  const _CommentTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkGray.withOpacity(0.06), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonCircle(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 100, height: 12, borderRadius: 5),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 12, borderRadius: 5),
                SizedBox(height: 5),
                SkeletonBox(width: 150, height: 12, borderRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}