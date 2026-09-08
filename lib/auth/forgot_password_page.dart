import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  bool isPressed = false;

  // ============================================================
  // THEME COLORS
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

  Color get _primaryTextColor =>
      _isDark ? Colors.white : const Color(0xFF2B2B2B);

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : Colors.grey;

  Color get _labelTextColor =>
      _isDark ? const Color(0xFFE0E0E0) : const Color(0xFF333333);

  Color get _inputBackground =>
      _isDark ? const Color(0xFF252525) : const Color(0xFFDDF2F7);

  Color get _inputBorderColor =>
      _isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade400;

  Color get _inputTextColor => _isDark ? Colors.white : const Color(0xFF303030);

  Color get _hintTextColor => _isDark ? const Color(0xFF8E8E8E) : Colors.grey;

  Color get _inputIconColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF555555);

  Color get _backIconColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF4A4A4A);

  Color get _signInTextColor =>
      _isDark ? const Color(0xFFE0E0E0) : const Color(0xFF333333);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND PASSWORD RESET EMAIL
  // ============================================================

  Future<void> _sendResetEmail() async {
    if (isLoading) return;

    final String email = emailController.text.trim();

    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    if (email.isEmpty) {
      _showMessage('Please enter your email.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      isLoading = true;
      isPressed = false;
    });

    try {
      // ----------------------------------------------------------
      // Firebase sends the password reset email.
      //
      // IMPORTANT:
      // This can also work for an account that originally used
      // Google if a password provider is linked to that account.
      // Firebase keeps both providers on the same account.
      // ----------------------------------------------------------

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showSuccessMessage(
        'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      debugPrint(
        'MEDELYRA: Password reset error: '
        '${e.code} - ${e.message}',
      );

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account was found with this email.';
          break;

        case 'operation-not-allowed':
          message = 'Password reset is currently unavailable. '
              'Please contact support.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;

        default:
          message = 'Unable to send reset email. Please try again.';
          break;
      }

      _showMessage(message);
    } catch (e) {
      debugPrint(
        'MEDELYRA: Unexpected password reset error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isPressed = false;
        });
      }
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ============================================================
  // ERROR / INFORMATION MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final double h = size.height;
    final double w = size.width;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ======================================================
            // MAIN CONTENT
            // ======================================================

            Center(
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // LOGO
                        // ==================================================

                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: Image.asset(
                            'assets/medelyraLogo.png',
                            width: w * 0.44,
                            height: h * 0.15,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ==================================================
                        // TITLE
                        // ==================================================

                        Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _primaryTextColor,
                            fontFamily: 'serif',
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ==================================================
                        // DESCRIPTION
                        // ==================================================

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: Text(
                            'Enter your email address and we will send you '
                            'a link to reset your password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _secondaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // EMAIL LABEL
                        // ==================================================

                        _buildLabel('Email'),

                        const SizedBox(height: 6),

                        // ==================================================
                        // EMAIL FIELD
                        // ==================================================

                        _buildTextField(
                          controller: emailController,
                          hintText: 'Enter your Email',
                          prefixIcon: Icons.email_outlined,
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // SEND RESET LINK BUTTON
                        // ==================================================

                        GestureDetector(
                          onTapDown: isLoading
                              ? null
                              : (_) {
                                  setState(() {
                                    isPressed = true;
                                  });
                                },
                          onTapUp: isLoading
                              ? null
                              : (_) {
                                  setState(() {
                                    isPressed = false;
                                  });

                                  _sendResetEmail();
                                },
                          onTapCancel: isLoading
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
                                    color: Colors.black.withOpacity(
                                      _isDark ? 0.35 : 0.20,
                                    ),
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
                                      'Send Reset Link',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // BACK TO SIGN IN
                        // ==================================================

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Remember your password? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: _signInTextColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                    },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF9B1C1C),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
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

            // ======================================================
            // BACK ARROW
            // ======================================================

            Positioned(
              top: 4,
              left: 12,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: Icon(
                  Icons.arrow_back,
                  size: 28,
                  color: _backIconColor,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _labelTextColor,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              _isDark ? 0.28 : 0.15,
            ),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _inputBorderColor,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        cursorColor:
            _isDark ? const Color(0xFF8FC4DE) : const Color(0xFF4A4A4A),
        style: TextStyle(
          color: _inputTextColor,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: _hintTextColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: _inputIconColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
        ),
        onSubmitted: (_) {
          _sendResetEmail();
        },
      ),
    );
  }
}
