import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const Color _backgroundColor = Color(0xFFFAF9FC);
  static const Color _primaryColor = Color(0xFF3D84A8);
  static const Color _secondaryTextColor = Color(0xFF666666);

  // ==========================================================================
  // THEME COLORS
  // ==========================================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : _backgroundColor;

  Color get _secondaryTextColorForTheme =>
      _isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

  // ==========================================================================
  // ONBOARDING DATA
  // ==========================================================================

  List<_OnboardingItem> _getPages(AppLocalizations l10n) {
    return [
      _OnboardingItem(
        title: l10n.welcomeToMedelyra,
        description: l10n.welcomeToMedelyraDescription,
      ),
      _OnboardingItem(
        title: l10n.stayOnTrack,
        description: l10n.stayOnTrackDescription,
      ),
      _OnboardingItem(
        title: l10n.toolsForYourHealth,
        description: l10n.toolsForYourHealthDescription,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // NEXT PAGE
  // ==========================================================================

  void _nextPage(int pageCount) {
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  // ==========================================================================
  // FINISH ONBOARDING
  // ==========================================================================

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/signin');
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------------
            // TOP BAR
            // ------------------------------------------------------------------

            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _currentPage < pages.length - 1
                      ? TextButton(
                          onPressed: _finishOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: _secondaryTextColorForTheme,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            l10n.skip,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _secondaryTextColorForTheme,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // ------------------------------------------------------------------
            // PAGES
            // ------------------------------------------------------------------

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingContent(
                    page: pages[index],
                    pageIndex: index,
                    isSmallScreen: isSmallScreen,
                    l10n: l10n,
                  );
                },
              ),
            ),

            // ------------------------------------------------------------------
            // BOTTOM CONTROLS
            // ------------------------------------------------------------------

            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                isSmallScreen ? 18 : 24,
              ),
              child: Column(
                children: [
                  // ------------------------------------------------------------
                  // PAGE INDICATORS
                  // ------------------------------------------------------------

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
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

                  SizedBox(
                    height: isSmallScreen ? 20 : 25,
                  ),

                  // ------------------------------------------------------------
                  // BUTTON
                  // ------------------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _nextPage(pages.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == pages.length - 1
                            ? l10n.getStarted
                            : l10n.next,
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

// ============================================================================
// ONBOARDING CONTENT
// ============================================================================

class _OnboardingContent extends StatelessWidget {
  final _OnboardingItem page;
  final int pageIndex;
  final bool isSmallScreen;
  final AppLocalizations l10n;

  const _OnboardingContent({
    required this.page,
    required this.pageIndex,
    required this.isSmallScreen,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryTextColor =
        isDark ? Colors.white : const Color(0xFF333333);

    final Color secondaryTextColor =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF666666);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isSmallScreen ? 12 : 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --------------------------------------------------------
                      // ILLUSTRATION
                      // --------------------------------------------------------

                      _buildIllustration(),

                      // --------------------------------------------------------
                      // SPACE AFTER ILLUSTRATION
                      // --------------------------------------------------------

                      SizedBox(
                        height: isSmallScreen ? 16 : 22,
                      ),

                      // --------------------------------------------------------
                      // TITLE
                      // --------------------------------------------------------

                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 25 : 28,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                          fontFamily: 'serif',
                        ),
                      ),

                      // --------------------------------------------------------
                      // DESCRIPTION
                      // --------------------------------------------------------

                      const SizedBox(height: 14),

                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15.5 : 17,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
                          fontFamily: 'serif',
                        ),
                      ),

                      // --------------------------------------------------------
                      // FEATURES
                      // --------------------------------------------------------

                      SizedBox(
                        height: isSmallScreen ? 26 : 34,
                      ),

                      if (pageIndex == 1) ...[
                        _FeatureRow(
                          icon: Icons.alarm_outlined,
                          text: l10n.medicationReminders,
                        ),
                        const SizedBox(height: 14),
                        _FeatureRow(
                          icon: Icons.calendar_today_outlined,
                          text: l10n.appointmentReminders,
                        ),
                      ],

                      if (pageIndex == 2) ...[
                        _FeatureRow(
                          icon: Icons.health_and_safety_outlined,
                          text: l10n.helpfulHealthTools,
                        ),
                        const SizedBox(height: 14),
                        _FeatureRow(
                          icon: Icons.medical_services_outlined,
                          text: l10n.emergencyGuidance,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // ILLUSTRATIONS
  // ==========================================================================

  Widget _buildIllustration() {
    // ------------------------------------------------------------------------
    // PAGE 1 — MEDELYRA LOGO
    // ------------------------------------------------------------------------

    if (pageIndex == 0) {
      return Image.asset(
        'assets/medelyraIcon.png',
        width: isSmallScreen ? 120 : 145,
        height: isSmallScreen ? 120 : 145,
        fit: BoxFit.contain,
      );
    }

    // ------------------------------------------------------------------------
    // PAGE 2 + PAGE 3 — ILLUSTRATIONS
    // ------------------------------------------------------------------------

    return Image.asset(
      pageIndex == 1
          ? 'assets/onboarding_reminders.png'
          : 'assets/onboarding_health.png',
      width: isSmallScreen ? 220 : 255,
      height: isSmallScreen ? 220 : 255,
      fit: BoxFit.contain,
    );
  }
}

// ============================================================================
// ONBOARDING DATA
// ============================================================================

class _OnboardingItem {
  final String title;
  final String description;

  const _OnboardingItem({
    required this.title,
    required this.description,
  });
}

// ============================================================================
// FEATURE ROW
// ============================================================================

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF555555);

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
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}
