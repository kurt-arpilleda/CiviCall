import 'package:civicall/drawerNavigation/reportProblem.dart';
import 'package:civicall/longText/privacyPolicy.dart';
import 'package:civicall/longText/termsConditions.dart';
import 'package:civicall/longText/aboutUs.dart';
import 'package:civicall/forgot_password_dialog.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _isTogglingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationPreference();
  }

  Future<void> _loadUserData() async {
    final response = await _apiService.getUserData();
    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _userData = response['user'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_isTogglingNotifications) return;
    setState(() => _isTogglingNotifications = true);

    if (value) {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', true);
        setState(() {
          _notificationsEnabled = true;
          _isTogglingNotifications = false;
        });
        Fluttertoast.showToast(
          msg: 'Notifications enabled',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        setState(() {
          _notificationsEnabled = false;
          _isTogglingNotifications = false;
        });
        Fluttertoast.showToast(
          msg: 'Permission denied. Enable in system settings.',
          backgroundColor: AppTheme.redPink,
          textColor: Colors.white,
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
      setState(() {
        _notificationsEnabled = false;
        _isTogglingNotifications = false;
      });
      Fluttertoast.showToast(
        msg: 'Notifications disabled',
        backgroundColor: AppTheme.darkGray,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
        backgroundColor: AppTheme.redPink,
        foregroundColor: AppTheme.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.redPink))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            if (_userData != null && (_userData!['signup_type'] as int) == 0)
              _buildSection('Account Security', [
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    final userEmail = _userData!['email']?.toString() ?? '';
                    showDialog(
                      context: context,
                      builder: (_) => ForgotPasswordDialog(
                        initialEmailOrPhone: userEmail,
                      ),
                    );
                  },
                ),
              ]),
            _buildSection('Preferences', [
              _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive alerts and updates',
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                isLoading: _isTogglingNotifications,
              ),
            ]),
            _buildSection('Support', [
              _buildSettingsTile(
                icon: Icons.report_problem_rounded,
                title: 'Report Problems',
                subtitle: 'Report bugs or issues',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
                  );
                },
              ),
            ]),
            _buildSection('Terms and Support', [
              _buildSettingsTile(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.description_rounded,
                title: 'Terms & Conditions',
                subtitle: 'Terms of use',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Us',
                subtitle: 'Learn more about CiviCall',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.redPink,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.redPink, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGray.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.darkGray.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.redPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.redPink, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGray.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.redPink,
              ),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.white,
              activeTrackColor: AppTheme.redPink,
              inactiveThumbColor: AppTheme.white,
              inactiveTrackColor: AppTheme.darkGray.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
}