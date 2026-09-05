import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final Color _backgroundColor = const Color(0xFFFAF9FC);
  final Color _primaryColor = const Color(0xFF3D84A8);
  final Color _textColor = const Color(0xFF333333);
  final Color _secondaryTextColor = const Color(0xFF666666);

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: 'Welcome to Medelyra',
      description:
          'Your simple companion for staying organized and prepared for your health.',
      icon: Icons.favorite_outline,
    ),
    _OnboardingItem(
      title: 'Stay on track',
      description:
          'Keep your medications and appointments organized with reminders that fit into your day.',
      icon: Icons.medication_outlined,
    ),
    _OnboardingItem(
      title: 'Tools for your health',
      description:
          'Use helpful health tools and access emergency guidance when you need it.',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: _currentPage < _pages.length - 1
                    ? TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
            ),

            /// PAGES
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: smallScreen ? 10 : 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 430,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: smallScreen ? 10 : 25,
                          ),

                          /// LOGO ON FIRST PAGE
                          if (index == 0)
                            Image.asset(
                              'assets/medelyraIcon.png',
                              width: smallScreen ? 105 : 125,
                              height: smallScreen ? 105 : 125,
                              fit: BoxFit.contain,
                            )
                          else
                            _FeatureIcon(
                              icon: page.icon,
                              primaryColor: _primaryColor,
                            ),

                          SizedBox(
                            height: smallScreen ? 35 : 45,
                          ),

                          /// TITLE
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: smallScreen ? 25 : 28,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                              fontFamily: 'serif',
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// DESCRIPTION
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: smallScreen ? 15.5 : 17,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: _secondaryTextColor,
                              fontFamily: 'serif',
                            ),
                          ),

                          SizedBox(
                            height: smallScreen ? 35 : 55,
                          ),

                          /// PAGE 2 FEATURES
                          if (index == 1)
                            const _FeatureRow(
                              icon: Icons.alarm_outlined,
                              text: 'Medication reminders',
                            ),

                          if (index == 1) const SizedBox(height: 14),

                          if (index == 1)
                            const _FeatureRow(
                              icon: Icons.calendar_today_outlined,
                              text: 'Appointment reminders',
                            ),

                          /// PAGE 3 FEATURES
                          if (index == 2)
                            const _FeatureRow(
                              icon: Icons.health_and_safety_outlined,
                              text: 'Helpful health tools',
                            ),

                          if (index == 2) const SizedBox(height: 14),

                          if (index == 2)
                            const _FeatureRow(
                              icon: Icons.medical_services_outlined,
                              text: 'Emergency guidance',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// BOTTOM CONTROLS
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
              child: Column(
                children: [
                  /// PAGE INDICATORS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) {
                        final selected = index == _currentPage;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: selected
                                ? _primaryColor
                                : _primaryColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                        ),
                      ),
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

/// ------------------------------------------------------------
/// ONBOARDING DATA
/// ------------------------------------------------------------

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// ------------------------------------------------------------
/// FEATURE ICON
/// ------------------------------------------------------------

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color primaryColor;

  const _FeatureIcon({
    required this.icon,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      height: 125,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withOpacity(0.08),
      ),
      child: Icon(
        icon,
        size: 58,
        color: primaryColor,
      ),
    );
  }
}

/// ------------------------------------------------------------
/// FEATURE ROW
/// ------------------------------------------------------------

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: const Color(0xFF3D84A8),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF555555),
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}
