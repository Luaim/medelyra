import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (isLoading) return;

    final userName = userNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Username validation
    if (userName.isEmpty) {
      _showMessage('Please enter your user name.');
      return;
    }

    // Email validation
    if (email.isEmpty) {
      _showMessage('Please enter your email.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      _showMessage('Please enter a password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    // Confirm password
    if (confirmPassword.isEmpty) {
      _showMessage('Please confirm your password.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    // Terms
    if (!agreeTerms) {
      _showMessage('Please agree to the Terms & Conditions.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ==============================
      // CREATE FIREBASE ACCOUNT
      // ==============================

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user was not created.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': userName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'SIGN UP SUCCESS: ${userCredential.user?.uid}',
      );

      // ==============================
      // SAVE USERNAME
      // ==============================

      try {
        await userCredential.user?.updateDisplayName(userName);

        debugPrint(
          'DISPLAY NAME UPDATED: $userName',
        );
      } catch (e, stackTrace) {
        // Do NOT fail the whole registration if
        // updating the display name fails.
        debugPrint('DISPLAY NAME ERROR: $e');
        debugPrintStack(stackTrace: stackTrace);
      }

      // ==============================
      // GO TO SUCCESS PAGE
      // ==============================

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
          message = 'Email/password sign up is currently unavailable. '
              'Please enable it in Firebase Authentication.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        default:
          message = e.message ?? 'Firebase could not create your account.';
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('UNKNOWN SIGN UP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Sign up failed. Check the terminal for the exact error.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;

    final isSmall = h < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.06,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// TOP AREA
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmall ? 4 : 8),

                  /// LOGO
                  Image.asset(
                    'assets/loginLogo.png',
                    width: w * 0.40,
                    height: h * 0.15,
                  ),

                  SizedBox(height: isSmall ? 6 : 12),

                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2B2B),
                      fontFamily: 'serif',
                    ),
                  ),

                  SizedBox(height: isSmall ? 20 : 26),

                  /// USER NAME
                  _buildTextField(
                    controller: userNameController,
                    hintText: 'User Name',
                    suffixIcon: const Icon(
                      Icons.person_outline,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// EMAIL
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    suffixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// PASSWORD
                  _buildTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// CONFIRM PASSWORD
                  _buildTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: obscureConfirmPassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// TERMS
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            agreeTerms = !agreeTerms;
                          });
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFC62828),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: agreeTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Agree With ',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: 'Terms & Condition',
                                style: TextStyle(
                                  color: Color(0xFF001EBD),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmall ? 18 : 24),

                  /// SIGN UP BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF387A97),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF387A97).withOpacity(0.6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: isSmall ? 16 : 22),

                  /// DIVIDER
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          'OR Continue with',
                          style: TextStyle(
                            color: Color.fromARGB(
                              255,
                              116,
                              115,
                              115,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmall ? 14 : 20),

                  /// SOCIAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialCircleButton(
                        'assets/google.png',
                      ),
                      const SizedBox(width: 25),
                      _socialCircleButton(
                        'assets/facebook.png',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _socialCircleButton(String path) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEAF6FA),
      ),
      child: Center(
        child: Image.asset(
          path,
          width: 35,
        ),
      ),
    );
  }
}
