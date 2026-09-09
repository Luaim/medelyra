import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/nav_bar.dart';
import 'emergency_guide_details_page.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allGuides = [];
  List<Map<String, dynamic>> filteredGuides = [];

  bool isLoading = true;
  String? errorMessage;

  // ---------------------------------------------------------------------------
  // THEME COLORS
  // ---------------------------------------------------------------------------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

  Color get _cardBackground => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _primaryTextColor =>
      _isDark ? Colors.white : const Color(0xFF24232A);

  Color get _searchHintColor =>
      _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6F6D75);

  Color get _searchIconColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF4D4B54);

  Color get _searchCloseColor =>
      _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF77757D);

  // ---------------------------------------------------------------------------
  // LOAD GUIDES
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuides() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      // Load the emergency guides directly from the bundled JSON file.
      final jsonString = await rootBundle.loadString(
        'assets/emergency_guides/emergency_guides.json',
      );

      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const FormatException(
          'Emergency guides JSON must contain a list.',
        );
      }

      final guides = decoded
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (guide) => Map<String, dynamic>.from(guide),
          )
          .toList();

      // Keep the exact order values from the JSON.
      guides.sort(
        (a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0),
      );

      if (!mounted) return;

      setState(() {
        allGuides = guides;
        filteredGuides = guides;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Could not load emergency guides.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  void _filterGuides(String query) {
    final searchText = query.trim().toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        filteredGuides = allGuides;
        return;
      }

      filteredGuides = allGuides.where((guide) {
        final title = guide['title']?.toString().toLowerCase() ?? '';

        final description =
            guide['shortDescription']?.toString().toLowerCase() ?? '';

        return title.contains(searchText) || description.contains(searchText);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // FALLBACK ICONS
  // ---------------------------------------------------------------------------

  IconData _fallbackIcon(String id) {
    switch (id) {
      case 'cpr':
        return Icons.health_and_safety_outlined;

      case 'choking':
        return Icons.accessibility_new_rounded;

      case 'severe_bleeding':
        return Icons.bloodtype_outlined;

      case 'burns':
        return Icons.local_fire_department_outlined;

      case 'fainting':
        return Icons.person_off_outlined;

      case 'fracture':
        return Icons.personal_injury_outlined;

      case 'suspected_poisoning':
        return Icons.warning_amber_rounded;

      case 'seizure':
        return Icons.accessibility_new_rounded;

      case 'severe_allergic_reaction':
        return Icons.warning_amber_rounded;

      default:
        return Icons.medical_services_outlined;
    }
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case 1:
        Navigator.pushReplacementNamed(context, '/reminder');
        break;

      case 2:
        Navigator.pushReplacementNamed(context, '/health-tools');
        break;

      case 3:
        // Already on Emergency Guide.
        break;

      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN GUIDE
  // ---------------------------------------------------------------------------

  void _openGuide(String guideId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyGuideDetailsPage(
          guideId: guideId,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 3,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.045,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),

              // ----------------------------------------------------------------
              // PAGE TITLE
              // ----------------------------------------------------------------

              Text(
                'Emergency guide',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------------
              // SEARCH BAR
              // ----------------------------------------------------------------

              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterGuides,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: _primaryTextColor,
                  ),
                  cursorColor: _isDark ? Colors.white : const Color(0xFF4D4B54),
                  decoration: InputDecoration(
                    hintText: 'Search emergency help...',
                    hintStyle: TextStyle(
                      color: _searchHintColor,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _searchIconColor,
                      size: 25,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: _searchCloseColor,
                            ),
                            onPressed: () {
                              searchController.clear();
                              _filterGuides('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------------
              // INFORMATION CARD
              // ----------------------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _isDark
                      ? const Color(0xFF302023)
                      : const Color(0xFFFDECEE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE96B6B),
                      child: Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Quick first-aid help for common emergencies',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              _isDark ? Colors.white : const Color(0xFF29272D),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ----------------------------------------------------------------
              // CONTENT
              // ----------------------------------------------------------------

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 70),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3D84A8),
                    ),
                  ),
                )
              else if (errorMessage != null)
                _ErrorCard(
                  message: errorMessage!,
                  onRetry: _loadGuides,
                )
              else if (filteredGuides.isEmpty)
                const _EmptySearchCard()
              else
                ListView.separated(
                  itemCount: filteredGuides.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final guide = filteredGuides[index];

                    final String id = guide['id']?.toString() ?? '';

                    final String title = guide['title']?.toString() ?? '';

                    final String description =
                        guide['shortDescription']?.toString() ?? '';

                    final String imagePath =
                        guide['thumbnail']?.toString() ?? '';

                    return _EmergencyGuideCard(
                      title: title,
                      description: description,
                      imagePath: imagePath,
                      fallbackIcon: _fallbackIcon(id),
                      onTap: () {
                        _openGuide(id);
                      },
                    );
                  },
                ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ERROR CARD
// =============================================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(
                color: const Color(0xFF333333),
              )
            : null,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFE96B6B),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF55525A),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY SEARCH CARD
// =============================================================================

class _EmptySearchCard extends StatelessWidget {
  const _EmptySearchCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(
                color: const Color(0xFF333333),
              )
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF8A8790),
          ),
          const SizedBox(height: 10),
          Text(
            'No emergency guide found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF444149),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try searching for a different emergency.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF77737A),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMERGENCY GUIDE CARD
// =============================================================================

class _EmergencyGuideCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _EmergencyGuideCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isDark
                ? Border.all(
                    color: const Color(0xFF333333),
                  )
                : null,
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------------------------------------------------------------
              // IMAGE
              // ---------------------------------------------------------------

              _GuideThumbnail(
                imagePath: imagePath,
                fallbackIcon: fallbackIcon,
              ),

              const SizedBox(width: 13),

              // ---------------------------------------------------------------
              // TITLE + DESCRIPTION
              // ---------------------------------------------------------------

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF29262D),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: isDark
                            ? const Color(0xFFBDBDBD)
                            : const Color(0xFF77737A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // ---------------------------------------------------------------
              // ARROW
              // ---------------------------------------------------------------

              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? const Color(0xFF9E9E9E) : const Color(0xFF8A8790),
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// THUMBNAIL
// =============================================================================

class _GuideThumbnail extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;

  const _GuideThumbnail({
    required this.imagePath,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fallbackColor =
        isDark ? const Color(0xFF6FA9C5) : const Color(0xFF3D84A8);

    return SizedBox(
      width: 88,
      height: 88,
      child: imagePath.isEmpty
          ? Container(
              alignment: Alignment.center,
              child: Icon(
                fallbackIcon,
                size: 34,
                color: fallbackColor,
              ),
            )
          : Image.asset(
              imagePath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) {
                return Container(
                  alignment: Alignment.center,
                  child: Icon(
                    fallbackIcon,
                    size: 34,
                    color: fallbackColor,
                  ),
                );
              },
            ),
    );
  }
}
