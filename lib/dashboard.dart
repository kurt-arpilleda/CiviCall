import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/drawerNavigation/drawerNavigation.dart';
import 'package:civicall/auto_update.dart';
import 'package:civicall/drawerNavigation/reportProblem.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<String> _pageTitles = [
    'Home',
    'Information',
    'Forum',
    'Notifications',
  ];

  final List<Widget> _pages = const [
    _DummyPage(label: 'Home', icon: Icons.home_rounded),
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
                      MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
                    );
                  },
                ),
                _buildActionChip(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Add Engagement',
                  color: const Color(0xFF2E7D5E),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Add engagement navigation
                  },
                ),
                _buildActionChip(
                  icon: Icons.event_outlined,
                  label: 'Event',
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Event navigation
                  },
                ),
                _buildActionChip(
                  icon: Icons.post_add_outlined,
                  label: 'Post in Forum',
                  color: const Color(0xFF6A1B9A),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Post in forum navigation
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
              onPressed: () {},
            ),
          ],
        ),
        body: IndexedStack(
          index: pageIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildCenterFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppTheme.darkGray,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.3),
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 56,
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
            const SizedBox(width: 56),
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
      borderRadius: BorderRadius.circular(12),
      splashColor: AppTheme.white.withOpacity(0.08),
      highlightColor: AppTheme.white.withOpacity(0.05),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive
                    ? AppTheme.redPink
                    : AppTheme.white.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? AppTheme.redPink
                    : AppTheme.white.withOpacity(0.6),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab() {
    return GestureDetector(
      onTap: () => _showAddSheet(),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE84757), AppTheme.redPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.redPink.withOpacity(0.4),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppTheme.white,
          size: 30,
        ),
      ),
    );
  }
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
            child: Icon(icon,
                size: 38, color: AppTheme.redPink.withOpacity(0.6)),
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