import 'package:civicall/drawerNavigation/settings.dart';
import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/login.dart';
import 'package:civicall/google_signin_service.dart';
import 'package:civicall/drawerNavigation/accountDetails.dart';
import 'package:civicall/drawerNavigation/userVerification.dart';
import 'package:civicall/anim/skeletonAnimation.dart';
import 'package:civicall/imageViewer.dart';
import 'package:civicall/drawerNavigation/feedBack.dart';
import 'package:civicall/drawerNavigation/scheduleCalendar.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _isLoading = true);
    final response = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          _userData = response['user'] as Map<String, dynamic>?;
        }
        _isLoading = false;
      });
    }
  }

  String get _fullName {
    if (_userData == null) return 'User';
    final first = (_userData!['firstName'] ?? '').toString().trim();
    final last = (_userData!['lastName'] ?? '').toString().trim();
    return '$first $last'.trim();
  }

  String get _email => (_userData?['email'] ?? '').toString();

  bool get _isVerified => (_userData?['isVerified'] ?? 0) == 1;

  ImageProvider? _resolveProfileImage() {
    final raw = _userData?['photo_url'];
    if (raw == null) return null;
    final url = raw.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return NetworkImage('${ApiService.apiUrl}profileImage/$url');
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.darkGray),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.darkGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.darkGray.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redPink,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _apiService.logout();
    await _apiService.clearAuthToken();
    await GoogleSignInService.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                color: AppTheme.darkGray,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Account Details',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AccountDetailsScreen(
                              userData: _userData,
                              onProfileUpdated: _loadUserData,
                            ),
                          ),
                        );
                        _loadUserData();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.verified_user_outlined,
                      label: 'Account Verification',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserVerificationScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Schedule Calendar',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScheduleCalendarScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.feedback_outlined,
                      label: 'Feedback',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeedBackScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.security_outlined,
                      label: 'Settings and Privacy',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.emoji_events_outlined,
                      label: 'Leaderboard',
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        color: AppTheme.white.withOpacity(0.1),
                        height: 1,
                        thickness: 1,
                      ),
                    ),
                    _buildLogoutButton(context),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.redPink,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 28,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      child: _isLoading
          ? const DrawerHeaderSkeleton()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(height: 14),
          Text(
            _fullName,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _isVerified
                    ? Icons.verified_rounded
                    : Icons.cancel_outlined,
                size: 15,
                color: _isVerified
                    ? Colors.greenAccent.shade200
                    : Colors.white38,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _email,
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final imageProvider = _resolveProfileImage();
    return GestureDetector(
      onTap: imageProvider != null
          ? () => showFullScreenImage(context, imageProvider)
          : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.white.withOpacity(0.5),
            width: 2.5,
          ),
          color: AppTheme.white.withOpacity(0.2),
        ),
        child: ClipOval(
          child: imageProvider != null
              ? Image(
            image: imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(),
          )
              : _avatarFallback(),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppTheme.white.withOpacity(0.2),
      child: const Icon(
        Icons.person_rounded,
        size: 38,
        color: AppTheme.white,
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.white.withOpacity(0.06),
      highlightColor: AppTheme.white.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.white.withOpacity(0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(14),
        splashColor: AppTheme.redPink.withOpacity(0.15),
        highlightColor: AppTheme.redPink.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.redPink.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.redPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.redPink,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}