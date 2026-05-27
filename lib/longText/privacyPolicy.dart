import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
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
                    _buildDocTitle('CiviCall App Privacy Policy'),
                    _buildSubtitle('Last Updated: 09/11/23'),
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 8),
                    _buildBodyText(
                      'Thank you for using the CiviCall app developed for students and alumni of Batangas State University, The National Engineering University. This Privacy Policy is designed to help you understand how your personal information is collected, used, and safeguarded by the CiviCall app.',
                    ),
                    _buildSectionHeading('Information We Collect'),
                    _buildSubSectionHeading('User Registration Information:'),
                    _buildBodyText(
                      'When you register for the CiviCall app, we collect and store information such as your name, university credentials, and contact details etc.',
                    ),
                    _buildSubSectionHeading('Civic Engagement Information:'),
                    _buildBodyText(
                      'The app allows users to request and apply for civic engagements. Information related to these engagements, including posts, applications, and progress tracking, is stored for administrative and recognition purposes.',
                    ),
                    _buildSubSectionHeading('Communication Information:'),
                    _buildBodyText(
                      'The app features communication modules, including open forums and discussion. Information shared in these interactions is stored to facilitate discussions and user engagement.',
                    ),
                    _buildSubSectionHeading('Educational Resources Information:'),
                    _buildBodyText(
                      'CiviCall app includes educational resources with categorical subjects and contact directories. Your interaction with these resources may be logged for improvement and user experience.',
                    ),
                    _buildSubSectionHeading('Recognition Information:'),
                    _buildBodyText(
                      'CiviCall app includes educational resources with categorical subjects and contact directories. Your interaction with these resources will help you to have fundamental knowledge about Civic Engagement.',
                    ),
                    _buildSectionHeading('How We Use Your Information?'),
                    _buildSubSectionHeading('We use the collected information for the following purposes:'),
                    _buildBodyText('USER AUTHENTICATION: To verify and authenticate users during registration and login processes.'),
                    _buildBodyText('CIVIC ENGAGEMENT: To facilitate and track user participation in civic engagement activities.'),
                    _buildBodyText('COMMUNICATION: To enable discussions, feedback, and notifications among users.'),
                    _buildBodyText('EDUCATIONAL RESOURCES: To provide relevant information and resources to users.'),
                    _buildBodyText('RECOGNITION: To acknowledge and recognize users for their active participation.'),
                    _buildSectionHeading('Information Sharing and Disclosure'),
                    _buildBodyText(
                      'We do not sell, trade, or otherwise transfer your personal information to outside parties. Your information is only shared within the CiviCall platform for the purposes stated in this Privacy Policy.',
                    ),
                    _buildSectionHeading('Security'),
                    _buildBodyText(
                      'We take reasonable measures to protect your personal information from unauthorized access, disclosure, alteration, and destruction. However, no method of transmission over the internet or method of electronic storage is 100% secure.',
                    ),
                    _buildSectionHeading('Limitations'),
                    _buildBodyText('A stable internet connection is required for app functionality.'),
                    _buildBodyText('Limited accessibility in areas with poor connectivity.'),
                    _buildBodyText('The app is currently available only on Android OS devices.'),
                    _buildSectionHeading('Changes to this Privacy Policy'),
                    _buildBodyText(
                      'The app is currently available only on Android OS devices. We may update this Privacy Policy from time to time. Users will be notified of significant changes.',
                    ),
                    _buildSectionHeading('Contact Information'),
                    _buildBodyText(
                      'If you have any questions or concerns regarding this Privacy Policy, please contact us at',
                    ),
                    _buildClickableContact(
                      icon: Icons.email_outlined,
                      label: 'appcivicall@gmail.com',
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'appcivicall@gmail.com',
                          queryParameters: {
                            'subject': 'Privacy Policy Inquiry - CiviCall App',
                          },
                        );
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
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
                'PRIVACY POLICY',
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

  Widget _buildSubSectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkGray.withOpacity(0.85),
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

  Widget _buildClickableContact({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.redPink),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                height: 1.65,
                color: AppTheme.redPink,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.redPink,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}