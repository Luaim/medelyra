import 'package:flutter/material.dart';
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
        '/successLogin',
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
        '/successLogin',
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
      backgroundColor: const Color(0xFFF8F6F8),
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
                    'assets/loginLogo.png',
                    width: w * 0.40,
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

                  GestureDetector(
                    onTap: busy
                        ? null
                        : () {
                            setState(() {
                              agreeTerms = !agreeTerms;
                            });
                          },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Clean blue checkbox
                        AnimatedContainer(
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

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.2,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Agree With ',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: Color(0xFF1239B5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        disabledBackgroundColor:
                            const Color(0xFF2F7FA5).withOpacity(0.55),
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
        // Light blue/gray like the screenshot
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
