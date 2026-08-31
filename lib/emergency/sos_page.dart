import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ============================================================================
  // LOAD EMERGENCY GUIDES FROM FIRESTORE
  // ============================================================================

  Future<void> _loadGuides() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('emergency_guides')
          .orderBy('order')
          .get();

      final guides = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'thumbnail': data['thumbnail'] ?? '',
          'shortDescription': data['shortDescription'] ?? '',
          'order': data['order'] ?? 0,
        };
      }).toList();

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
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================================
  // SEARCH
  // ============================================================================

  void _filterGuides(String query) {
    final searchText = query.trim().toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        filteredGuides = allGuides;
      } else {
        filteredGuides = allGuides.where((guide) {
          final title = guide['title'].toString().toLowerCase();

          final description =
              guide['shortDescription'].toString().toLowerCase();

          return title.contains(searchText) || description.contains(searchText);
        }).toList();
      }
    });
  }

  // ============================================================================
  // FALLBACK IMAGE
  // ============================================================================

  String _fallbackImage(String id) {
    switch (id) {
      case 'cpr':
        return 'assets/cpr.png';

      case 'choking':
        return 'assets/choking.png';

      case 'severe_bleeding':
        return 'assets/bleeding.png';

      default:
        return '';
    }
  }

  // ============================================================================
  // FALLBACK ICON
  // ============================================================================

  IconData _fallbackIcon(String id) {
    switch (id) {
      case 'cpr':
        return Icons.health_and_safety_outlined;

      case 'choking':
        return Icons.accessibility_new_rounded;

      case 'severe_bleeding':
        return Icons.bloodtype_outlined;

      default:
        return Icons.medical_services_outlined;
    }
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case 1:
        Navigator.pushReplacementNamed(context, '/reminder');
        break;

      case 2:
        Navigator.pushReplacementNamed(context, '/finder');
        break;

      case 3:
        Navigator.pushReplacementNamed(context, '/sos');
        break;

      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  // ============================================================================
  // OPEN GUIDE DETAILS
  // ============================================================================

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

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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

              // ==============================================================
              // PAGE TITLE
              // ==============================================================

              const Text(
                'Emergency guide',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF24232A),
                ),
              ),

              const SizedBox(height: 16),

              // ==============================================================
              // SEARCH BAR
              // ==============================================================

              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
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
                  decoration: InputDecoration(
                    hintText: 'Search emergency help...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6F6D75),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF4D4B54),
                      size: 25,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF77757D),
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

              // ==============================================================
              // INFORMATION BOX
              // ==============================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE96B6B),
                      child: Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Quick first-aid help for common emergencies',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF29272D),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==============================================================
              // CONTENT
              // ==============================================================

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 70),
                  child: Center(
                    child: CircularProgressIndicator(),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final guide = filteredGuides[index];

                    final String id = guide['id'].toString();

                    final String firestoreImage = guide['thumbnail'].toString();

                    final String fallbackImage = _fallbackImage(id);

                    final String imagePath = firestoreImage.isNotEmpty
                        ? firestoreImage
                        : fallbackImage;

                    return _EmergencyGuideCard(
                      title: guide['title'].toString(),
                      description: guide['shortDescription'].toString(),
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

// ============================================================================
// ERROR CARD
// ============================================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load emergency guides.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D84A8),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY SEARCH CARD
// ============================================================================

class _EmptySearchCard extends StatelessWidget {
  const _EmptySearchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No emergency guide found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try searching for another emergency.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMERGENCY GUIDE CARD
// ============================================================================

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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF3D84A8).withOpacity(0.08),
        highlightColor: const Color(0xFF3D84A8).withOpacity(0.035),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ==============================================================
              // THUMBNAIL
              // ==============================================================

              _GuideThumbnail(
                imagePath: imagePath,
                fallbackIcon: fallbackIcon,
              ),

              const SizedBox(width: 14),

              // ==============================================================
              // TEXT
              // ==============================================================

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF28262D),
                        height: 1.18,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,

                        // Keep the card clean.
                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF737078),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // ==============================================================
              // CHEVRON
              // ==============================================================

              const Icon(
                Icons.chevron_right_rounded,
                size: 27,
                color: Color(0xFF8A8990),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GUIDE THUMBNAIL
// ============================================================================

class _GuideThumbnail extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;

  const _GuideThumbnail({
    required this.imagePath,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isEmpty
          ? Center(
              child: Icon(
                fallbackIcon,
                size: 34,
                color: const Color(0xFF3D84A8),
              ),
            )
          : imagePath.startsWith('http://') || imagePath.startsWith('https://')
              ? Image.network(
                  imagePath,

                  // IMPORTANT:
                  // Do NOT crop the portrait image.
                  fit: BoxFit.contain,

                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },

                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Icon(
                        fallbackIcon,
                        size: 34,
                        color: const Color(0xFF3D84A8),
                      ),
                    );
                  },
                )
              : Image.asset(
                  imagePath,

                  // IMPORTANT:
                  // Do NOT crop the portrait image.
                  fit: BoxFit.contain,

                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Icon(
                        fallbackIcon,
                        size: 34,
                        color: const Color(0xFF3D84A8),
                      ),
                    );
                  },
                ),
    );
  }
}
