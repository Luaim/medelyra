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

        // ----------------------------
        // PERSONAL INFORMATION
        // ----------------------------

        nameController.text =
            data['name']?.toString() ?? user.displayName ?? '';

        emailController.text = data['email']?.toString() ?? user.email ?? '';

        phoneController.text = data['phone']?.toString() ?? '';

        // ----------------------------
        // GENDER
        // ----------------------------

        final savedGender = data['gender']?.toString();

        if (savedGender == 'Male' || savedGender == 'Female') {
          gender = savedGender!;
        }

        // ----------------------------
        // BLOOD GROUP
        // ----------------------------

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

        // ----------------------------
        // DATE OF BIRTH
        // ----------------------------

        if (data['dateOfBirth'] is Timestamp) {
          selectedDate = (data['dateOfBirth'] as Timestamp).toDate();
        }

        // ----------------------------
        // ALLERGIES
        // ----------------------------

        if (data['allergies'] is List) {
          allergies = List<String>.from(
            (data['allergies'] as List).map(
              (item) => item.toString(),
            ),
          );
        }

        // ----------------------------
        // EMERGENCY CONTACT
        // ----------------------------

        emergencyNameController.text =
            data['emergencyContactName']?.toString() ?? '';

        emergencyPhoneController.text =
            data['emergencyContactPhone']?.toString() ?? '';
      } else {
        // --------------------------------------------------------
        // No Firestore profile yet.
        // Use Firebase Authentication information.
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
              primary: Color(0xFF3D84A8),
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
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3D84A8),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),

                  // =================================================
                  // PERSONAL INFORMATION
                  // =================================================

                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Full Name
                  _input(
                    nameController,
                    'Full Name',
                  ),

                  // Email
                  _input(
                    emailController,
                    'Email',
                    enabled: false,
                  ),

                  // Phone Number
                  _input(
                    phoneController,
                    'Phone Number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),

                  // =================================================
                  // DATE OF BIRTH
                  // =================================================

                  GestureDetector(
                    onTap: _pickDate,
                    child: _box(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/'
                            '${selectedDate.month}/'
                            '${selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: Color(0xFF3D84A8),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // GENDER
                  // =================================================

                  const Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _dropdown(
                    ['Male', 'Female'],
                    gender,
                    (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // MEDICAL INFORMATION
                  // =================================================

                  const Text(
                    'Medical Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Blood Group',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _dropdown(
                    [
                      'A+',
                      'B+',
                      'AB+',
                      'O+',
                    ],
                    bloodGroup,
                    (value) {
                      setState(() {
                        bloodGroup = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // ALLERGIES
                  // =================================================

                  const Text(
                    'Allergies',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (allergies.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergies.map((item) {
                        return Chip(
                          label: Text(item),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                          ),
                          onDeleted: () => _removeAllergy(item),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _box(
                          child: TextField(
                            controller: allergyController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addAllergy(),
                            decoration: const InputDecoration(
                              hintText: 'Add allergy',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: ElevatedButton(
                          onPressed: _addAllergy,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF3D84A8,
                            ),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // EMERGENCY CONTACT
                  // =================================================

                  const Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Someone to contact in case of an emergency.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Emergency Contact Name
                  _input(
                    emergencyNameController,
                    'Emergency Contact Name',
                  ),

                  // Emergency Contact Phone
                  _input(
                    emergencyPhoneController,
                    'Emergency Contact Phone',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // SAVE BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D84A8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF9BBFCC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: _box(
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOX STYLE
  // ============================================================

  Widget _box({
    required Widget child,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown(
    List<String> items,
    String value,
    Function(String) onChanged,
  ) {
    return _box(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF3D84A8),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
