import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController currentController = TextEditingController();

  final TextEditingController newController = TextEditingController();

  final TextEditingController confirmController = TextEditingController();

  // ============================================================
  // VISIBILITY
  // ============================================================

  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;
  String? error;

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // AUTHENTICATION CHECK
  // ============================================================

  /// Returns true when this Firebase account has a password
  /// authentication provider.
  ///
  /// Google-only accounts will return false.
  bool get hasPasswordProvider {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  /// Returns true when the account is using Google.
  bool get isGoogleAccount {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  // ============================================================
  // THEME HELPERS
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

  Color get _appBarBackground =>
      _isDark ? const Color(0xFF121212) : Colors.white;

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF252525) : Colors.white;

  Color get _borderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE7E4E7);

  Color get _primaryTextColor =>
      _isDark ? Colors.white : const Color(0xFF222222);

  Color get _headingTextColor =>
      _isDark ? Colors.white : const Color(0xFF292929);

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF888888);

  Color get _hintColor =>
      _isDark ? const Color(0xFF8E8E8E) : const Color(0xFFA5A3A5);

  Color get _iconColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF9B999B);

  Color get _errorBackground =>
      _isDark ? const Color(0xFF302020) : const Color(0xFFFFEEEE);

  Color get _errorTextColor =>
      _isDark ? const Color(0xFFFFB4B4) : const Color(0xFF9B3A3A);

  Color get _googleCardBackground =>
      _isDark ? const Color(0xFF1E3035) : const Color(0xFFEAF6FA);

  Color get _googleCardBorder =>
      _isDark ? const Color(0xFF31515A) : const Color(0xFFD4EAF0);

  Color get _googleIconBackground =>
      _isDark ? const Color(0xFF252525) : Colors.white;

  Color get _googleTitleColor =>
      _isDark ? Colors.white : const Color(0xFF303030);

  Color get _googleDescriptionColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF666666);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    super.dispose();
  }

  // ============================================================
  // UPDATE PASSWORD
  // ============================================================

  Future<void> _save() async {
    if (isLoading) return;

    final user = _auth.currentUser;

    // ------------------------------------------------------------
    // CHECK USER
    // ------------------------------------------------------------

    if (user == null) {
      setState(() {
        error = 'Your session has expired. Please sign in again.';
      });
      return;
    }

    // ------------------------------------------------------------
    // GOOGLE / NON-PASSWORD ACCOUNT
    // ------------------------------------------------------------

    if (!hasPasswordProvider) {
      setState(() {
        error = isGoogleAccount
            ? 'This account uses Google Sign-In. Your password is managed by Google.'
            : 'This account does not have a password that can be changed here.';
      });
      return;
    }

    // ------------------------------------------------------------
    // GET VALUES
    // ------------------------------------------------------------

    // Do NOT trim passwords.
    // Spaces can technically be part of a password.
    final currentPassword = currentController.text;
    final newPassword = newController.text;
    final confirmPassword = confirmController.text;

    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    if (currentPassword.isEmpty) {
      setState(() {
        error = 'Please enter your current password.';
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        error = 'Please enter your new password.';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        error = 'Please confirm your new password.';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        error = 'New password must be at least 6 characters.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        error = 'Passwords do not match.';
      });
      return;
    }

    if (currentPassword == newPassword) {
      setState(() {
        error = 'New password must be different from your current password.';
      });
      return;
    }

    if (user.email == null || user.email!.isEmpty) {
      setState(() {
        error = 'Unable to update the password for this account.';
      });
      return;
    }

    // ------------------------------------------------------------
    // START LOADING
    // ------------------------------------------------------------

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // ----------------------------------------------------------
      // RE-AUTHENTICATE USER
      // ----------------------------------------------------------

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // ----------------------------------------------------------
      // UPDATE PASSWORD
      // ----------------------------------------------------------

      await user.updatePassword(newPassword);

      if (!mounted) return;

      // ----------------------------------------------------------
      // CLEAR FIELDS
      // ----------------------------------------------------------

      currentController.clear();
      newController.clear();
      confirmController.clear();

      setState(() {
        isLoading = false;
        error = null;
      });

      // ----------------------------------------------------------
      // SUCCESS MESSAGE
      // ----------------------------------------------------------

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Password updated successfully.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

      // ----------------------------------------------------------
      // RETURN TO SETTINGS
      // ----------------------------------------------------------

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;

        case 'weak-password':
          message = 'New password is too weak.';
          break;

        case 'requires-recent-login':
          message = 'Please sign in again before changing your password.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'user-not-found':
          message = 'Your account could not be found. Please sign in again.';
          break;

        default:
          message = e.message ?? 'Unable to update your password.';
      }

      setState(() {
        isLoading = false;
        error = message;
      });
    } catch (e) {
      debugPrint('PASSWORD UPDATE ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        error = 'Something went wrong. Please try again.';
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final googleOnlyAccount = isGoogleAccount && !hasPasswordProvider;

    return Scaffold(
      backgroundColor: _pageBackground,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: _appBarBackground,
        foregroundColor: _primaryTextColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Change Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _primaryTextColor,
          ),
        ),
        centerTitle: false,
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.045,
            vertical: 10,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // =================================================
                  // HEADER
                  // =================================================

                  Text(
                    'Update your password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _headingTextColor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    googleOnlyAccount
                        ? 'Your account uses Google Sign-In'
                        : 'Make sure your new password is secure',
                    style: TextStyle(
                      fontSize: 14,
                      color: _secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // GOOGLE ACCOUNT MESSAGE
                  // =================================================

                  if (googleOnlyAccount) ...[
                    _GoogleAccountCard(
                      backgroundColor: _googleCardBackground,
                      borderColor: _googleCardBorder,
                      iconBackground: _googleIconBackground,
                      titleColor: _googleTitleColor,
                      descriptionColor: _googleDescriptionColor,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D84A8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Back to Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]

                  // =================================================
                  // NORMAL PASSWORD ACCOUNT
                  // =================================================

                  else ...[
                    // CURRENT PASSWORD

                    _passwordField(
                      controller: currentController,
                      hint: 'Current Password',
                      show: showCurrent,
                      toggle: () {
                        setState(() {
                          showCurrent = !showCurrent;
                          error = null;
                        });
                      },
                    ),

                    // NEW PASSWORD

                    _passwordField(
                      controller: newController,
                      hint: 'New Password',
                      show: showNew,
                      toggle: () {
                        setState(() {
                          showNew = !showNew;
                          error = null;
                        });
                      },
                    ),

                    // CONFIRM PASSWORD

                    _passwordField(
                      controller: confirmController,
                      hint: 'Confirm New Password',
                      show: showConfirm,
                      toggle: () {
                        setState(() {
                          showConfirm = !showConfirm;
                          error = null;
                        });
                      },
                    ),

                    // =================================================
                    // PASSWORD REQUIREMENT
                    // =================================================

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        top: 0,
                        bottom: 4,
                      ),
                      child: Text(
                        'Password must contain at least 6 characters.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ),

                    // =================================================
                    // ERROR
                    // =================================================

                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _errorBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 19,
                              color: Color(0xFFC94C4C),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: _errorTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // =================================================
                    // UPDATE BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D84A8),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF9BBFCC),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback toggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          color: _fieldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
          ),
          boxShadow: [
            if (!_isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: !show,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 16,
          ),
          cursorColor: const Color(0xFF3D84A8),
          onChanged: (_) {
            if (error != null) {
              setState(() {
                error = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 16,
              color: _hintColor,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            isDense: true,
            suffixIcon: IconButton(
              onPressed: isLoading ? null : toggle,
              icon: Icon(
                show
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _iconColor,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// GOOGLE ACCOUNT INFORMATION CARD
// ===========================================================================

class _GoogleAccountCard extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackground;
  final Color titleColor;
  final Color descriptionColor;

  const _GoogleAccountCard({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackground,
    required this.titleColor,
    required this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF3D84A8),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Sign-In account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your password is managed by Google, so it cannot be changed from Medelyra.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: descriptionColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
