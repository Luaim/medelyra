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
      'address': 'Jalan 18, Desa Jaya, Kuala Lumpur',
      'icon': Icons.local_hospital,
    },
    {
      'name': 'Kajang Hospital',
      'type': 'General Hospital',
      'distance': '2.4 km away',
      'rating': '4.2',
      'isOpen': true,
      'openText': 'Open 24 hours',
      'address': 'Jalan Semenyih, Kajang',
      'icon': Icons.apartment,
    },
  ];

  List<Map<String, dynamic>> filteredPlaces = [];

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
  void initState() {
    super.initState();
    filteredPlaces = places;
  }

  void _filterPlaces(String query) {
    setState(() {
      filteredPlaces = query.isEmpty
          ? places
          : places.where((p) {
              final q = query.toLowerCase();
              return p['name'].toLowerCase().contains(q) ||
                  p['type'].toLowerCase().contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 2,
        onTap: (i) => _onBottomTap(context, i),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: Column(
            children: [
              const SizedBox(height: 12),

              /// SEARCH
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterPlaces,
                  decoration: const InputDecoration(
                    hintText: 'Search hospital, clinic...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              ///  HEADER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF3D84A8)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nearby clinics & pharmacies',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available places',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text('${filteredPlaces.length} found'),
                ],
              ),

              const SizedBox(height: 12),

              /// LIST
              Expanded(
                child: ListView.builder(
                  itemCount: filteredPlaces.length,
                  itemBuilder: (context, index) {
                    final place = filteredPlaces[index];
                    return _PlaceCard(place: place);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  place['icon'],
                  color: const Color(0xFF3D84A8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place['type'],
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// INFO
          Row(
            children: [
              _chip('⭐ ${place['rating']}'),
              const SizedBox(width: 8),
              _chip(place['distance']),
            ],
          ),

          const SizedBox(height: 8),

          /// ADDRESS
          Text(
            place['address'],
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 14),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: _outlineBtn(
                  text: 'Website',
                  icon: Icons.language,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _mainBtn(
                  text: 'Directions',
                  icon: Icons.directions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// CHIP
  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  /// PRIMARY BUTTON
  Widget _mainBtn({required String text, required IconData icon}) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D84A8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// OUTLINE BUTTON
  Widget _outlineBtn({required String text, required IconData icon}) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3D84A8),
          side: const BorderSide(color: Color(0xFF3D84A8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
