import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final TextEditingController currentController = TextEditingController();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  bool isLoading = false;
  String? error;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  // ============================================================
  // AUTHENTICATION CHECK
  // ============================================================

  bool get hasPasswordProvider {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

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
        error = _l10n.sessionExpired;
      });
      return;
    }

    // ------------------------------------------------------------
    // GOOGLE / NON-PASSWORD ACCOUNT
    // ------------------------------------------------------------

    if (!hasPasswordProvider) {
      setState(() {
        error = isGoogleAccount
            ? _l10n.googlePasswordManaged
            : _l10n.noPasswordToChange;
      });
      return;
    }

    // ------------------------------------------------------------
    // GET VALUES
    // ------------------------------------------------------------

    // Do NOT trim passwords.
    final currentPassword = currentController.text;
    final newPassword = newController.text;
    final confirmPassword = confirmController.text;

    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    if (currentPassword.isEmpty) {
      setState(() {
        error = _l10n.pleaseEnterCurrentPassword;
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        error = _l10n.pleaseEnterNewPassword;
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        error = _l10n.pleaseConfirmNewPassword;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        error = _l10n.newPasswordMinLength;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        error = _l10n.passwordsDoNotMatch;
      });
      return;
    }

    if (currentPassword == newPassword) {
      setState(() {
        error = _l10n.newPasswordMustBeDifferent;
      });
      return;
    }

    if (user.email == null || user.email!.isEmpty) {
      setState(() {
        error = _l10n.unableToUpdatePassword;
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
          SnackBar(
            content: Text(
              _l10n.passwordUpdatedSuccessfully,
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
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
          message = _l10n.currentPasswordIncorrect;
          break;

        case 'weak-password':
          message = _l10n.newPasswordTooWeak;
          break;

        case 'requires-recent-login':
          message = _l10n.securityRecentLogin;
          break;

        case 'network-request-failed':
          message = _l10n.checkInternet;
          break;

        case 'too-many-requests':
          message = _l10n.tooManyAttempts;
          break;

        case 'user-disabled':
          message = _l10n.accountDisabled;
          break;

        case 'user-not-found':
          message = _l10n.accountNoLongerExists;
          break;

        default:
          message = e.message ?? _l10n.unableToUpdatePassword;
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
        error = _l10n.somethingWentWrong;
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
          _l10n.changePassword,
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
                    _l10n.updateYourPassword,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _headingTextColor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    googleOnlyAccount
                        ? _l10n.accountUsesGoogleSignIn
                        : _l10n.makeNewPasswordSecure,
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
                        child: Text(
                          _l10n.backToSettings,
                          style: const TextStyle(
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
                    _passwordField(
                      controller: currentController,
                      hint: _l10n.currentPassword,
                      show: showCurrent,
                      toggle: () {
                        setState(() {
                          showCurrent = !showCurrent;
                          error = null;
                        });
                      },
                    ),

                    _passwordField(
                      controller: newController,
                      hint: _l10n.newPassword,
                      show: showNew,
                      toggle: () {
                        setState(() {
                          showNew = !showNew;
                          error = null;
                        });
                      },
                    ),

                    _passwordField(
                      controller: confirmController,
                      hint: _l10n.confirmNewPassword,
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
                        _l10n.passwordMinSixCharacters,
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
                            : Text(
                                _l10n.updatePassword,
                                style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.googleSignInAccount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.googlePasswordDescription,
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
