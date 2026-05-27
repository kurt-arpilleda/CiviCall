import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
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
                    _buildLogo(),
                    const SizedBox(height: 16),
                    _buildAppName(),
                    const SizedBox(height: 24),
                    _buildBodyText(
                      'Civcall App is a powerful community volunteer app design specifically for students, providing them with a platform to make a positive impact in their community and beyond.',
                    ),
                    const SizedBox(height: 12),
                    _buildBodyText(
                      'Now you can effortlessly discover Nearby Volunteer Opportunities, Refine result, invite your friends and share contributions with your school.',
                    ),
                    const SizedBox(height: 32),
                    _buildSocialRow(
                      iconLabel: 'f',
                      label: 'Contact us in Facebook',
                      url: 'https://www.facebook.com/BatStateUTheNEU/',
                    ),
                    const SizedBox(height: 16),
                    _buildSocialRow(
                      iconLabel: '𝕏',
                      label: 'Follow us on X (Twitter)',
                      url: 'https://x.com/BatStateUTheNEU',
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
              const Text(
                'ABOUT US',
                style: TextStyle(
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

  Widget _buildAppName() {
    return Center(
      child: Text(
        'CiviCall App',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppTheme.darkGray,
          fontFamily: AppTheme.fontFamily,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.65,
        color: AppTheme.darkGray.withOpacity(0.72),
        fontFamily: AppTheme.fontFamily,
      ),
    );
  }

  Widget _buildSocialRow({
    required String iconLabel,
    required String label,
    required String url,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.redPink,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                iconLabel,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
    );
  }
}