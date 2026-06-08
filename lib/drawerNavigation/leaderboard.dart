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

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _campuses = [];
  Set<int> _selectedCampusIds = {};
  bool _isLoading = true;
  String? _error;
  int _currentUserCampus = 0;

  @override
  void initState() {
    super.initState();
    _loadCampusesAndLeaderboard();
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
    } else {
      setState(() {
        _error = res['message'] ?? 'Failed to load leaderboard.';
        _isLoading = false;
      });
    }
  }

  void _showCampusFilterDialog() {
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
                          child: const Icon(Icons.filter_alt_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Filter by Campus',
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
                        final isSelected = tempSelected.contains(id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setS(() {
                              if (val == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkGray,
                            ),
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
                        _fetchLeaderboard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.redPink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _buildRankBadge(int index) {
    if (index == 0) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Text(
            '1',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        ),
      );
    } else if (index == 1) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFFA9A9A9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Text(
            '2',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        ),
      );
    } else if (index == 2) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFFB87333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.darkGray.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.darkGray,
            ),
          ),
        ),
      );
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppTheme.redPink,
        foregroundColor: AppTheme.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showCampusFilterDialog,
            tooltip: 'Filter campuses',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : _error != null
          ? _buildErrorState()
          : _leaderboard.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: AppTheme.redPink,
        onRefresh: _fetchLeaderboard,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _leaderboard.length,
          itemBuilder: (_, i) => _LeaderboardItem(
            user: _leaderboard[i],
            rank: i + 1,
            rankBadge: _buildRankBadge(i),
            imageProvider: _getImageProvider(_leaderboard[i]['photo_url']),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 6,
      itemBuilder: (_, __) => const _LeaderboardSkeletonItem(),
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
              child: Icon(Icons.error_outline_rounded, color: AppTheme.redPink.withOpacity(0.6), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load leaderboard',
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
              onPressed: _fetchLeaderboard,
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
              child: Icon(Icons.leaderboard_outlined, color: AppTheme.redPink.withOpacity(0.55), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'No participants yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No one has earned points yet.\nStart joining engagements!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.4), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final Widget rankBadge;
  final ImageProvider imageProvider;

  const _LeaderboardItem({
    required this.user,
    required this.rank,
    required this.rankBadge,
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
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            rankBadge,
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => showFullScreenImage(context, imageProvider),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.redPink.withOpacity(0.2), width: 2),
                  color: AppTheme.redPink.withOpacity(0.08),
                ),
                child: ClipOval(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 28, color: AppTheme.redPink),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? 'Unknown User' : fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: 12, color: AppTheme.darkGray.withOpacity(0.45)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          campusName,
                          style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.55)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.redPink.withOpacity(0.12), AppTheme.redPink.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.redPink.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.redPink, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$points',
                    style: const TextStyle(
                      fontSize: 15,
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

class _LeaderboardSkeletonItem extends StatelessWidget {
  const _LeaderboardSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SkeletonCircle(size: 32),
            const SizedBox(width: 12),
            SkeletonCircle(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 12, borderRadius: 6),
                ],
              ),
            ),
            SkeletonBox(width: 70, height: 32, borderRadius: 30),
          ],
        ),
      ),
    );
  }
}