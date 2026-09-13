import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;

  bool isLoading = false;
  bool isGoogleLoading = false;

  // ===========================================================================
  // THEME COLORS
  // ===========================================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF8F6F8);

  Color get _primaryTextColor =>
      _isDark ? Colors.white : const Color(0xFF292929);

  Color get _labelTextColor =>
      _isDark ? const Color(0xFFE0E0E0) : const Color(0xFF303030);

  Color get _bodyTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF333333);

  Color get _inputBackground =>
      _isDark ? const Color(0xFF252525) : const Color(0xFFEAF4F8);

  Color get _inputBorderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D8DC);

  Color get _inputTextColor => _isDark ? Colors.white : const Color(0xFF303030);

  Color get _hintColor =>
      _isDark ? const Color(0xFF8E8E8E) : const Color(0xFF9BA5AA);

  Color get _inputIconColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF4F5A5F);

  Color get _visibilityIconColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF555555);

  Color get _dividerColor =>
      _isDark ? const Color(0xFF555555) : const Color(0xFFBDBDBD);

  Color get _dividerTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF777777);

  Color get _googleBackground =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _googleBorderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE1E1E1);

  Color get _googleTextColor =>
      _isDark ? Colors.white : const Color(0xFF353535);

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // EMAIL / PASSWORD SIGN UP
  // ===========================================================================

  Future<void> _handleSignUp() async {
    if (isLoading || isGoogleLoading) return;

    final l10n = AppLocalizations.of(context)!;

    final userName = userNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // -------------------------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------------------------

    if (userName.isEmpty) {
      _showMessage(l10n.pleaseEnterUserName);
      return;
    }

    if (userName.length < 2) {
      _showMessage(l10n.userNameMinLength);
      return;
    }

    if (email.isEmpty) {
      _showMessage(l10n.pleaseEnterEmail);
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(l10n.invalidEmailAddress);
      return;
    }

    if (password.isEmpty) {
      _showMessage(l10n.pleaseEnterPassword);
      return;
    }

    if (password.length < 6) {
      _showMessage(l10n.passwordMinLength);
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(l10n.pleaseConfirmPassword);
      return;
    }

    if (password != confirmPassword) {
      _showMessage(l10n.passwordsDoNotMatch);
      return;
    }

    if (!agreeTerms) {
      _showMessage(l10n.agreeTermsRequired);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // -----------------------------------------------------------------------
      // CREATE FIREBASE ACCOUNT
      // -----------------------------------------------------------------------

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user was not created.');
      }

      // -----------------------------------------------------------------------
      // SAVE USER INFORMATION TO FIRESTORE
      // -----------------------------------------------------------------------

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': userName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // -----------------------------------------------------------------------
      // SAVE DISPLAY NAME
      // -----------------------------------------------------------------------

      try {
        await user.updateDisplayName(userName);
      } catch (e) {
        debugPrint('DISPLAY NAME ERROR: $e');
      }

      debugPrint('SIGN UP SUCCESS: ${user.uid}');

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FIREBASE SIGN UP ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = l10n.emailAlreadyInUse;
          break;

        case 'invalid-email':
          message = l10n.invalidEmailAddress;
          break;

        case 'weak-password':
          message = l10n.weakPassword;
          break;

        case 'operation-not-allowed':
          message = l10n.emailSignUpUnavailable;
          break;

        case 'network-request-failed':
          message = l10n.checkInternet;
          break;

        case 'too-many-requests':
          message = l10n.tooManyAttempts;
          break;

        default:
          message = e.message ?? l10n.unableToCreateAccount;
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('UNKNOWN SIGN UP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        l10n.signUpFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ===========================================================================
  // TERMS & CONDITIONS
  // ===========================================================================

  void _showTermsAndConditions() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final Color dialogBackground =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F6F8);

    final Color dialogPrimaryText =
        isDark ? Colors.white : const Color(0xFF292929);

    final Color dialogCloseIcon =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF555555);

    final Color dialogDivider =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(isDark ? 0.60 : 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 430,
              maxHeight: 620,
            ),
            decoration: BoxDecoration(
              color: dialogBackground,
              borderRadius: BorderRadius.circular(22),
              border: isDark
                  ? Border.all(
                      color: const Color(0xFF333333),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----------------------------------------------------------------
                // HEADER
                // ----------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    10,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.termsAndConditions,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: dialogPrimaryText,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: Icon(
                          Icons.close,
                          size: 24,
                          color: dialogCloseIcon,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: dialogDivider,
                ),

                // ----------------------------------------------------------------
                // TERMS CONTENT
                // ----------------------------------------------------------------

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TermsSection(
                          title: l10n.termsAcceptanceTitle,
                          text: l10n.termsAcceptanceText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsUseTitle,
                          text: l10n.termsUseText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsMedicalTitle,
                          text: l10n.termsMedicalText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsAccountTitle,
                          text: l10n.termsAccountText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsInformationTitle,
                          text: l10n.termsInformationText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsMedicationTitle,
                          text: l10n.termsMedicationText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsAvailabilityTitle,
                          text: l10n.termsAvailabilityText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsChangesTitle,
                          text: l10n.termsChangesText,
                          isDark: isDark,
                        ),
                        _TermsSection(
                          title: l10n.termsContactTitle,
                          text: l10n.termsContactText,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                // ----------------------------------------------------------------
                // CLOSE BUTTON
                // ----------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    18,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D84A8),
                        foregroundColor: Colors.white,
                        elevation: isDark ? 0 : 2,
                        shadowColor: Colors.black.withOpacity(0.20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        l10n.close,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // GOOGLE SIGN UP
  // ===========================================================================

  Future<void> _handleGoogleSignUp() async {
    if (isLoading || isGoogleLoading) return;

    final l10n = AppLocalizations.of(context)!;

    if (!agreeTerms) {
      _showMessage(l10n.agreeTermsRequired);
      return;
    }

    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            isGoogleLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Google user was not created.');
      }

      // -----------------------------------------------------------------------
      // SAVE GOOGLE USER TO FIRESTORE
      // -----------------------------------------------------------------------

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': user.displayName ?? googleUser.displayName ?? 'Google User',
          'email': user.email ?? googleUser.email,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        },
        SetOptions(merge: true),
      );

      debugPrint(
        'GOOGLE SIGN UP SUCCESS: ${user.uid}',
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('GOOGLE SIGN UP FIREBASE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = l10n.accountExistsDifferentMethod;
          break;

        case 'credential-already-in-use':
          message = l10n.googleAccountAlreadyUsed;
          break;

        case 'operation-not-allowed':
          message = l10n.googleSignInNotEnabled;
          break;

        case 'invalid-credential':
          message = l10n.invalidGoogleInformation;
          break;

        case 'user-disabled':
          message = l10n.accountDisabled;
          break;

        case 'network-request-failed':
          message = l10n.checkInternet;
          break;

        default:
          message = e.message ?? l10n.unableToSignUpGoogle;
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('GOOGLE SIGN UP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        l10n.googleSignUpFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  // ===========================================================================
  // EMAIL VALIDATION
  // ===========================================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;

    final bool isSmall = h < 700;
    final bool busy = isLoading || isGoogleLoading;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.05,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // =================================================================
                  // BACK BUTTON
                  // =================================================================

                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 2,
                      ),
                      child: IconButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: Icon(
                          Icons.arrow_back,
                          size: 27,
                          color: _isDark
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: isSmall ? 0 : 3,
                  ),

                  // =================================================================
                  // LOGO
                  // =================================================================

                  Image.asset(
                    _isDark
                        ? 'assets/medelyraLogoDark.png'
                        : 'assets/medelyraLogo.png',
                    width: w * 0.44,
                    height: h * 0.15,
                  ),

                  SizedBox(
                    height: isSmall ? 3 : 8,
                  ),

                  // =================================================================
                  // TITLE
                  // =================================================================

                  Text(
                    l10n.signUp,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _primaryTextColor,
                      fontFamily: 'serif',
                    ),
                  ),

                  SizedBox(
                    height: isSmall ? 17 : 22,
                  ),

                  // =================================================================
                  // USER NAME
                  // =================================================================

                  _buildLabel(l10n.userName),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: userNameController,
                    hintText: l10n.enterYourUserName,
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outline,
                  ),

                  const SizedBox(height: 13),

                  // =================================================================
                  // EMAIL
                  // =================================================================

                  _buildLabel(l10n.email),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: emailController,
                    hintText: l10n.enterYourEmail,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 13),

                  // =================================================================
                  // PASSWORD
                  // =================================================================

                  _buildLabel(l10n.password),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: passwordController,
                    hintText: l10n.enterYourPassword,
                    obscureText: obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 21,
                        color: _visibilityIconColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // =================================================================
                  // CONFIRM PASSWORD
                  // =================================================================

                  _buildLabel(l10n.confirmPassword),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: confirmPasswordController,
                    hintText: l10n.confirmYourPassword,
                    obscureText: obscureConfirmPassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 21,
                        color: _visibilityIconColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================================
                  // TERMS & CONDITIONS
                  // =================================================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // -------------------------------------------------------------
                      // CHECKBOX
                      // -------------------------------------------------------------

                      GestureDetector(
                        onTap: busy
                            ? null
                            : () {
                                setState(() {
                                  agreeTerms = !agreeTerms;
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 150,
                          ),
                          curve: Curves.easeOut,
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: agreeTerms
                                ? const Color(0xFF2F7FA5)
                                : Colors.transparent,
                            border: Border.all(
                              color: agreeTerms
                                  ? const Color(0xFF2F7FA5)
                                  : const Color(0xFF9E9E9E),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: agreeTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // -------------------------------------------------------------
                      // AGREE WITH TEXT
                      // -------------------------------------------------------------

                      Text(
                        l10n.agreeWith,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          color: _bodyTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      // -------------------------------------------------------------
                      // TERMS BUTTON
                      // -------------------------------------------------------------

                      GestureDetector(
                        onTap: busy ? null : _showTermsAndConditions,
                        child: Text(
                          l10n.termsAndConditions,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: Color(0xFF1239B5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: isSmall ? 18 : 21,
                  ),

                  // =================================================================
                  // SIGN UP BUTTON
                  // =================================================================

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: busy ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D84A8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFF2F7FA5,
                        ).withOpacity(0.55),
                        disabledForegroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(
                          _isDark ? 0.35 : 0.20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.signUp,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(
                    height: isSmall ? 17 : 20,
                  ),

                  // =================================================================
                  // DIVIDER
                  // =================================================================

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _dividerColor,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          l10n.orContinueWith,
                          style: TextStyle(
                            color: _dividerTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: _dividerColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: isSmall ? 14 : 18,
                  ),

                  // =================================================================
                  // GOOGLE
                  // =================================================================

                  _googleButton(),

                  const SizedBox(height: 17),

                  // =================================================================
                  // SIGN IN
                  // =================================================================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.alreadyHaveAccount,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _bodyTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: busy
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: Text(
                          l10n.signIn,
                          style: const TextStyle(
                            color: Color(0xFFB51E24),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LABEL
  // ===========================================================================

  Widget _buildLabel(String text) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _labelTextColor,
        ),
      ),
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 47,
      decoration: BoxDecoration(
        color: _inputBackground,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _inputBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              _isDark ? 0.28 : 0.08,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        cursorColor:
            _isDark ? const Color(0xFF8FC4DE) : const Color(0xFF4F5A5F),
        style: TextStyle(
          fontSize: 14,
          color: _inputTextColor,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 11,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: _hintColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
            color: _inputIconColor,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // ===========================================================================
  // GOOGLE BUTTON
  // ===========================================================================

  Widget _googleButton() {
    final bool disabled = isLoading || isGoogleLoading;

    return GestureDetector(
      onTap: disabled ? null : _handleGoogleSignUp,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          height: 47,
          decoration: BoxDecoration(
            color: _googleBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _googleBorderColor,
              width: 1,
            ),
            boxShadow: [
              if (!_isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: isGoogleLoading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Color(0xFF2F7FA5),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google.png',
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.continueWithGoogle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _googleTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TERMS SECTION WIDGET
// =============================================================================

class _TermsSection extends StatelessWidget {
  final String title;
  final String text;
  final bool isDark;

  const _TermsSection({
    required this.title,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}
