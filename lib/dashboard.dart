import 'dart:ui' as ui;
import 'package:civicall/addDrawer/addEngagement.dart';
import 'package:civicall/drawerNavigation/userVerification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/drawerNavigation/drawerNavigation.dart';
import 'package:civicall/auto_update.dart';
import 'package:civicall/drawerNavigation/reportProblem.dart';
import 'package:civicall/homePage/engagementPost.dart';
import 'package:civicall/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  final GlobalKey<EngagementFeedScreenState> _engagementFeedKey =
  GlobalKey<EngagementFeedScreenState>();

  static const List<String> _pageTitles = [
    'Home',
    'Information',
    'Forum',
    'Notifications',
  ];

  final List<Widget> _pages = const [
    EngagementFeedScreen(),
    _DummyPage(label: 'Information', icon: Icons.info_outline_rounded),
    _DummyPage(label: 'Forum', icon: Icons.forum_outlined),
    _DummyPage(label: 'Notifications', icon: Icons.notifications_outlined),
  ];

  int _navIndexToPageIndex(int navIndex) {
    const map = {0: 0, 1: 1, 3: 2, 4: 3};
    return map[navIndex] ?? 0;
  }

  void _onTabTapped(int navIndex) {
    if (navIndex == 2) {
      _showAddSheet();
      return;
    }
    setState(() => _selectedIndex = navIndex);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
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
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionChip(
                  icon: Icons.campaign_outlined,
                  label: 'Report',
                  color: AppTheme.redPink,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReportProblemScreen()),
                    );
                  },
                ),
                _buildActionChip(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Add Engagement',
                  color: const Color(0xFF2E7D5E),
                  onTap: () async {
                    Navigator.pop(context);
                    final userRes = await _apiService.getUserData();
                    if (!mounted) return;
                    final isVerified = userRes['success'] == true &&
                        (userRes['user']?['isVerified'] ?? 0) == 1;
                    if (!isVerified) {
                      _showUnverifiedDialog();
                      return;
                    }
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddEngagementScreen()));
                    _engagementFeedKey.currentState?.refresh();
                  },
                ),
                _buildActionChip(
                  icon: Icons.event_outlined,
                  label: 'Event',
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildActionChip(
                  icon: Icons.post_add_outlined,
                  label: 'Post in Forum',
                  color: const Color(0xFF6A1B9A),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  void _showUnverifiedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined,
                  color: AppTheme.redPink, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verification Required',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You need to verify your account before you can add an engagement.',
              style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.darkGray.withOpacity(0.65),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Maybe Later',
                style: TextStyle(color: AppTheme.darkGray.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UserVerificationScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redPink,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AutoUpdate.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = _navIndexToPageIndex(_selectedIndex);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isGestureNavigation = bottomPadding > 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.redPink,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F6FA),
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: AppTheme.redPink,
          foregroundColor: AppTheme.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            _pageTitles[pageIndex],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 24),
              onPressed: () {
                if (_selectedIndex == 0 || _navIndexToPageIndex(_selectedIndex) == 0) {
                  showSearch(
                    context: context,
                    delegate: EngagementSearchDelegate(
                      engagements: _engagementFeedKey.currentState?.engagements ?? [],
                      currentUserId: _engagementFeedKey.currentState?.currentUserId,
                      onRefresh: () => _engagementFeedKey.currentState?.refresh(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: pageIndex,
          children: [
            EngagementFeedScreen(key: _engagementFeedKey),
            _pages[1],
            _pages[2],
            _pages[3],
          ],
        ),
        bottomNavigationBar: _buildBottomNav(isGestureNavigation),
        floatingActionButton: _buildTikTokFab(),
        floatingActionButtonLocation: isGestureNavigation
            ? FloatingActionButtonLocation.centerDocked
            : CustomFloatingActionButtonLocation(),
      ),
    );
  }

  Widget _buildBottomNav(bool isGestureNavigation) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = isGestureNavigation ? 64.0 : 56.0;
    final extraBottomPadding = isGestureNavigation ? 8.0 : 0.0;

    return Container(
      height: navBarHeight + bottomPadding,
      decoration: BoxDecoration(
        color: AppTheme.darkGray,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: navBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  navIndex: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  navIndex: 1,
                  icon: Icons.info_outline_rounded,
                  activeIcon: Icons.info_rounded,
                  label: 'Info',
                ),
                const SizedBox(width: 52),
                _buildNavItem(
                  navIndex: 3,
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum_rounded,
                  label: 'Forum',
                ),
                _buildNavItem(
                  navIndex: 4,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Alerts',
                ),
              ],
            ),
          ),
          if (isGestureNavigation) SizedBox(height: extraBottomPadding),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int navIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _selectedIndex == navIndex;
    return InkWell(
      onTap: () => _onTabTapped(navIndex),
      borderRadius: BorderRadius.circular(8),
      splashColor: AppTheme.white.withOpacity(0.08),
      highlightColor: AppTheme.white.withOpacity(0.05),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color:
                isActive ? AppTheme.redPink : AppTheme.white.withOpacity(0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color:
                isActive ? AppTheme.redPink : AppTheme.white.withOpacity(0.5),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTikTokFab() {
    return GestureDetector(
      onTap: () => _showAddSheet(),
      child: CustomPaint(
        painter: TikTokFabPainter(),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_rounded,
            color: AppTheme.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class TikTokFabPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE84757), Color(0xFFE53935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFFE53935).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final w = size.width;
    final h = size.height;
    final radius = 14.0;
    final notchDepth = 6.0;
    final cornerRadius = 4.0;

    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(w - cornerRadius, 0);
    path.quadraticBezierTo(w, 0, w, cornerRadius);
    path.lineTo(w, h - radius);
    path.quadraticBezierTo(w, h - radius + notchDepth, w - notchDepth, h - radius + notchDepth * 1.5);
    path.lineTo(w / 2 + radius * 0.8, h);
    path.lineTo(w / 2 - radius * 0.8, h);
    path.lineTo(notchDepth, h - radius + notchDepth * 1.5);
    path.quadraticBezierTo(0, h - radius + notchDepth, 0, h - radius);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        scaffoldGeometry.minInsets.bottom -
        28;
    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'CustomFloatingActionButtonLocation';
}

class _DummyPage extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DummyPage({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.redPink.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child:
            Icon(icon, size: 38, color: AppTheme.redPink.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkGray.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkGray.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}