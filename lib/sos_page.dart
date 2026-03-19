import 'package:flutter/material.dart';
import 'nav_bar.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final smallScreen = screenHeight < 700;

    final guides = [
      {
        'title': 'CPR (Cardiopulmonary Resuscitation)',
        'image': 'assets/cpr.png',
        'icon': Icons.health_and_safety_outlined,
      },
      {
        'title': 'Someone Choking',
        'image': 'assets/choking.png',
        'icon': Icons.accessibility_new_rounded,
      },
      {
        'title': 'Someone Bleeding',
        'image': 'assets/bleeding.png',
        'icon': Icons.bloodtype_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 3,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.045,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: smallScreen ? 8 : 12),
                  const Text(
                    'Emergency guide',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 16 : 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFEFEF),
                          Color(0xFFF9FDFD),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFE96B6B),
                          child: Icon(
                            Icons.emergency_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Quick first-aid help for common emergencies',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.35,
                              color: Color(0xFF555555),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 22),
                  ListView.separated(
                    itemCount: guides.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final guide = guides[index];
                      return _EmergencyGuideCard(
                        title: guide['title'] as String,
                        imagePath: guide['image'] as String,
                        fallbackIcon: guide['icon'] as IconData,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${guide['title']} guide coming soon'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: smallScreen ? 14 : 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final isLongTitle = title.length > 24;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFCFEFED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7FAEAA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon,
                  size: 42,
                  color: const Color(0xFF3D84A8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: isLongTitle ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF67C0D7),
                        foregroundColor: const Color(0xFF17333B),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                            color: Color(0xFF2A6E7E),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'See how',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
