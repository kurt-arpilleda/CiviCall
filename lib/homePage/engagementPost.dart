import 'dart:async';
import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/anim/skeletonAnimation.dart';
import 'package:civicall/homePage/engagementDetails.dart';
import 'package:intl/intl.dart';

class EngagementFeedScreen extends StatefulWidget {
  const EngagementFeedScreen({Key? key}) : super(key: key);

  @override
  State<EngagementFeedScreen> createState() => EngagementFeedScreenState();
}

class EngagementFeedScreenState extends State<EngagementFeedScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> engagements = [];
  bool _isLoading = true;
  String? _error;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadEngagements();
  }

  Future<void> refresh() async {
    await _loadEngagements();
  }

  Future<void> _loadEngagements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await _apiService.fetchEngagements();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        engagements = List<Map<String, dynamic>>.from(res['engagements'] ?? []);
        currentUserId = res['currentUserId'] as int?;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load engagements.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeletonList();
    if (_error != null) return _buildErrorState();
    if (engagements.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppTheme.redPink,
      onRefresh: _loadEngagements,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: engagements.length,
        itemBuilder: (_, i) => _EngagementCard(
          engagement: engagements[i],
          currentUserId: currentUserId,
          onRefresh: _loadEngagements,
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 4,
      itemBuilder: (_, __) => _EngagementCardSkeleton(),
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
              child: Icon(Icons.wifi_off_rounded, color: AppTheme.redPink.withOpacity(0.6), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load engagements',
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
              style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.45)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEngagements,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  colors: [AppTheme.redPink.withOpacity(0.12), AppTheme.redPink.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.volunteer_activism_outlined,
                  color: AppTheme.redPink.withOpacity(0.55), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'No Engagements Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to add a community\nengagement activity.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.4), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final Map<String, dynamic> engagement;
  final int? currentUserId;
  final VoidCallback onRefresh;

  const _EngagementCard({
    required this.engagement,
    required this.currentUserId,
    required this.onRefresh,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMMM d, yyyy hh:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int verificationStatus = engagement['verificationStatus'] as int? ?? 0;
    final bool isVerified = verificationStatus == 1;
    final bool isOwner = (engagement['uploaderId'] as int?) == currentUserId;
    final String? imageFile = engagement['engagementImage'] as String?;
    final String imageUrl = (imageFile != null && imageFile.isNotEmpty)
        ? '${ApiService.apiUrl}civicall_add_engagement.php/../engagementImage/$imageFile'
        : '';
    final bool hasImage = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EngagementDetailsScreen(
              engagement: engagement,
              currentUserId: currentUserId,
              onUpdated: onRefresh,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            _buildImageSection(context, hasImage, imageUrl, isVerified, isOwner),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryChip(),
                  const SizedBox(height: 8),
                  Text(
                    engagement['titleEngagement'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkGray,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    engagement['locationAddress'] ?? '—',
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    _formatDate(engagement['startSchedule'] as String?),
                    const Color(0xFF2E7D5E),
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.event_outlined,
                    _formatDate(engagement['endSchedule'] as String?),
                    const Color(0xFF6A1B9A),
                  ),
                  if (!isVerified && isOwner) ...[
                    const SizedBox(height: 12),
                    _buildUnverifiedBanner(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, bool hasImage, String imageUrl, bool isVerified, bool isOwner) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Stack(
        children: [
          hasImage
              ? Image.network(
            imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _noImagePlaceholder(),
          )
              : _noImagePlaceholder(),
          Positioned(
            top: 12,
            right: 12,
            child: _buildVerificationBadge(isVerified),
          ),
          if (isOwner && !isVerified)
            Positioned(
              top: 12,
              left: 12,
              child: _buildOwnerBadge(),
            ),
        ],
      ),
    );
  }

  Widget _noImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.redPink.withOpacity(0.15),
            AppTheme.redPink.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.volunteer_activism_outlined,
          color: AppTheme.redPink.withOpacity(0.35),
          size: 52,
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFF2E7D5E) : const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.pending_rounded,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            'Your Post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip() {
    final String cat = engagement['categoryName'] as String? ?? 'General';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.redPink.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.redPink.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, color: AppTheme.redPink, size: 12),
          const SizedBox(width: 4),
          Text(
            cat,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.redPink,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGray.withOpacity(0.75),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnverifiedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 15),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Only visible to you until verified by admin.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: SkeletonBox(width: double.infinity, height: 180, borderRadius: 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 90, height: 22, borderRadius: 8),
                const SizedBox(height: 10),
                SkeletonBox(width: double.infinity, height: 16, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonBox(width: 200, height: 14, borderRadius: 6),
                const SizedBox(height: 14),
                SkeletonBox(width: double.infinity, height: 13, borderRadius: 5),
                const SizedBox(height: 8),
                SkeletonBox(width: 240, height: 13, borderRadius: 5),
                const SizedBox(height: 8),
                SkeletonBox(width: 200, height: 13, borderRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class EngagementSearchDelegate extends SearchDelegate<void> {
  final List<Map<String, dynamic>> engagements;
  final int? currentUserId;
  final VoidCallback onRefresh;

  EngagementSearchDelegate({
    required this.engagements,
    required this.currentUserId,
    required this.onRefresh,
  });

  @override
  String get searchFieldLabel => 'Search engagements...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.redPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 16),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (query.trim().isEmpty) return engagements;
    final q = query.trim().toLowerCase();
    return engagements.where((e) {
      final title = (e['titleEngagement'] as String? ?? '').toLowerCase();
      final category = (e['categoryName'] as String? ?? '').toLowerCase();
      final location = (e['locationAddress'] as String? ?? '').toLowerCase();
      return title.contains(q) || category.contains(q) || location.contains(q);
    }).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: AppTheme.darkGray.withOpacity(0.25)),
            const SizedBox(height: 14),
            Text(
              'No engagements found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkGray.withOpacity(0.45)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different title, category, or location.',
              style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.35)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: results.length,
      itemBuilder: (_, i) => _EngagementCard(
        engagement: results[i],
        currentUserId: currentUserId,
        onRefresh: onRefresh,
      ),
    );
  }
}