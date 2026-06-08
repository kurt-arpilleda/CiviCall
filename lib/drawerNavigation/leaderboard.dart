import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/anim/skeletonAnimation.dart';
import 'package:civicall/imageViewer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _campuses = [];
  Set<int> _selectedCampusIds = {};
  bool _isLoading = true;
  String? _error;
  int _currentUserCampus = 0;
  late AnimationController _podiumController;
  late Animation<double> _podiumAnimation;

  @override
  void initState() {
    super.initState();
    _podiumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _podiumAnimation = CurvedAnimation(
      parent: _podiumController,
      curve: Curves.easeOutBack,
    );
    _loadCampusesAndLeaderboard();
  }

  @override
  void dispose() {
    _podiumController.dispose();
    super.dispose();
  }

  Future<void> _loadCampusesAndLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final campusRes = await _apiService.fetchCampus();
      if (campusRes['success'] == true) {
        _campuses = List<Map<String, dynamic>>.from(campusRes['campuses'] ?? []);
      }
      await _fetchLeaderboard();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLeaderboard() async {
    final res = await _apiService.getLeaderboard(
      campusIds: _selectedCampusIds.isEmpty ? null : _selectedCampusIds.toList(),
    );
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _leaderboard = List<Map<String, dynamic>>.from(res['leaderboard'] ?? []);
        _currentUserCampus = res['currentUserCampus'] as int? ?? 0;
        if (_selectedCampusIds.isEmpty && _currentUserCampus != 0) {
          _selectedCampusIds.add(_currentUserCampus);
        }
        _isLoading = false;
      });
      _podiumController.forward(from: 0);
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load leaderboard.';
        _isLoading = false;
      });
    }
  }

  void _showCampusFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Set<int> tempSelected = Set.from(_selectedCampusIds);
        return StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.redPink, Color(0xFFFF6B8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter by Campus',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            Text(
                              'Select one or more campuses',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.shade100, height: 1),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _campuses.length,
                    itemBuilder: (_, i) {
                      final campus = _campuses[i];
                      final id = campus['campusId'] as int;
                      final name = campus['campusName'] as String;
                      final isSelected = tempSelected.contains(id);
                      return InkWell(
                        onTap: () {
                          setS(() {
                            if (isSelected) {
                              tempSelected.remove(id);
                            } else {
                              tempSelected.add(id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.redPink
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.redPink
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.darkGray
                                          : AppTheme.darkGray.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setS(() => tempSelected.clear());
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppTheme.darkGray.withOpacity(0.25)),
                            foregroundColor: AppTheme.darkGray,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Clear All',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedCampusIds = tempSelected);
                            Navigator.pop(ctx);
                            _fetchLeaderboard();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.redPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Apply Filter',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return NetworkImage(photoUrl);
    }
    return NetworkImage('${ApiService.apiUrl}profileImage/$photoUrl');
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = _selectedCampusIds.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            pinned: true,
            backgroundColor: AppTheme.redPink,
            foregroundColor: AppTheme.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.white,
                letterSpacing: 0.2,
              ),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: _showCampusFilterDialog,
                    tooltip: 'Filter campuses',
                  ),
                  if (hasFilter)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _isLoading ? null : _fetchLeaderboard,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
        body: _isLoading
            ? _buildSkeletonView()
            : _error != null
            ? _buildErrorState()
            : _leaderboard.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
          color: AppTheme.redPink,
          onRefresh: _fetchLeaderboard,
          child: CustomScrollView(
            slivers: [
              // Podium section
              if (_leaderboard.length >= 3)
                SliverToBoxAdapter(
                  child: _buildPodiumSection(),
                ),
              // Rank list header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.redPink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _leaderboard.length >= 3
                            ? 'More Rankings'
                            : 'Rankings',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkGray,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.redPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_leaderboard.length} participants',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.redPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // List items (skip top 3 if podium is shown)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                      final startIndex =
                      _leaderboard.length >= 3 ? 3 : 0;
                      final actualIndex = startIndex + i;
                      if (actualIndex >= _leaderboard.length)
                        return null;
                      return _LeaderboardListItem(
                        user: _leaderboard[actualIndex],
                        rank: actualIndex + 1,
                        imageProvider: _getImageProvider(
                            _leaderboard[actualIndex]['photo_url']),
                      );
                    },
                    childCount: _leaderboard.length >= 3
                        ? _leaderboard.length - 3
                        : _leaderboard.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // PODIUM SECTION
  // ──────────────────────────────────────────
  Widget _buildPodiumSection() {
    final top3 = _leaderboard.take(3).toList();
    // Order: 2nd | 1st | 3rd  (classic podium layout)
    final podiumOrder = [top3[1], top3[0], top3[2]];
    final podiumRanks = [2, 1, 3];
    final podiumHeights = [100.0, 130.0, 80.0];
    final podiumColors = [
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFFFD700), // Gold
      const Color(0xFFCD7F32), // Bronze
    ];
    final crownColors = [
      const Color(0xFFB8B8B8),
      const Color(0xFFFFCC00),
      const Color(0xFFBF8040),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.redPink,
            AppTheme.redPink.withOpacity(0.85),
            const Color(0xFFF3F4F8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Title badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Top Performers',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Podium avatars + names
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final user = podiumOrder[i];
              final rank = podiumRanks[i];
              final isFirst = rank == 1;
              final avatarSize = isFirst ? 80.0 : 64.0;
              final image =
              _getImageProvider(user['photo_url'] as String?);
              final firstName = (user['firstName'] ?? '').toString();
              final lastName = (user['lastName'] ?? '').toString();
              final shortName =
              firstName.isNotEmpty ? firstName : lastName;
              final points = user['totalPoints'] ?? 0;

              return ScaleTransition(
                scale: _podiumAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isFirst ? 8 : 4),
                  child: Column(
                    children: [
                      // Crown for 1st
                      if (isFirst)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.workspace_premium_rounded,
                              color: Colors.amber, size: 28),
                        )
                      else
                        const SizedBox(height: 32),
                      // Avatar
                      GestureDetector(
                        onTap: () =>
                            showFullScreenImage(context, image),
                        child: Container(
                          width: avatarSize + 4,
                          height: avatarSize + 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: podiumColors[i],
                              width: isFirst ? 3.5 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: podiumColors[i].withOpacity(0.5),
                                blurRadius: isFirst ? 16 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image(
                              image: image,
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: avatarSize * 0.55,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Name
                      SizedBox(
                        width: 80,
                        child: Text(
                          shortName.isEmpty ? 'User' : shortName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isFirst ? 14 : 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Points badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: crownColors[i], size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '$points pts',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            }),
          ),
          // Podium stage blocks
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final rank = podiumRanks[i];
              final isFirst = rank == 1;
              return Padding(
                padding:
                EdgeInsets.symmetric(horizontal: isFirst ? 4 : 2),
                child: AnimatedBuilder(
                  animation: _podiumAnimation,
                  builder: (_, __) => Container(
                    width: isFirst ? 110 : 88,
                    height: podiumHeights[i] * _podiumAnimation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          podiumColors[i],
                          podiumColors[i].withOpacity(0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: podiumColors[i].withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: isFirst ? 22 : 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.9),
                          shadows: const [
                            Shadow(
                                color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // SKELETON
  // ──────────────────────────────────────────
  Widget _buildSkeletonView() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildPodiumSkeleton()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                SkeletonBox(width: 120, height: 14, borderRadius: 6),
                const Spacer(),
                SkeletonBox(width: 90, height: 24, borderRadius: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, __) => const _LeaderboardSkeletonItem(),
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumSkeleton() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
            const Color(0xFFF3F4F8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        children: [
          Center(child: SkeletonBox(width: 130, height: 28, borderRadius: 20)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [2, 1, 3].map((rank) {
              final isFirst = rank == 1;
              return Padding(
                padding:
                EdgeInsets.symmetric(horizontal: isFirst ? 8 : 4),
                child: Column(
                  children: [
                    SizedBox(height: isFirst ? 0 : 32),
                    SkeletonCircle(size: isFirst ? 84 : 68),
                    const SizedBox(height: 8),
                    SkeletonBox(
                        width: 64, height: isFirst ? 14 : 12, borderRadius: 6),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 50, height: 20, borderRadius: 20),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            }).toList(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(width: 88, height: 80, borderRadius: 0),
              const SizedBox(width: 4),
              SkeletonBox(width: 110, height: 110, borderRadius: 0),
              const SizedBox(width: 4),
              SkeletonBox(width: 88, height: 65, borderRadius: 0),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // ERROR / EMPTY
  // ──────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.redPink.withOpacity(0.12),
                    AppTheme.redPink.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: AppTheme.redPink.withOpacity(0.6), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load leaderboard',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.darkGray.withOpacity(0.45)),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _fetchLeaderboard,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.redPink.withOpacity(0.12),
                    AppTheme.redPink.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_outlined,
                  color: AppTheme.redPink.withOpacity(0.5), size: 44),
            ),
            const SizedBox(height: 22),
            Text(
              'No Participants Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No one has earned points yet.\nStart joining engagements to rank up!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray.withOpacity(0.4),
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// RANK LIST ITEM  (rank #4 onwards)
// ──────────────────────────────────────────────────────────────────
class _LeaderboardListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final ImageProvider imageProvider;

  const _LeaderboardListItem({
    required this.user,
    required this.rank,
    required this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final campusName = user['campusName'] ?? '—';
    final points = user['totalPoints'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 34,
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkGray.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Avatar
            GestureDetector(
              onTap: () => showFullScreenImage(context, imageProvider),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.redPink.withOpacity(0.15), width: 2),
                  color: AppTheme.redPink.withOpacity(0.06),
                ),
                child: ClipOval(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person_rounded,
                      size: 26,
                      color: AppTheme.redPink.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + campus
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? 'Unknown User' : fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkGray,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.school_outlined,
                          size: 11,
                          color: AppTheme.darkGray.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          campusName,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.darkGray.withOpacity(0.5)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Points chip
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.redPink.withOpacity(0.13),
                    AppTheme.redPink.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: AppTheme.redPink.withOpacity(0.18), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppTheme.redPink, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '$points',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.redPink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// SKELETON ITEM
// ──────────────────────────────────────────────────────────────────
class _LeaderboardSkeletonItem extends StatelessWidget {
  const _LeaderboardSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SkeletonBox(width: 34, height: 16, borderRadius: 6),
            const SizedBox(width: 8),
            SkeletonCircle(size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                      width: double.infinity, height: 14, borderRadius: 6),
                  const SizedBox(height: 7),
                  SkeletonBox(width: 110, height: 11, borderRadius: 5),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SkeletonBox(width: 64, height: 30, borderRadius: 30),
          ],
        ),
      ),
    );
  }
}