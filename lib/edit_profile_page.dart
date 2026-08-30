import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController emergencyNameController = TextEditingController();

  final TextEditingController emergencyPhoneController =
      TextEditingController();

  final TextEditingController allergyController = TextEditingController();

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String gender = 'Male';
  String bloodGroup = 'O+';

  DateTime selectedDate = DateTime(2002, 5, 12);

  List<String> allergies = [];

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  bool isSaving = false;

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF3D84A8);
  static const Color primaryLight = Color(0xFFEAF6FA);

  static const Color background = Color(0xFFF7F7F9);
  static const Color textDark = Color(0xFF25252A);
  static const Color textMedium = Color(0xFF66666D);
  static const Color textLight = Color(0xFF92929A);
  static const Color border = Color(0xFFE9E9ED);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        // --------------------------------------------------------
        // PERSONAL INFORMATION
        // --------------------------------------------------------

        nameController.text =
            data['name']?.toString() ?? user.displayName ?? '';

        emailController.text = data['email']?.toString() ?? user.email ?? '';

        phoneController.text = data['phone']?.toString() ?? '';

        // --------------------------------------------------------
        // GENDER
        // --------------------------------------------------------

        final savedGender = data['gender']?.toString();

        if (savedGender == 'Male' || savedGender == 'Female') {
          gender = savedGender!;
        }

        // --------------------------------------------------------
        // BLOOD GROUP
        // --------------------------------------------------------

        final savedBloodGroup = data['bloodGroup']?.toString();

        const allowedBloodGroups = [
          'A+',
          'B+',
          'AB+',
          'O+',
        ];

        if (savedBloodGroup != null &&
            allowedBloodGroups.contains(savedBloodGroup)) {
          bloodGroup = savedBloodGroup;
        }

        // --------------------------------------------------------
        // DATE OF BIRTH
        // --------------------------------------------------------

        if (data['dateOfBirth'] is Timestamp) {
          selectedDate = (data['dateOfBirth'] as Timestamp).toDate();
        }

        // --------------------------------------------------------
        // ALLERGIES
        // --------------------------------------------------------

        if (data['allergies'] is List) {
          allergies = List<String>.from(
            (data['allergies'] as List).map(
              (item) => item.toString(),
            ),
          );
        }

        // --------------------------------------------------------
        // EMERGENCY CONTACT
        // --------------------------------------------------------

        emergencyNameController.text =
            data['emergencyContactName']?.toString() ?? '';

        emergencyPhoneController.text =
            data['emergencyContactPhone']?.toString() ?? '';
      } else {
        // --------------------------------------------------------
        // NO FIRESTORE PROFILE YET
        // --------------------------------------------------------

        nameController.text = user.displayName ?? '';
        emailController.text = user.email ?? '';
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR LOADING PROFILE: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
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
  // PICK DATE
  // ============================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ============================================================
  // ADD ALLERGY
  // ============================================================

  void _addAllergy() {
    final allergy = allergyController.text.trim();

    if (allergy.isEmpty) {
      return;
    }

    if (allergies.contains(allergy)) {
      allergyController.clear();
      return;
    }

    setState(() {
      allergies.add(allergy);
      allergyController.clear();
    });
  }

  // ============================================================
  // REMOVE ALLERGY
  // ============================================================

  void _removeAllergy(String item) {
    setState(() {
      allergies.remove(item);
    });
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (isSaving) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are not signed in.',
          ),
        ),
      );
      return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    final emergencyName = emergencyNameController.text.trim();
    final emergencyPhone = emergencyPhoneController.text.trim();

    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your full name.',
          ),
        ),
      );
      return;
    }

    if (phone.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone number can contain numbers only.',
          ),
        ),
      );
      return;
    }

    if (emergencyPhone.isNotEmpty &&
        !RegExp(r'^[0-9]+$').hasMatch(emergencyPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Emergency phone number can contain numbers only.',
          ),
        ),
      );
      return;
    }

    // ------------------------------------------------------------
    // START SAVING
    // ------------------------------------------------------------

    setState(() {
      isSaving = true;
    });

    try {
      // ----------------------------------------------------------
      // SAVE TO FIRESTORE
      // ----------------------------------------------------------

      await _firestore.collection('users').doc(user.uid).set(
        {
          'name': name,
          'email': emailController.text.trim(),
          'phone': phone,
          'dateOfBirth': Timestamp.fromDate(selectedDate),
          'gender': gender,
          'bloodGroup': bloodGroup,
          'allergies': allergies,
          'emergencyContactName': emergencyName,
          'emergencyContactPhone': emergencyPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ----------------------------------------------------------
      // UPDATE FIREBASE AUTH DISPLAY NAME
      // ----------------------------------------------------------

      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully!',
          ),
        ),
      );

      // ----------------------------------------------------------
      // RETURN TO PROFILE PAGE
      // ----------------------------------------------------------

      Navigator.pop(context);
    } catch (e) {
      debugPrint('ERROR SAVING PROFILE: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your profile. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formattedDate() {
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

    return '${selectedDate.day} ${months[selectedDate.month - 1]} '
        '${selectedDate.year}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    emergencyNameController.dispose();
    emergencyPhoneController.dispose();

    allergyController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // INTRO HEADER
                        // ==================================================

                        _buildIntroHeader(),

                        const SizedBox(height: 24),

                        // ==================================================
                        // PERSONAL INFORMATION
                        // ==================================================

                        _sectionHeader(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Information',
                          subtitle: 'Keep your basic information up to date.',
                        ),

                        const SizedBox(height: 12),

                        _buildSectionCard(
                          children: [
                            _modernInput(
                              controller: nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _modernInput(
                              controller: emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              enabled: false,
                              helperText: 'Email cannot be changed here.',
                            ),
                            const SizedBox(height: 14),
                            _modernInput(
                              controller: phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _buildDateField(),
                            const SizedBox(height: 14),
                            _buildDropdownField(
                              label: 'Gender',
                              icon: Icons.wc_outlined,
                              value: gender,
                              items: const [
                                'Male',
                                'Female',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  gender = value;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ==================================================
                        // MEDICAL INFORMATION
                        // ==================================================

                        _sectionHeader(
                          icon: Icons.favorite_outline_rounded,
                          title: 'Medical Information',
                          subtitle:
                              'Important information for your health profile.',
                        ),

                        const SizedBox(height: 12),

                        _buildSectionCard(
                          children: [
                            _buildDropdownField(
                              label: 'Blood Group',
                              icon: Icons.bloodtype_outlined,
                              value: bloodGroup,
                              items: const [
                                'A+',
                                'B+',
                                'AB+',
                                'O+',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  bloodGroup = value;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Allergies',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add any medicines or substances you are allergic to.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textLight,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (allergies.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allergies.map((item) {
                                  return _buildAllergyChip(item);
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: _modernInput(
                                    controller: allergyController,
                                    label: 'Add Allergy',
                                    icon: Icons.add_rounded,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _addAllergy(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildAddButton(),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ==================================================
                        // EMERGENCY CONTACT
                        // ==================================================

                        _sectionHeader(
                          icon: Icons.emergency_outlined,
                          title: 'Emergency Contact',
                          subtitle:
                              'Someone to contact in case of an emergency.',
                        ),

                        const SizedBox(height: 12),

                        _buildSectionCard(
                          children: [
                            _modernInput(
                              controller: emergencyNameController,
                              label: 'Emergency Contact Name',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _modernInput(
                              controller: emergencyPhoneController,
                              label: 'Emergency Contact Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ==================================================
                        // PRIVACY NOTE
                        // ==================================================

                        _buildPrivacyNote(),

                        const SizedBox(height: 20),

                        // ==================================================
                        // SAVE BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF9BBFCC),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: 21,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Center(
                          child: Text(
                            'Your changes will be saved securely.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
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
  // INTRO HEADER
  // ============================================================

  Widget _buildIntroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF6FA),
            Color(0xFFF4FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCEFF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.manage_accounts_outlined,
              color: primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Update your information to keep your MedMinder profile accurate.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ============================================================
  // MODERN INPUT
  // ============================================================

  Widget _modernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    String? helperText,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: enabled ? textDark : textLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: textMedium,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          size: 21,
          color: enabled ? primary : textLight,
        ),
        helperText: helperText,
        helperStyle: const TextStyle(
          fontSize: 11,
          color: textLight,
        ),
        filled: true,
        fillColor: enabled ? const Color(0xFFFAFAFB) : const Color(0xFFF2F2F4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _buildDateField() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 12,
                        color: textLight,
                      ),
                    ),
                    SizedBox(height: 3),
                  ],
                ),
              ),
              Text(
                _formattedDate(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: textLight,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN FIELD
  // ============================================================

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                borderRadius: BorderRadius.circular(15),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primary,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
                selectedItemBuilder: (context) {
                  return items.map((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALLERGY CHIP
  // ============================================================

  Widget _buildAllergyChip(String item) {
    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 6,
        top: 7,
        bottom: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDCEFF4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: primary,
          ),
          const SizedBox(width: 6),
          Text(
            item,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: () => _removeAllergy(item),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 17,
                color: textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: _addAllergy,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 25,
        ),
      ),
    );
  }

  // ============================================================
  // PRIVACY NOTE
  // ============================================================

  Widget _buildPrivacyNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCECF1),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your profile information is securely stored and used to personalize your MedMinder experience.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
