import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context)!;

    final email = emailController.text.trim();
    final password = passwordController.text;

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
        case 'user-not-found':
        case 'wrong-password':
          message = l10n.incorrectEmailOrPassword;
          break;

        case 'invalid-email':
          message = l10n.invalidEmailAddress;
          break;

        case 'user-disabled':
          message = l10n.accountDisabled;
          break;

        case 'too-many-requests':
          message = l10n.tooManyAttempts;
          break;

        case 'network-request-failed':
          message = l10n.checkInternet;
          break;

        default:
          message = l10n.unableToSignIn;
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'MEDELYRA: Email sign-in error: $e',
      );

      _showMessage(
        l10n.somethingWentWrong,
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

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User cancelled Google account picker.
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(
        credential,
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
        case 'account-exists-with-different-credential':
          message = l10n.accountExistsDifferentMethod;
          break;

        case 'invalid-credential':
          message = l10n.invalidGoogleCredential;
          break;

        case 'operation-not-allowed':
          message = l10n.googleSignInNotEnabled;
          break;

        case 'user-disabled':
          message = l10n.accountDisabled;
          break;

        case 'network-request-failed':
          message = l10n.checkInternet;
          break;

        default:
          message = e.message ?? l10n.unableToSignInGoogle;
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'MEDELYRA: Google Sign-In error: $e',
      );

      _showMessage(
        l10n.googleSignInFailed,
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

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isSmall = h < 700;
    final bool busy = isLoading || isGoogleLoading;

    final l10n = AppLocalizations.of(context)!;

    // =========================================================================
    // THEME COLORS
    // =========================================================================

    final Color pageBackground =
        isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

    final Color primaryText = isDark ? Colors.white : const Color(0xFF2B2B2B);

    final Color secondaryText =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF747373);

    return Scaffold(
      backgroundColor: pageBackground,
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
                        isDark
                            ? 'assets/medelyraLogoDark.png'
                            : 'assets/medelyraLogo.png',
                        width: w * 0.44,
                        height: h * 0.15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // =================================================================
                    // TITLE
                    // =================================================================

                    Text(
                      l10n.signIn,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                        fontFamily: 'serif',
                      ),
                    ),

                    SizedBox(
                      height: isSmall ? 22 : 28,
                    ),

                    // =================================================================
                    // EMAIL
                    // =================================================================

                    _buildLabel(
                      l10n.email,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 6),

                    _buildTextField(
                      context: context,
                      controller: emailController,
                      hintText: l10n.enterYourEmail,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // =================================================================
                    // PASSWORD
                    // =================================================================

                    _buildLabel(
                      l10n.password,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 6),

                    _buildTextField(
                      context: context,
                      controller: passwordController,
                      hintText: l10n.enterYourPassword,
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      keyboardType: TextInputType.text,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        splashRadius: 20,
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
                          color: isDark
                              ? const Color(0xFFBDBDBD)
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // =================================================================
                    // FORGOT PASSWORD
                    // =================================================================

                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: GestureDetector(
                        onTap: busy
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                );
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Text(
                            l10n.forgotPasswordQuestion,
                            style: const TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: isSmall ? 16 : 20,
                    ),

                    // =================================================================
                    // SIGN IN BUTTON
                    // =================================================================

                    GestureDetector(
                      onTapDown: busy
                          ? null
                          : (_) {
                              setState(() {
                                isPressed = true;
                              });
                            },
                      onTapUp: busy
                          ? null
                          : (_) {
                              setState(() {
                                isPressed = false;
                              });

                              _handleSignIn();
                            },
                      onTapCancel: busy
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
                          height: 47,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D84A8),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.35 : 0.18,
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
                              : Text(
                                  l10n.signIn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: isSmall ? 18 : 24,
                    ),

                    // =================================================================
                    // DIVIDER
                    // =================================================================

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                isDark ? const Color(0xFF555555) : Colors.grey,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: Text(
                            l10n.orContinueWith,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color:
                                isDark ? const Color(0xFF555555) : Colors.grey,
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

                    _googleButton(
                      context,
                      isDark: isDark,
                      googleText: l10n.continueWithGoogle,
                    ),

                    const SizedBox(height: 18),

                    // =================================================================
                    // SIGN UP
                    // =================================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.dontHaveAccount,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFFBDBDBD)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: busy
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    '/signup',
                                  );
                                },
                          child: Text(
                            l10n.signUp,
                            style: const TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
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

  Widget _buildLabel(
    String text, {
    required bool isDark,
  }) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2B2B2B),
        ),
      ),
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required TextInputType keyboardType,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 47,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFDDF2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade400,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isDark ? 0.28 : 0.12,
              ),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF4A4A4A),
          ),
          cursorColor:
              isDark ? const Color(0xFF8FC4DE) : const Color(0xFF3D84A8),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 13,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF8E8E8E) : Colors.grey,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF555555),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // GOOGLE BUTTON
  // ===========================================================================

  Widget _googleButton(
    BuildContext context, {
    required bool isDark,
    required String googleText,
  }) {
    final bool disabled = isLoading || isGoogleLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: disabled ? null : _handleGoogleSignIn,
        child: AnimatedOpacity(
          duration: const Duration(
            milliseconds: 150,
          ),
          opacity: disabled ? 0.6 : 1,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    isDark ? 0.30 : 0.10,
                  ),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isGoogleLoading
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
                          'assets/google.png',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.continueWithGoogle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF333333),
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
}
