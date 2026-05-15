import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for animation + minimum splash duration (~1900ms, same as Kotlin delay)
    await Future.delayed(const Duration(milliseconds: 1900));

    if (!mounted) return;

    await _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

      if (isFirstOpen) {
        await prefs.setBool('isFirstOpen', false);
        _navigateWithFade('/splash'); // or your onboarding route
        return;
      }

      final apiService = ApiService();
      final authToken = await apiService.getAuthToken();

      if (authToken != null) {
        _navigateWithFade('/checkAccount');
      } else {
        _navigateWithFade('/login');
      }
    } catch (_) {
      _navigateWithFade('/login');
    }
  }

  void _navigateWithFade(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color: <color name="DarkGray">#333333</color>
      backgroundColor: const Color(0xFF333333),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon
              Image.asset(
                'assets/images/icon.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              // App name
              const Text(
                'CiviCall',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle / tagline
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Serving the community, Collaborating with Others',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}