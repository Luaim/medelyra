import 'package:flutter/material.dart';

import '../widgets/nav_bar.dart';

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
  // HEALTH TOOLS
  // --------------------------------------------------------------------------

  final List<_HealthTool> _tools = const [
    _HealthTool(
      title: 'BMI Calculator',
      description: 'Check your body mass index',
      icon: Icons.monitor_weight_outlined,
      iconColor: Color(0xFF3D84A8),
    ),
    _HealthTool(
      title: 'Age Calculator',
      description: 'Find your exact age',
      icon: Icons.cake_outlined,
      iconColor: Color(0xFFD18B3C),
    ),
    _HealthTool(
      title: 'Blood Pressure',
      description: 'Understand your blood pressure',
      icon: Icons.favorite_outline,
      iconColor: Color(0xFFD95C68),
    ),
    _HealthTool(
      title: 'Heart Rate',
      description: 'Check your heart rate',
      icon: Icons.monitor_heart_outlined,
      iconColor: Color(0xFFC95C68),
    ),
    _HealthTool(
      title: 'Medical Unit Converter',
      description: 'Convert common medical units',
      icon: Icons.swap_horiz_rounded,
      iconColor: Color(0xFF7167B7),
    ),
    _HealthTool(
      title: 'Medication Schedule Helper',
      description: 'Organize your medication schedule',
      icon: Icons.medication_outlined,
      iconColor: Color(0xFF4E9A78),
    ),
  ];

  late List<_HealthTool> _filteredTools;

  // --------------------------------------------------------------------------
  // INIT
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _filteredTools = _tools;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tool.title} will be available soon.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
    return Scaffold(
      backgroundColor: _backgroundColor,

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

                    const Text(
                      'Health Tools',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        fontFamily: 'serif',
                      ),
                    ),

                    const SizedBox(height: 7),

                    // ----------------------------------------------------------
                    // DESCRIPTION
                    // ----------------------------------------------------------

                    const Text(
                      'Simple tools to help you understand '
                      'and manage your health.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: _secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================================
                    // SEARCH BAR
                    // ==========================================================

                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFE3EAF5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search health tools',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9CA3AF),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: Color(0xFF7B8491),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: Color(0xFF7B8491),
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

                    const Text(
                      'Tools',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
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

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 45,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: _primaryColor,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No tools found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Try searching for another health tool.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColor,
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
    return Material(
      color: Colors.white,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE3EAF5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
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
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
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
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: _secondaryTextColor,
                  ),
                ),
              ),

              // =================================================================
              // ARROW
              // =================================================================

              Align(
                alignment: Alignment.bottomRight,
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
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _HealthTool({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}
