import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
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

  // IMPORTANT:
  // These values remain in English because they are stored in
  // Firestore. Only their displayed labels are localized.
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
  // LOCALIZATION
  // ============================================================

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

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
  // DARK MODE COLORS
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground => _isDark ? const Color(0xFF121212) : background;

  Color get _cardBackground => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFB);

  Color get _disabledFieldBackground =>
      _isDark ? const Color(0xFF202020) : const Color(0xFFF2F2F4);

  Color get _borderColor => _isDark ? const Color(0xFF3A3A3A) : border;

  Color get _primaryTextColor => _isDark ? Colors.white : textDark;

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : textMedium;

  Color get _lightTextColor => _isDark ? const Color(0xFF9E9E9E) : textLight;

  Color get _introStartColor =>
      _isDark ? const Color(0xFF1D3038) : const Color(0xFFEAF6FA);

  Color get _introEndColor =>
      _isDark ? const Color(0xFF202B30) : const Color(0xFFF4FAFC);

  Color get _introBorderColor =>
      _isDark ? const Color(0xFF31454D) : const Color(0xFFDCEFF4);

  Color get _iconBackground => _isDark ? const Color(0xFF243943) : Colors.white;

  Color get _sectionIconBackground =>
      _isDark ? const Color(0xFF243943) : primaryLight;

  Color get _allergyBackground =>
      _isDark ? const Color(0xFF20353A) : const Color(0xFFF0F8FA);

  Color get _allergyBorder =>
      _isDark ? const Color(0xFF315058) : const Color(0xFFDCEFF4);

  Color get _privacyBackground =>
      _isDark ? const Color(0xFF1D3035) : const Color(0xFFF1F7F9);

  Color get _privacyBorder =>
      _isDark ? const Color(0xFF304B52) : const Color(0xFFDCECF1);

  Color get _dateIconBackground =>
      _isDark ? const Color(0xFF243943) : primaryLight;

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
          SnackBar(
            content: Text(
              _l10n.couldNotLoadYourProfile,
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: primary,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
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
        SnackBar(
          content: Text(
            _l10n.notSignedIn,
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
        SnackBar(
          content: Text(
            _l10n.pleaseEnterFullName,
          ),
        ),
      );
      return;
    }

    if (phone.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.phoneNumbersOnly,
          ),
        ),
      );
      return;
    }

    if (emergencyPhone.isNotEmpty &&
        !RegExp(r'^[0-9]+$').hasMatch(
          emergencyPhone,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.emergencyPhoneNumbersOnly,
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
        SnackBar(
          content: Text(
            _l10n.profileUpdatedSuccessfully,
          ),
        ),
      );

      // ----------------------------------------------------------
      // RETURN TO PROFILE PAGE
      // ----------------------------------------------------------

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'ERROR SAVING PROFILE: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotSaveProfile,
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
    return DateFormat(
      'd MMMM yyyy',
      _l10n.localeName,
    ).format(selectedDate);
  }

  // ============================================================
  // LOCALIZED GENDER LABEL
  // ============================================================

  String _genderLabel(String value) {
    switch (value) {
      case 'Male':
        return _l10n.male;

      case 'Female':
        return _l10n.female;

      default:
        return value;
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
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        foregroundColor: _primaryTextColor,
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
        title: Text(
          _l10n.editProfile,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _primaryTextColor,
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
                          title: _l10n.personalInformation,
                          subtitle: _l10n.keepBasicInformationUpdated,
                        ),

                        const SizedBox(height: 12),

                        _buildSectionCard(
                          children: [
                            _modernInput(
                              controller: nameController,
                              label: _l10n.fullName,
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            _modernInput(
                              controller: emailController,
                              label: _l10n.emailAddress,
                              icon: Icons.email_outlined,
                              enabled: false,
                              helperText: _l10n.emailCannotBeChanged,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            _modernInput(
                              controller: phoneController,
                              label: _l10n.phoneNumber,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            _buildDateField(),
                            const SizedBox(
                              height: 14,
                            ),
                            _buildDropdownField(
                              label: _l10n.gender,
                              icon: Icons.wc_outlined,
                              value: gender,
                              items: const [
                                'Male',
                                'Female',
                              ],
                              itemLabels: [
                                _l10n.male,
                                _l10n.female,
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
                          title: _l10n.medicalInformation,
                          subtitle: _l10n.importantHealthProfileInformation,
                        ),

                        const SizedBox(height: 12),

                        _buildSectionCard(
                          children: [
                            _buildDropdownField(
                              label: _l10n.bloodGroup,
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
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              _l10n.allergies,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _l10n.allergiesDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: _lightTextColor,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            if (allergies.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allergies.map(
                                  (item) {
                                    return _buildAllergyChip(
                                      item,
                                    );
                                  },
                                ).toList(),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: _modernInput(
                                    controller: allergyController,
                                    label: _l10n.addAllergy,
                                    icon: Icons.add_rounded,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _addAllergy(),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
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
                          title: _l10n.emergencyContact,
                          subtitle: _l10n.emergencyContactDescription,
                        ),

                        const SizedBox(height: 12),

                        _buildSectionCard(
                          children: [
                            _modernInput(
                              controller: emergencyNameController,
                              label: _l10n.emergencyContactName,
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            _modernInput(
                              controller: emergencyPhoneController,
                              label: _l10n.emergencyContactPhone,
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
                              disabledBackgroundColor: const Color(
                                0xFF9BBFCC,
                              ),
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
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 21,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        _l10n.saveChanges,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: Text(
                            _l10n.changesSavedSecurely,
                            style: TextStyle(
                              fontSize: 12,
                              color: _lightTextColor,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _introStartColor,
            _introEndColor,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _introBorderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _iconBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!_isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.04,
                    ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.yourProfile,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _l10n.updateProfileDescription,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _secondaryTextColor,
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
            color: _sectionIconBackground,
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: _lightTextColor,
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
        color: _cardBackground,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          if (!_isDark)
            BoxShadow(
              color: Colors.black.withOpacity(
                0.025,
              ),
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
        color: enabled ? _primaryTextColor : _lightTextColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: _secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          size: 21,
          color: enabled ? primary : _lightTextColor,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          fontSize: 11,
          color: _lightTextColor,
        ),
        filled: true,
        fillColor: enabled ? _fieldBackground : _disabledFieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            15,
          ),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            15,
          ),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            15,
          ),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            15,
          ),
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
            color: _fieldBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _dateIconBackground,
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.dateOfBirth,
                      style: TextStyle(
                        fontSize: 12,
                        color: _lightTextColor,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                  ],
                ),
              ),
              Text(
                _formattedDate(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: _lightTextColor,
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
    List<String>? itemLabels,
    required ValueChanged<String> onChanged,
  }) {
    final displayLabels = itemLabels ??
        items.map((item) {
          if (label == _l10n.gender) {
            return _genderLabel(item);
          }

          return item;
        }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _sectionIconBackground,
              borderRadius: BorderRadius.circular(
                11,
              ),
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
                borderRadius: BorderRadius.circular(
                  15,
                ),
                dropdownColor: _isDark
                    ? const Color(
                        0xFF1E1E1E,
                      )
                    : Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primary,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
                selectedItemBuilder: (context) {
                  return items.asMap().entries.map((entry) {
                    final index = entry.key;

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: _lightTextColor,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            displayLabels[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                items: items.asMap().entries.map((entry) {
                  final index = entry.key;

                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(
                      displayLabels[index],
                      style: TextStyle(
                        color: _primaryTextColor,
                      ),
                    ),
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

  Widget _buildAllergyChip(
    String item,
  ) {
    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 6,
        top: 7,
        bottom: 7,
      ),
      decoration: BoxDecoration(
        color: _allergyBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _allergyBorder,
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: () => _removeAllergy(item),
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                3,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 17,
                color: _secondaryTextColor,
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
            borderRadius: BorderRadius.circular(
              15,
            ),
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
        color: _privacyBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _privacyBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _l10n.yourProfileSecurelyStored,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: _secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
