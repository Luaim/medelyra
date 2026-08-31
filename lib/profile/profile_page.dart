import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE FROM FIRESTORE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final document = await _firestore.collection('users').doc(user.uid).get();

      if (document.exists) {
        _profileData = document.data() ?? {};
      } else {
        _profileData = {};
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR LOADING PROFILE: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not load your profile. Please try again.',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
        break;

      case 1:
        Navigator.pushReplacementNamed(
          context,
          '/reminder',
        );
        break;

      case 2:
        Navigator.pushReplacementNamed(
          context,
          '/finder',
        );
        break;

      case 3:
        Navigator.pushReplacementNamed(
          context,
          '/sos',
        );
        break;

      case 4:
        break;
    }
  }

  // ============================================================
  // GET STRING VALUE
  // ============================================================

  String _getString(
    String field, {
    String fallback = 'Not provided',
  }) {
    final value = _profileData[field];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // GET EMERGENCY CONTACT
  // ============================================================

  String _getEmergencyContact() {
    final name = _getString(
      'emergencyContactName',
      fallback: '',
    );

    final phone = _getString(
      'emergencyContactPhone',
      fallback: '',
    );

    // Both are empty
    if (name.isEmpty && phone.isEmpty) {
      return 'Not provided';
    }

    // Only name exists
    if (name.isNotEmpty && phone.isEmpty) {
      return name;
    }

    // Only phone exists
    if (name.isEmpty && phone.isNotEmpty) {
      return phone;
    }

    // Both exist
    return '$name - $phone';
  }

  // ============================================================
  // FORMAT DATE OF BIRTH
  // ============================================================

  String _getDateOfBirth() {
    final value = _profileData['dateOfBirth'];

    if (value == null) {
      return 'Not provided';
    }

    try {
      if (value is Timestamp) {
        final date = value.toDate();

        return '${date.day} '
            '${_monthName(date.month)} '
            '${date.year}';
      }

      if (value is DateTime) {
        return '${value.day} '
            '${_monthName(value.month)} '
            '${value.year}';
      }
    } catch (e) {
      debugPrint(
        'DATE FORMAT ERROR: $e',
      );
    }

    return 'Not provided';
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // FORMAT ALLERGIES
  // ============================================================

  String _getAllergies() {
    final value = _profileData['allergies'];

    if (value == null || value is! List || value.isEmpty) {
      return 'No known allergies';
    }

    final allergies = value
        .map(
          (item) => item.toString().trim(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();

    if (allergies.isEmpty) {
      return 'No known allergies';
    }

    return allergies.join(', ');
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not log out. Please try again.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final screenWidth = size.width;
    final screenHeight = size.height;

    final smallScreen = screenHeight < 700;

    final currentUser = _auth.currentUser;

    // ------------------------------------------------------------
    // REAL USER DATA
    // ------------------------------------------------------------

    final name = _getString(
      'name',
      fallback: currentUser?.displayName ?? 'MedMinder User',
    );

    final email = _getString(
      'email',
      fallback: currentUser?.email ?? 'Not provided',
    );

    final phone = _getString(
      'phone',
    );

    final gender = _getString(
      'gender',
    );

    final bloodGroup = _getString(
      'bloodGroup',
    );

    final emergencyContact = _getEmergencyContact();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 4,
        onTap: (index) => _onBottomTap(
          context,
          index,
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3D84A8),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.045,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 430,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: smallScreen ? 8 : 12,
                        ),

                        // ==================================================
                        // PAGE TITLE
                        // ==================================================

                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                        ),

                        SizedBox(
                          height: smallScreen ? 18 : 22,
                        ),

                        // ==================================================
                        // HEADER
                        // ==================================================

                        _buildHeaderCard(
                          name,
                        ),

                        SizedBox(
                          height: smallScreen ? 18 : 22,
                        ),

                        // ==================================================
                        // PERSONAL INFORMATION
                        // ==================================================

                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildInfoCard(
                          children: [
                            ProfileInfoTile(
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              value: name,
                            ),
                            ProfileInfoTile(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: email,
                            ),
                            ProfileInfoTile(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: phone,
                            ),
                            ProfileInfoTile(
                              icon: Icons.calendar_month_outlined,
                              label: 'Date of Birth',
                              value: _getDateOfBirth(),
                            ),
                            ProfileInfoTile(
                              icon: Icons.wc_outlined,
                              label: 'Gender',
                              value: gender,
                            ),
                          ],
                        ),

                        SizedBox(
                          height: smallScreen ? 18 : 22,
                        ),

                        // ==================================================
                        // MEDICAL INFORMATION
                        // ==================================================

                        const Text(
                          'Medical Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildInfoCard(
                          children: [
                            ProfileInfoTile(
                              icon: Icons.bloodtype_outlined,
                              label: 'Blood Group',
                              value: bloodGroup,
                            ),
                            ProfileInfoTile(
                              icon: Icons.contact_emergency_outlined,
                              label: 'Emergency Contact',
                              value: emergencyContact,
                            ),
                            ProfileInfoTile(
                              icon: Icons.medical_information_outlined,
                              label: 'Allergies',
                              value: _getAllergies(),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: smallScreen ? 18 : 22,
                        ),

                        // ==================================================
                        // QUICK ACTIONS
                        // ==================================================

                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // Settings
                        _ActionTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'Manage account preferences',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/settings',
                            );
                          },
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // Notifications
                        _ActionTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Control reminder and app alerts',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/notification_settings',
                            );
                          },
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // ==================================================
                        // LOGOUT
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout_rounded,
                            ),
                            label: const Text(
                              'Logout',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF4B1B1,
                              ),
                              foregroundColor: const Color(
                                0xFF6E1E1E,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  18,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard(
    String name,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9ED8E8),
            Color(0xFFDDF4F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ==========================================================
          // GENERIC USER ICON
          // ==========================================================

          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 48,
              color: Color(0xFF4D4D4D),
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          // ==========================================================
          // USER NAME
          // ==========================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                const Text(
                  'MedMinder User',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4D4D4D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: Color(0xFF2F7B95),
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Health profile active',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2F7B95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ================================================================
// PROFILE INFO TILE
// ================================================================

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6FA),
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3D84A8),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF777777),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(
          top: 3,
        ),
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ACTION TILE
// ================================================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: const Color(0xFFE3E3E3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.03,
                ),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FA),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3D84A8),
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF777777),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF9A9A9A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
