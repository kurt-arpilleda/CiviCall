import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDocTitle('CiviCall App Terms And Condition'),
                    _buildSubtitle('Last Updated: 09/11/23'),
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 8),
                    _buildSectionHeading('Introductions'),
                    _buildBodyText(
                      'Welcome to CiviCall, a digital civic engagement platform designed for students and alumni of Batangas State University. By using this application, you agree to abide by the following terms and conditions.',
                    ),
                    _buildSectionHeading('Use of the App'),
                    _buildBodyText(
                      'The CiviCall app is exclusively for Batangas State University TNEU. Any other users are not eligible to use the app unless it is allowed by the university.',
                    ),
                    _buildBodyText(
                      'Users must register with their university credentials to access and use the app.',
                    ),
                    _buildBodyText(
                      'Users are responsible for their actions, posts, and interactions within the app. The app administrators hold the right to moderate and take action against any content deemed inappropriate.',
                    ),
                    _buildSectionHeading('Features and Functions'),
                    _buildBodyText(
                      'CiviCall offers various features such as civic engagement opportunities, forums, notifications, and educational resources.',
                    ),
                    _buildBodyText(
                      'Users can request, apply to, or join civic engagements, participate in forum discussions, give feedback, and access educational resources.',
                    ),
                    _buildBodyText(
                      'Super Admin and Sub-Admins are responsible for user management, forum moderation, post validation, and managing civic engagement opportunities.',
                    ),
                    _buildSectionHeading('Liabilities and Limitations'),
                    _buildBodyText(
                      'The CiviCall app is designed exclusively for Batangas State University students and alumni. It may face technical issues or limitations, including connectivity requirements and compatibility limitations (only available on Android devices).',
                    ),
                    _buildBodyText(
                      'Administrators hold the right to validate, reject, or archive user-generated content, and may take action against content that violates the app\'s guidelines.',
                    ),
                    _buildSectionHeading('Disclaimers'),
                    _buildBodyText(
                      'Users access and use CiviCall at their own risk. The app developers are not liable for any direct or indirect damages resulting from the app\'s use.',
                    ),
                    _buildBodyText(
                      'The app\'s availability is subject to technical constraints and may not be uninterrupted, timely, or error-free.',
                    ),
                    _buildSectionHeading('Termination and Modifications'),
                    _buildBodyText(
                      'The app administrators reserve the right to terminate or suspend user accounts for violations of the app\'s terms and guidelines.',
                    ),
                    _buildBodyText(
                      'CiviCall reserves the right to update or modify these terms and conditions. Users will be notified of any changes.',
                    ),
                    _buildSectionHeading('Acceptance of Terms'),
                    _buildBodyText(
                      'CiviCall reserves the right to update or modify these terms and conditions. Users will be notified of any changes.',
                    ),
                    _buildSectionHeading('Contact Information'),
                    _buildBodyText(
                      'For any queries or concerns regarding these terms, contact us at [09267383649].',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppTheme.redPink,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Text(
                'TERMS AND CONDITIONS',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppTheme.darkGray,
        fontFamily: AppTheme.fontFamily,
        height: 1.3,
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.darkGray.withOpacity(0.55),
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        height: 160,
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.redPink.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Image.asset(
          'assets/images/icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkGray,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.65,
          color: AppTheme.darkGray.withOpacity(0.72),
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}