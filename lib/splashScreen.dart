import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showOnboarding = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: _showOnboarding ? const OnboardingScreen() : const SplashLogo(),
    );
  }
}

class SplashLogo extends StatelessWidget {
  const SplashLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.redPink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icon.png',
              height: 180,
              width: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'CiviCall',
              style: TextStyle(
                fontFamily: 'OleoScript',
                fontSize: 65,
                letterSpacing: 0.1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Serving the community,\nCollaborating with others',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 18,
                letterSpacing: 0.2,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String image;
  final String title;
  final String desc;
  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.desc,
  });
}

// ─────────────────────────────────────────────────────────────
// Main screen — background cross-fades, card content slides in
// ─────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  bool _swipingLeft = true; // true = going forward, false = going back

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      image: 'assets/images/volunteer.jpg',
      title: 'Join the Movement: Building a Stronger Community Together',
      desc:
      'Volunteer for community building; make a positive impact for others. Strengthen bonds, create unity, and leave a legacy of cooperation and kindness. Inspire others to build a brighter future.',
    ),
    _OnboardingPage(
      image: 'assets/images/volunteer2.jpg',
      title: 'Join the Effort to Revitalize our Environment',
      desc:
      'Contribute to environmental restoration. Make a difference, preserve nature, and leave a lasting impact for a sustainable future.',
    ),
    _OnboardingPage(
      image: 'assets/images/volunteer3.jpg',
      title: 'Lead by Example for the Next Generation',
      desc:
      'Become a role model for the next generation. Inspire and guide them towards a brighter future.',
    ),
  ];

  void _goToLogin() =>
      Navigator.pushReplacementNamed(context, '/login');

  void _next() {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _swipingLeft = true;
        _currentPage++;
      });
    } else {
      _goToLogin();
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      setState(() {
        _swipingLeft = false;
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -300) {
            _next(); // swipe left → next
          } else if (velocity > 300) {
            _prev(); // swipe right → prev
          }
        },
        child: Stack(
          children: [
            // ── Background: cross-fades between images ──────────
            _AnimatedBackground(
              imagePath: _pages[_currentPage].image,
            ),

            // ── Bottom card: only the content animates ──────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  24, 20, 24,
                  20 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Animated text content ──────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        final slideIn = Tween<Offset>(
                          begin: Offset(_swipingLeft ? 0.12 : -0.12, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slideIn,
                            child: child,
                          ),
                        );
                      },
                      child: _PageContent(
                        key: ValueKey(_currentPage),
                        page: _pages[_currentPage],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Dot indicators ─────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 8,
                          width: _currentPage == i ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppTheme.redPink
                                : AppTheme.darkGray.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Skip ───────────────────────────────────
                    OutlinedButton(
                      onPressed: _goToLogin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.redPink),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'DMSansRegular',
                          fontSize: 17,
                          color: AppTheme.redPink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Next / Get Started ─────────────────────
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.redPink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontFamily: 'DMSansRegular',
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ), // Stack
      ), // GestureDetector
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Background cross-fade widget
// ─────────────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final String imagePath;
  const _AnimatedBackground({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: SizedBox.expand(
        key: ValueKey(imagePath),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated content block (title + desc)
// ─────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({Key? key, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DMSansBold',
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.redPink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.desc,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DMSansMedium',
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}