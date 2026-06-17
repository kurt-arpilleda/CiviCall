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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> refresh() async {
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
        onRefresh: _loadPosts,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: _posts.length,
          itemBuilder: (_, i) => _ForumPostCard(
            post: _posts[i],
            profileImageProvider: _resolveProfileImage(_posts[i]['photo_url'] as String?),
            forumImageProvider: _resolveForumImage(_posts[i]['image'] as String?),
            timeAgo: _timeAgo(_posts[i]['createdAt'] as String),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: 4,
      itemBuilder: (_, __) => _ForumPostCardSkeleton(),
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

class _ForumPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final ImageProvider profileImageProvider;
  final ImageProvider forumImageProvider;
  final String timeAgo;

  const _ForumPostCard({
    required this.post,
    required this.profileImageProvider,
    required this.forumImageProvider,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = post['firstName'] as String? ?? '';
    final lastName = post['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final message = post['message'] as String? ?? '';
    final hasImage = post['image'] != null && post['image'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    try {
                      showFullScreenImage(context, profileImageProvider);
                    } catch (_) {}
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.redPink.withOpacity(0.15),
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
                            size: 22,
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
                      Text(
                        fullName.isEmpty ? 'Unknown User' : fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkGray,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            timeAgo,
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
                          Text(
                            'Public',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.darkGray.withOpacity(0.3),
                              fontWeight: FontWeight.w500,
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
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
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ForumPostCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                SkeletonCircle(size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 14, borderRadius: 6),
                      const SizedBox(height: 6),
                      SkeletonBox(width: 80, height: 11, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonBox(width: 200, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonBox(width: 160, height: 14, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 280, borderRadius: 0),
        ],
      ),
    );
  }
}