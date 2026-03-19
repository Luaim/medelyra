import 'package:flutter/material.dart';
import 'nav_bar.dart';

class FinderPage extends StatefulWidget {
  const FinderPage({super.key});

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> places = [
    {
      'name': 'Prince Klinik Aziz',
      'type': 'Health Screening Medical Clinic',
      'distance': '1.2 km away',
      'rating': '4.7',
      'isOpen': true,
      'openText': 'Open now · Closes 10:00 PM',
      'address': 'Jalan 18, Pusat Perdagangan Desa Jaya, Kuala Lumpur',
      'icon': Icons.local_hospital_outlined,
    },
    {
      'name': 'Kajang Hospital',
      'type': 'General Hospital',
      'distance': '2.4 km away',
      'rating': '4.2',
      'isOpen': true,
      'openText': 'Open 24 hours',
      'address': 'Jalan Semenyih, Kajang',
      'icon': Icons.apartment_rounded,
    },
    {
      'name': 'Putrajaya Hospital',
      'type': 'General Hospital',
      'distance': '4.8 km away',
      'rating': '4.3',
      'isOpen': true,
      'openText': 'Open 24 hours',
      'address': 'Presint 7, Putrajaya',
      'icon': Icons.local_hospital_rounded,
    },
    {
      'name': 'CarePlus Pharmacy',
      'type': 'Pharmacy',
      'distance': '0.8 km away',
      'rating': '4.8',
      'isOpen': true,
      'openText': 'Open now · Closes 11:00 PM',
      'address': 'Block C, City Square',
      'icon': Icons.medication_outlined,
    },
  ];

  List<Map<String, dynamic>> filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    filteredPlaces = places;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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

  void _filterPlaces(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredPlaces = places;
      } else {
        filteredPlaces = places.where((place) {
          final name = place['name'].toString().toLowerCase();
          final type = place['type'].toString().toLowerCase();
          final address = place['address'].toString().toLowerCase();
          final q = query.toLowerCase();

          return name.contains(q) || type.contains(q) || address.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final smallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 2,
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
                  Row(
                    children: [
                      _topIconButton(Icons.tune_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSearchBar(),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 18 : 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD8F2F2),
                          Color(0xFFEFF9F9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF67C0D7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nearby clinics & pharmacies',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Find medical places close to your current location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: smallScreen ? 16 : 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available places',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        '${filteredPlaces.length} found',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 14 : 18),
                  ListView.separated(
                    itemCount: filteredPlaces.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      return _PlaceCard(
                        name: place['name'],
                        type: place['type'],
                        distance: place['distance'],
                        rating: place['rating'],
                        isOpen: place['isOpen'],
                        openText: place['openText'],
                        address: place['address'],
                        icon: place['icon'],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topIconButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD7E7ED),
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF3D84A8),
        size: 26,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD0D0D0),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: _filterPlaces,
        decoration: InputDecoration(
          hintText: 'Search hospital, clinic, pharmacy',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF777777),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String name;
  final String type;
  final String distance;
  final String rating;
  final bool isOpen;
  final String openText;
  final String address;
  final IconData icon;

  const _PlaceCard({
    required this.name,
    required this.type,
    required this.distance,
    required this.rating,
    required this.isOpen,
    required this.openText,
    required this.address,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F3F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF98C9C5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3D84A8),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5E5E5E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _infoChip(
                          Icons.star_rounded,
                          rating,
                          const Color(0xFFFFB800),
                        ),
                        _infoChip(
                          Icons.near_me_rounded,
                          distance,
                          const Color(0xFF3D84A8),
                        ),
                        _statusChip(isOpen, openText),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.language_rounded,
                  text: 'Website',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.directions_rounded,
                  text: 'Directions',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isOpen, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE6F7EA) : const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isOpen ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF67C0D7),
          foregroundColor: const Color(0xFF17333B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF2A6E7E),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
