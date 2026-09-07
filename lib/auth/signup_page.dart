import 'package:flutter/material.dart';
import 'package:medelyra/services/theme_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

    final userName = userNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // -------------------------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------------------------

    if (userName.isEmpty) {
      _showMessage('Please enter your user name.');
      return;
    }

    if (userName.length < 2) {
      _showMessage('User name must be at least 2 characters.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter a password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('Please confirm your password.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (!agreeTerms) {
      _showMessage('Please agree to the Terms & Conditions.');
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
          message = 'An account already exists with this email.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message = 'Your password is too weak.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password sign up is currently unavailable. Please check Firebase Authentication.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        default:
          message = e.message ?? 'Unable to create your account.';
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('UNKNOWN SIGN UP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Sign up failed. Please try again.',
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
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
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
              color: const Color(0xFFF8F6F8),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
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
                      const Expanded(
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF292929),
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  color: Color(0xFFD0D0D0),
                ),

                // ----------------------------------------------------------------
                // TERMS CONTENT
                // ----------------------------------------------------------------

                const Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TermsSection(
                          title: '1. Acceptance of Terms',
                          text:
                              'By creating a Medelyra account, you agree to these Terms & Conditions. If you do not agree with these terms, please do not create an account or use the application.',
                        ),
                        _TermsSection(
                          title: '2. Use of Medelyra',
                          text:
                              'Medelyra is designed to help users manage and organize their medication-related information and reminders. You agree to use the application only for lawful purposes and in a responsible manner.',
                        ),
                        _TermsSection(
                          title: '3. Medical Information',
                          text:
                              'Medelyra is not a replacement for a doctor, pharmacist, or other qualified healthcare professional. Information and reminders provided through the application should not be considered medical advice. Always follow instructions provided by your healthcare professional.',
                        ),
                        _TermsSection(
                          title: '4. Your Account',
                          text:
                              'You are responsible for providing accurate information when creating your account and for keeping your account information secure. You are responsible for activity performed through your account.',
                        ),
                        _TermsSection(
                          title: '5. User Information',
                          text:
                              'Medelyra may store information that you provide when using the application, such as your name, email address, and information necessary to provide the application services. Your information should be handled according to the application’s privacy practices.',
                        ),
                        _TermsSection(
                          title: '6. Medication Reminders',
                          text:
                              'Medication reminders are provided as a convenience. You remain responsible for taking medications according to the instructions given by your healthcare professional. Medelyra should not be relied upon as the sole method for remembering or managing medication.',
                        ),
                        _TermsSection(
                          title: '7. Application Availability',
                          text:
                              'We aim to keep Medelyra available and functioning correctly, but we cannot guarantee that the application will always be available, error-free, or uninterrupted.',
                        ),
                        _TermsSection(
                          title: '8. Changes to These Terms',
                          text:
                              'These Terms & Conditions may be updated from time to time. Continued use of Medelyra after changes are made means that you accept the updated terms.',
                        ),
                        _TermsSection(
                          title: '9. Contact',
                          text:
                              'If you have questions about these Terms & Conditions, please contact the Medelyra support team.',
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
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
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

    if (!agreeTerms) {
      _showMessage('Please agree to the Terms & Conditions.');
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
          message =
              'An account already exists with this email using a different sign-in method.';
          break;

        case 'credential-already-in-use':
          message = 'This Google account is already being used.';
          break;

        case 'operation-not-allowed':
          message = 'Google Sign-In is not enabled in Firebase.';
          break;

        case 'invalid-credential':
          message =
              'The Google sign-in information is invalid. Please try again.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        default:
          message = e.message ?? 'Unable to sign up with Google.';
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('GOOGLE SIGN UP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Google Sign-Up failed. Please try again.',
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

    return Scaffold(
      backgroundColor: ThemeService.surface(context, const Color(0xFFF8F6F8)),
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
                    alignment: Alignment.centerLeft,
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
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 27,
                          color: Color(0xFF222222),
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
                    'assets/medelyraLogo.png',
                    width: w * 0.44,
                    height: h * 0.15,
                  ),

                  SizedBox(
                    height: isSmall ? 3 : 8,
                  ),

                  // =================================================================
                  // TITLE
                  // =================================================================

                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF292929),
                      fontFamily: 'serif',
                    ),
                  ),

                  SizedBox(
                    height: isSmall ? 17 : 22,
                  ),

                  // =================================================================
                  // USER NAME
                  // =================================================================

                  _buildLabel('User Name'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: userNameController,
                    hintText: 'Enter your User Name',
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outline,
                  ),

                  const SizedBox(height: 13),

                  // =================================================================
                  // EMAIL
                  // =================================================================

                  _buildLabel('Email'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: emailController,
                    hintText: 'Enter your Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 13),

                  // =================================================================
                  // PASSWORD
                  // =================================================================

                  _buildLabel('Password'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: passwordController,
                    hintText: 'Enter your Password',
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
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // =================================================================
                  // CONFIRM PASSWORD
                  // =================================================================

                  _buildLabel('Confirm Password'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm your Password',
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
                        color: const Color(0xFF555555),
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

                      const Text(
                        'Agree With ',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      // -------------------------------------------------------------
                      // TERMS BUTTON
                      // -------------------------------------------------------------

                      GestureDetector(
                        onTap: busy ? null : _showTermsAndConditions,
                        child: const Text(
                          'Terms & Conditions',
                          style: TextStyle(
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
                        shadowColor: Colors.black.withOpacity(0.20),
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
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
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

                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xFFBDBDBD),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          'OR Continue with',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Color(0xFFBDBDBD),
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
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                      GestureDetector(
                        onTap: busy
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
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
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF303030),
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
        color: const Color(0xFFEAF4F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFD0D8DC),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF303030),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 11,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9BA5AA),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
            color: const Color(0xFF4F5A5F),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE1E1E1),
              width: 1,
            ),
            boxShadow: [
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
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF353535),
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

  const _TermsSection({
    required this.title,
    required this.text,
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}
