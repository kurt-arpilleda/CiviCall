// forum/forumPost.dart
import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/anim/skeletonAnimation.dart';
import 'package:civicall/imageViewer.dart';
import 'package:intl/intl.dart';

class ForumPostScreen extends StatefulWidget {
  const ForumPostScreen({Key? key}) : super(key: key);

  @override
  ForumPostScreenState createState() => ForumPostScreenState();
}

class ForumPostScreenState extends State<ForumPostScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> refresh() async {
    await _loadPosts(silent: true);
  }

  Future<void> _loadPosts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final res = await _apiService.getForumPosts();

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _posts = List<Map<String, dynamic>>.from(res['posts'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load forum posts.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePullRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadPosts(silent: true);
    if (mounted) setState(() => _isRefreshing = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: _isLoading
          ? _buildSkeletonView()
          : _error != null
          ? _buildErrorState()
          : _posts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: AppTheme.redPink,
        onRefresh: _handlePullRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: _posts.length,
          itemBuilder: (_, i) {
            final post = _posts[i];
            final key = ValueKey(post['forumId']);
            return _ForumPostCard(
              key: key,
              post: post,
              profileImageProvider: _resolveProfileImage(post['photo_url'] as String?),
              forumImageProvider: _resolveForumImage(post['image'] as String?),
              timeAgo: _timeAgo(post['createdAt'] as String),
              formatCount: _formatCount,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: 4,
      itemBuilder: (_, __) => const _ForumPostCardSkeleton(),
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
              'Could not load forum posts',
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
              onPressed: _loadPosts,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
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
                Icons.forum_outlined,
                color: AppTheme.redPink.withOpacity(0.55),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Forum Posts Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts\nin the community forum.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGray.withOpacity(0.4),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final ImageProvider profileImageProvider;
  final ImageProvider forumImageProvider;
  final String timeAgo;
  final String Function(int) formatCount;

  const _ForumPostCard({
    Key? key,
    required this.post,
    required this.profileImageProvider,
    required this.forumImageProvider,
    required this.timeAgo,
    required this.formatCount,
  }) : super(key: key);

  @override
  State<_ForumPostCard> createState() => _ForumPostCardState();
}

class _ForumPostCardState extends State<_ForumPostCard> {
  final ApiService _apiService = ApiService();
  bool _isVoting = false;
  int? _userVoteType;
  int _upCount = 0;
  int _downCount = 0;

  @override
  void initState() {
    super.initState();
    _upCount = widget.post['upCount'] as int? ?? 0;
    _downCount = widget.post['downCount'] as int? ?? 0;
    _userVoteType = widget.post['userVoteType'] as int?;
  }

  Future<void> _handleVote(int voteType) async {
    if (_isVoting) return;

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

    final forumId = widget.post['forumId'] as int;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.redPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleCommentTap() {
    // Placeholder - comment feature not implemented yet.
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.post['firstName'] as String? ?? '';
    final lastName = widget.post['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final rawCampusName = (widget.post['campusName'] as String? ?? '').trim();
    final campusName = rawCampusName.isNotEmpty ? rawCampusName : 'Campus Community';
    final message = widget.post['message'] as String? ?? '';
    final hasImage = widget.post['image'] != null && widget.post['image'].toString().isNotEmpty;
    final commentCount = widget.post['commentCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
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
                      showFullScreenImage(context, widget.profileImageProvider);
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
                        image: widget.profileImageProvider,
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
                            widget.timeAgo,
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
                              campusName,
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
                  showFullScreenImage(context, widget.forumImageProvider);
                } catch (_) {}
              },
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image(
                  image: widget.forumImageProvider,
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
                  formatCount: widget.formatCount,
                  onTap: () => _handleVote(1),
                  isLoading: _isVoting,
                  color: const Color(0xFF2E7D5E),
                ),
                const SizedBox(width: 6),
                _VoteButton(
                  icon: Icons.arrow_circle_down_rounded,
                  isActive: _userVoteType == 0,
                  count: _downCount,
                  formatCount: widget.formatCount,
                  onTap: () => _handleVote(0),
                  isLoading: _isVoting,
                  color: AppTheme.redPink,
                ),
                const Spacer(),
                _CommentButton(
                  count: commentCount,
                  formatCount: widget.formatCount,
                  onTap: _handleCommentTap,
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

class _CommentButton extends StatelessWidget {
  final int count;
  final String Function(int) formatCount;
  final VoidCallback onTap;

  const _CommentButton({
    required this.count,
    required this.formatCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.darkGray.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mode_comment_outlined,
              size: 18,
              color: AppTheme.darkGray.withOpacity(0.4),
            ),
            const SizedBox(width: 5),
            Text(
              formatCount(count),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumPostCardSkeleton extends StatelessWidget {
  const _ForumPostCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const SkeletonCircle(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 140, height: 14, borderRadius: 6),
                      const SizedBox(height: 6),
                      const SkeletonBox(width: 90, height: 11, borderRadius: 5),
                      const SizedBox(height: 6),
                      const SkeletonBox(width: 70, height: 10, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 200, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 160, height: 14, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 280, borderRadius: 0),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
                Spacer(),
                SkeletonBox(width: 50, height: 30, borderRadius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}