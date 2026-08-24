import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'nav_bar.dart';
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

  // ============================================================
  // LOAD EMERGENCY GUIDES FROM FIRESTORE
  // ============================================================

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

  // ============================================================
  // SEARCH
  // ============================================================

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

  // ============================================================
  // FALLBACK IMAGE
  // ============================================================

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

  // ============================================================
  // FALLBACK ICON
  // ============================================================

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

  // ============================================================
  // NAVIGATION
  // ============================================================

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

  // ============================================================
  // OPEN GUIDE DETAILS
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

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
            horizontal: width * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Emergency guide',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // SEARCH BAR
              // ==================================================

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterGuides,
                  decoration: const InputDecoration(
                    hintText: 'Search emergency help...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // INFO BOX
              // ==================================================

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE96B6B),
                      child: Icon(
                        Icons.emergency,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quick first-aid help for common emergencies',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CONTENT
              // ==================================================

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
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
                      imagePath: imagePath,
                      fallbackIcon: _fallbackIcon(id),
                      onTap: () {
                        _openGuide(id);
                      },
                    );
                  },
                ),

              const SizedBox(height: 20),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load emergency guides.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Try Again'),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
  final String imagePath;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _EmergencyGuideCard({
    required this.title,
    required this.imagePath,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // ==================================================
          // IMAGE
          // ==================================================

          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          fallbackIcon,
                          color: const Color(0xFF3D84A8),
                        );
                      },
                    )
                  : Icon(
                      fallbackIcon,
                      color: const Color(0xFF3D84A8),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================
          // TEXT + BUTTON
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D84A8),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'See how',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
