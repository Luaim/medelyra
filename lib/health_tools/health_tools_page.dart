import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/nav_bar.dart';
import 'age.dart';
import 'blood_pressure.dart';
import 'bmi.dart';
import 'heart_rate.dart';
import 'medical_unit_converter_page.dart';
import 'sleep_calculator.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFF3D84A8);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class HealthToolsPage extends StatefulWidget {
  const HealthToolsPage({super.key});

  @override
  State<HealthToolsPage> createState() => _HealthToolsPageState();
}

class _HealthToolsPageState extends State<HealthToolsPage> {
  final TextEditingController _searchController = TextEditingController();

  // --------------------------------------------------------------------------
  // DARK MODE COLORS
  // --------------------------------------------------------------------------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : _backgroundColor;

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF252525) : Colors.white;

  Color get _borderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

  Color get _primaryTextColor => _isDark ? Colors.white : _textColor;

  Color get _secondaryTextColorForTheme =>
      _isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

  // --------------------------------------------------------------------------
  // HEALTH TOOLS
  // --------------------------------------------------------------------------

  List<_HealthTool> _tools = [];

  late List<_HealthTool> _filteredTools;

  // --------------------------------------------------------------------------
  // INIT
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterTools);
  }

  // --------------------------------------------------------------------------
  // DISPOSE
  // --------------------------------------------------------------------------

  @override
  void dispose() {
    _searchController.removeListener(_filterTools);
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOCALIZED TOOLS
  // --------------------------------------------------------------------------

  List<_HealthTool> _buildTools(AppLocalizations l10n) {
    return [
      _HealthTool(
        id: 'bmi',
        title: l10n.bmiToolTitle,
        description: l10n.bmiToolDescription,
        icon: Icons.monitor_weight_outlined,
        iconColor: const Color(0xFF3D84A8),
      ),
      _HealthTool(
        id: 'age',
        title: l10n.ageToolTitle,
        description: l10n.ageToolDescription,
        icon: Icons.cake_outlined,
        iconColor: const Color(0xFFD18B3C),
      ),
      _HealthTool(
        id: 'blood_pressure',
        title: l10n.bloodPressureToolTitle,
        description: l10n.bloodPressureToolDescription,
        icon: Icons.favorite_outline,
        iconColor: const Color(0xFFD95C68),
      ),
      _HealthTool(
        id: 'heart_rate',
        title: l10n.heartRateToolTitle,
        description: l10n.heartRateToolDescription,
        icon: Icons.monitor_heart_outlined,
        iconColor: const Color(0xFFC95C68),
      ),
      _HealthTool(
        id: 'medical_unit_converter',
        title: l10n.medicalUnitConverterToolTitle,
        description: l10n.medicalUnitConverterToolDescription,
        icon: Icons.swap_horiz_rounded,
        iconColor: const Color(0xFF7167B7),
      ),
      _HealthTool(
        id: 'sleep_calculator',
        title: l10n.sleepCalculatorToolTitle,
        description: l10n.sleepCalculatorToolDescription,
        icon: Icons.bedtime_outlined,
        iconColor: const Color(0xFF6B67B7),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // SEARCH
  // --------------------------------------------------------------------------

  void _filterTools() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredTools = _tools;
      } else {
        _filteredTools = _tools.where((tool) {
          return tool.title.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // --------------------------------------------------------------------------
  // OPEN TOOL
  // --------------------------------------------------------------------------

  void _openTool(_HealthTool tool) {
    if (tool.id == 'bmi') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const BmiPage();
        },
      );

      return;
    }

    if (tool.id == 'age') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const AgePage();
        },
      );

      return;
    }

    if (tool.id == 'blood_pressure') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const BloodPressurePage();
        },
      );

      return;
    }

    if (tool.id == 'heart_rate') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const HeartRatePage();
        },
      );

      return;
    }

    if (tool.id == 'medical_unit_converter') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const MedicalUnitConverterPage();
        },
      );

      return;
    }

    if (tool.id == 'sleep_calculator') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const SleepCalculatorPage();
        },
      );

      return;
    }
  }

  // --------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------------------------------

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case 1:
        Navigator.pushReplacementNamed(context, '/reminder');
        break;

      case 2:
        // Already on Health Tools.
        break;

      case 3:
        Navigator.pushReplacementNamed(context, '/sos');
        break;

      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Rebuild the localized tool list whenever the page builds.
    _tools = _buildTools(l10n);

    if (_searchController.text.trim().isEmpty) {
      _filteredTools = _tools;
    } else {
      final query = _searchController.text.trim().toLowerCase();

      _filteredTools = _tools.where((tool) {
        return tool.title.toLowerCase().contains(query) ||
            tool.description.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: _pageBackground,

      // ----------------------------------------------------------------------
      // BODY
      // ----------------------------------------------------------------------

      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ==================================================================
            // HEADER
            // ==================================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------------------------------------------------------
                    // TITLE
                    // ----------------------------------------------------------

                    Text(
                      l10n.healthTools,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: _primaryTextColor,
                        fontFamily: 'serif',
                      ),
                    ),

                    const SizedBox(height: 7),

                    // ----------------------------------------------------------
                    // DESCRIPTION
                    // ----------------------------------------------------------

                    Text(
                      l10n.healthToolsDescription,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: _secondaryTextColorForTheme,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================================
                    // SEARCH BAR
                    // ==========================================================

                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _fieldBackground,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              _isDark ? 0.20 : 0.035,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                          fontSize: 15,
                          color: _primaryTextColor,
                        ),
                        cursorColor: _primaryColor,
                        decoration: InputDecoration(
                          hintText: l10n.searchHealthTools,
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: _isDark
                                ? const Color(0xFF8E8E8E)
                                : const Color(0xFF9CA3AF),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: _isDark
                                ? const Color(0xFFAAAAAA)
                                : const Color(0xFF7B8491),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: _isDark
                                        ? const Color(0xFFAAAAAA)
                                        : const Color(0xFF7B8491),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ----------------------------------------------------------
                    // SECTION TITLE
                    // ----------------------------------------------------------

                    Text(
                      l10n.tools,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _primaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 13),
                  ],
                ),
              ),
            ),

            // ==================================================================
            // TOOL GRID
            // ==================================================================

            if (_filteredTools.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  24,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tool = _filteredTools[index];

                      return _HealthToolCard(
                        tool: tool,
                        onTap: () => _openTool(tool),
                      );
                    },
                    childCount: _filteredTools.length,
                  ),

                  // ------------------------------------------------------------
                  // COMPACT TWO-COLUMN GRID
                  // ------------------------------------------------------------

                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.04,
                  ),
                ),
              )
            else

              // =================================================================
              // NO RESULTS
              // =================================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 45,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: _primaryColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.noToolsFound,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.tryAnotherHealthTool,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColorForTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),

      // ========================================================================
      // BOTTOM NAVIGATION
      // ========================================================================

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 2,
        onTap: (index) => _onBottomTap(context, index),
      ),
    );
  }
}

// ==============================================================================
// HEALTH TOOL CARD
// ==============================================================================

class _HealthToolCard extends StatelessWidget {
  final _HealthTool tool;
  final VoidCallback onTap;

  const _HealthToolCard({
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardBackground =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final Color borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final Color titleColor = isDark ? Colors.white : _textColor;

    final Color descriptionColor =
        isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

    return Material(
      color: cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: _primaryColor.withOpacity(0.08),
        highlightColor: _primaryColor.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            14,
            10,
            12,
            10,
          ),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isDark ? 0.20 : 0.035,
                ),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================================
              // ICON
              // =================================================================

              SizedBox(
                height: 54,
                width: double.infinity,
                child: Center(
                  child: Icon(
                    tool.icon,
                    size: 42,
                    color: tool.iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // =================================================================
              // TITLE
              // =================================================================

              Text(
                tool.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),

              const SizedBox(height: 5),

              // =================================================================
              // DESCRIPTION
              // =================================================================

              Expanded(
                child: Text(
                  tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: descriptionColor,
                  ),
                ),
              ),

              // =================================================================
              // ARROW
              // =================================================================

              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _primaryColor.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// HEALTH TOOL DATA
// ==============================================================================

class _HealthTool {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _HealthTool({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}
