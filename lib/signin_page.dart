import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isPressed = false;
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // EMAIL / PASSWORD SIGN IN
  // ===========================================================================

  Future<void> _handleSignIn() async {
    if (isLoading || isGoogleLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _showMessage('Please enter your email.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          message = 'No account was found with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        default:
          message = e.message ?? 'Unable to sign in.';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
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
  // GOOGLE SIGN IN
  // ===========================================================================

  Future<void> _handleGoogleSignIn() async {
    if (isLoading || isGoogleLoading) return;

    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Open Google's account picker.
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User closed/cancelled the Google account picker.
      if (googleUser == null) {
        if (mounted) {
          setState(() {
            isGoogleLoading = false;
          });
        }

        return;
      }

      // Get authentication information from Google.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (!mounted) return;

      // Google login succeeded.
      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with this email using a different sign-in method.';
          break;

        case 'invalid-credential':
          message =
              'The Google sign-in credential is invalid. Please try again.';
          break;

        case 'operation-not-allowed':
          message = 'Google Sign-In is not enabled in Firebase.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        default:
          message = e.message ?? 'Unable to sign in with Google.';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'MEDMINDER: Google Sign-In error: $e',
      );

      _showMessage(
        'Google Sign-In failed. Please try again.',
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06,
                ),
                child: Column(
                  children: [
                    // =================================================================
                    // LOGO
                    // =================================================================

                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Image.asset(
                        'assets/loginLogo.png',
                        width: w * 0.42,
                        height: h * 0.14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2B2B),
                        fontFamily: 'serif',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================================================
                    // EMAIL
                    // =================================================================

                    _buildLabel('Email'),

                    const SizedBox(height: 6),

                    _buildTextField(
                      controller: emailController,
                      hintText: 'Enter your Email',
                      prefixIcon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 16),

                    // =================================================================
                    // PASSWORD
                    // =================================================================

                    _buildLabel('Password'),

                    const SizedBox(height: 6),

                    _buildTextField(
                      controller: passwordController,
                      hintText: '••••••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // =================================================================
                    // FORGOT PASSWORD
                    // =================================================================

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: isLoading || isGoogleLoading
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                );
                              },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================================
                    // SIGN IN BUTTON
                    // =================================================================

                    GestureDetector(
                      onTapDown: isLoading || isGoogleLoading
                          ? null
                          : (_) {
                              setState(() {
                                isPressed = true;
                              });
                            },
                      onTapUp: isLoading || isGoogleLoading
                          ? null
                          : (_) {
                              setState(() {
                                isPressed = false;
                              });

                              _handleSignIn();
                            },
                      onTapCancel: isLoading || isGoogleLoading
                          ? null
                          : () {
                              setState(() {
                                isPressed = false;
                              });
                            },
                      child: AnimatedScale(
                        scale: isPressed ? 0.97 : 1,
                        duration: const Duration(
                          milliseconds: 100,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D84A8),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
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
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================================
                    // DIVIDER
                    // =================================================================

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

                    const SizedBox(height: 20),

                    // =================================================================
                    // SOCIAL BUTTONS
                    // =================================================================

                    Row(
                      children: [
                        Expanded(
                          child: _socialButton(
                            text: 'Google',
                            imagePath: 'assets/google.png',
                            onPressed: _handleGoogleSignIn,
                            isLoading: isGoogleLoading,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _socialButton(
                            text: 'Facebook',
                            imagePath: 'assets/facebook.png',
                            onPressed: () {
                              _showMessage(
                                'Facebook Sign-In is not configured yet.',
                              );
                            },
                            isLoading: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // =================================================================
                    // SIGN UP
                    // =================================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don’t have account? ',
                        ),
                        GestureDetector(
                          onTap: isLoading || isGoogleLoading
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    '/signup',
                                  );
                                },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
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
          fontSize: 15,
          fontWeight: FontWeight.w500,
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
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF2F7),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade400,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SOCIAL BUTTON
  // ===========================================================================

  Widget _socialButton({
    required String text,
    required String imagePath,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    bool pressed = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final bool disabled = isLoading || this.isLoading;

        return GestureDetector(
          onTapDown: disabled
              ? null
              : (_) {
                  setState(() {
                    pressed = true;
                  });
                },
          onTapUp: disabled
              ? null
              : (_) {
                  setState(() {
                    pressed = false;
                  });

                  onPressed();
                },
          onTapCancel: disabled
              ? null
              : () {
                  setState(() {
                    pressed = false;
                  });
                },
          child: AnimatedScale(
            scale: pressed ? 0.95 : 1,
            duration: const Duration(
              milliseconds: 100,
            ),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  181,
                  169,
                  240,
                  250,
                ),
                border: Border.all(
                  color: const Color.fromARGB(
                    170,
                    71,
                    71,
                    71,
                  ),
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF3D84A8),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            imagePath,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
