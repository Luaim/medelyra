import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;

  String selectedLanguage = 'English';
  String appVersion = '';

  bool isLoggingOut = false;
  bool isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  // ===========================================================================
  // LOAD APP VERSION
  // ===========================================================================

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        appVersion = info.version;
      });
    } catch (e) {
      debugPrint('VERSION LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        appVersion = '1.0.0';
      });
    }
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> _logout() async {
    if (isLoggingOut || isDeletingAccount) return;

    final shouldLogout = await _showLogoutConfirmation();

    if (!shouldLogout) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      // -----------------------------------------------------------------------
      // ACTUALLY SIGN OUT FROM FIREBASE
      // -----------------------------------------------------------------------

      await FirebaseAuth.instance.signOut();

      // -----------------------------------------------------------------------
      // ALSO SIGN OUT FROM GOOGLE IF A GOOGLE ACCOUNT WAS USED
      // -----------------------------------------------------------------------

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        // Google sign-out failure should not prevent Firebase logout.
        debugPrint('GOOGLE SIGN OUT INFO: $e');
      }

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // REMOVE ALL PREVIOUS SCREENS
      // -----------------------------------------------------------------------

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('LOGOUT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Unable to log out. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  // ===========================================================================
  // LOGOUT CONFIRMATION
  // ===========================================================================

  Future<bool> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8F6F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFF3D84A8),
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF292929),
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your Medelyra account?',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF555555),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ===========================================================================
  // DELETE ACCOUNT
  // ===========================================================================

  Future<void> _deleteAccount() async {
    if (isDeletingAccount || isLoggingOut) return;

    // -------------------------------------------------------------------------
    // FIRST CONFIRMATION
    // -------------------------------------------------------------------------

    final firstConfirmation = await _showDeleteWarning();

    if (!firstConfirmation) return;

    // -------------------------------------------------------------------------
    // SECOND CONFIRMATION
    // -------------------------------------------------------------------------

    final secondConfirmation = await _showFinalDeleteConfirmation();

    if (!secondConfirmation) return;

    setState(() {
      isDeletingAccount = true;
    });

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final User? user = auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final String uid = user.uid;

      // -----------------------------------------------------------------------
      // RE-AUTHENTICATE IF FIREBASE REQUIRES RECENT LOGIN
      // -----------------------------------------------------------------------

      await _reauthenticateUserIfNeeded(user);

      // -----------------------------------------------------------------------
      // DELETE USER DATA FROM FIRESTORE
      //
      // The profile document contains account/profile information such as:
      // - name
      // - email
      // - emergency contact information
      //
      // when those values are stored under users/{uid}.
      // -----------------------------------------------------------------------

      await firestore.collection('users').doc(uid).delete();

      // -----------------------------------------------------------------------
      // DELETE FIREBASE AUTHENTICATION ACCOUNT
      // -----------------------------------------------------------------------

      await user.delete();

      // -----------------------------------------------------------------------
      // SIGN OUT LOCALLY
      // -----------------------------------------------------------------------

      await auth.signOut();

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('GOOGLE SIGN OUT AFTER DELETE: $e');
      }

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // SEND USER TO SIGN IN AND REMOVE ALL PREVIOUS ROUTES
      // -----------------------------------------------------------------------

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
      );

      // -----------------------------------------------------------------------
      // SUCCESS MESSAGE
      // -----------------------------------------------------------------------

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        _showMessage(
          'Your Medelyra account has been permanently deleted.',
        );
      });
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('DELETE ACCOUNT FIREBASE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'requires-recent-login':
          message =
              'For your security, please sign in again before deleting your account.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'user-token-expired':
          message =
              'Your session has expired. Please sign in again and try again.';
          break;

        case 'user-not-found':
          message = 'This account no longer exists.';
          break;

        default:
          message =
              e.message ?? 'Unable to delete your account. Please try again.';
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('DELETE ACCOUNT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Unable to delete your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeletingAccount = false;
        });
      }
    }
  }

  // ===========================================================================
  // RE-AUTHENTICATION
  // ===========================================================================

  Future<void> _reauthenticateUserIfNeeded(User user) async {
    try {
      // -----------------------------------------------------------------------
      // TRY TO DELETE LATER.
      //
      // Firebase will tell us if recent authentication is required.
      // However, we cannot call user.delete() here because Firestore data
      // should not be removed before authentication is confirmed.
      //
      // So we check whether the user has a supported provider and perform
      // re-authentication proactively.
      // -----------------------------------------------------------------------

      final providerIds =
          user.providerData.map((provider) => provider.providerId).toList();

      // -----------------------------------------------------------------------
      // GOOGLE ACCOUNT
      // -----------------------------------------------------------------------

      if (providerIds.contains('google.com')) {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        final GoogleSignInAccount? googleUser =
            await googleSignIn.signInSilently();

        final GoogleSignInAccount? account =
            googleUser ?? await googleSignIn.signIn();

        if (account == null) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Google re-authentication was cancelled.',
          );
        }

        final GoogleSignInAuthentication googleAuth =
            await account.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);

        return;
      }

      // -----------------------------------------------------------------------
      // EMAIL / PASSWORD ACCOUNT
      // -----------------------------------------------------------------------

      if (providerIds.contains('password')) {
        final String? password = await _showPasswordDialog();

        if (password == null || password.isEmpty) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Password verification was cancelled.',
          );
        }

        final String email = user.email ?? '';

        if (email.isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-user-token',
            message: 'No email address is associated with this account.',
          );
        }

        final AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        return;
      }

      // -----------------------------------------------------------------------
      // OTHER PROVIDERS
      // -----------------------------------------------------------------------

      debugPrint(
        'No supported re-authentication provider found: $providerIds',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('RE-AUTHENTICATION ERROR: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // PASSWORD DIALOG
  // ===========================================================================

  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();

    bool obscure = true;

    final String? password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF8F6F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF3D84A8),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confirm Your Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For your security, enter your current password to permanently delete your account.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Current password',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF3D84A8),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscure = !obscure;
                          });
                        },
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF3D84A8),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                16,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      passwordController.text,
                    );
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
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    return password;
  }

  // ===========================================================================
  // FIRST DELETE WARNING
  // ===========================================================================

  Future<bool> _showDeleteWarning() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8F6F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC62828),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF292929),
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Deleting your Medelyra account is permanent.\n\n'
            'Your account and the information stored with your profile will be deleted and cannot be recovered.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF555555),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ===========================================================================
  // FINAL DELETE CONFIRMATION
  // ===========================================================================

  Future<bool> _showFinalDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8F6F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Are you absolutely sure?',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF292929),
            ),
          ),
          content: const Text(
            'This is your final confirmation.\n\n'
            'Your Medelyra account will be permanently deleted. This action cannot be undone.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF555555),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Keep My Account',
                style: TextStyle(
                  color: Color(0xFF3D84A8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Delete Permanently',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
    final screenWidth = size.width;
    final screenHeight = size.height;
    final smallScreen = screenHeight < 700;

    final bool busy = isLoggingOut || isDeletingAccount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: busy
              ? null
              : () {
                  Navigator.pop(context);
                },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF222222),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.045,
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
                SizedBox(
                  height: smallScreen ? 4 : 8,
                ),

                // =================================================================
                // ACCOUNT
                // =================================================================

                _sectionTitle('Account'),

                const SizedBox(height: 10),

                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: busy
                      ? () {}
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/edit_profile',
                          );
                        },
                ),

                const SizedBox(height: 12),

                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Keep your account secure',
                  onTap: busy
                      ? () {}
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/edit_password',
                          );
                        },
                ),

                SizedBox(
                  height: smallScreen ? 18 : 22,
                ),

                // =================================================================
                // PREFERENCES
                // =================================================================

                _sectionTitle('Preferences'),

                const SizedBox(height: 10),

                _SwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Switch app appearance',
                  value: darkMode,
                  onChanged: busy
                      ? (_) {}
                      : (value) {
                          setState(() {
                            darkMode = value;
                          });
                        },
                ),

                const SizedBox(height: 12),

                _DropdownTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'Choose app language',
                  value: selectedLanguage,
                  items: const [
                    'English',
                    'Arabic',
                    'Malay',
                  ],
                  onChanged: busy
                      ? (_) {}
                      : (value) {
                          if (value != null) {
                            setState(() {
                              selectedLanguage = value;
                            });
                          }
                        },
                ),

                SizedBox(
                  height: smallScreen ? 18 : 22,
                ),

                // =================================================================
                // MORE
                // =================================================================

                _sectionTitle('More'),

                const SizedBox(height: 10),

                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read how your data is handled',
                  onTap: busy
                      ? () {}
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/privacy',
                          );
                        },
                ),

                const SizedBox(height: 12),

                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help using the app',
                  onTap: busy
                      ? () {}
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/help_support',
                          );
                        },
                ),

                const SizedBox(height: 12),

                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Medelyra',
                  subtitle: 'App version and information',
                  onTap: busy
                      ? () {}
                      : () {
                          _showAboutDialog();
                        },
                ),

                SizedBox(
                  height: smallScreen ? 24 : 30,
                ),

                // =================================================================
                // ACCOUNT ACTIONS
                // =================================================================

                _sectionTitle('Account Actions'),

                const SizedBox(height: 10),

                // -----------------------------------------------------------------
                // DELETE ACCOUNT
                // -----------------------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: busy ? null : _deleteAccount,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF0CACA),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEEE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFC62828),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8E2424),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Permanently delete your account and profile data',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF777777),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: Color(0xFFC62828),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: smallScreen ? 24 : 30,
                ),

                // =================================================================
                // LOGOUT
                // =================================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _logout,
                    icon: isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF6E1E1E),
                            ),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                          ),
                    label: Text(
                      isLoggingOut ? 'Logging Out...' : 'Logout',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4B1B1),
                      disabledBackgroundColor:
                          const Color(0xFFF4B1B1).withOpacity(0.6),
                      foregroundColor: const Color(0xFF6E1E1E),
                      disabledForegroundColor:
                          const Color(0xFF6E1E1E).withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ABOUT MEDELYRA
  // ===========================================================================

  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              22,
              22,
              22,
              18,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F8),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =============================================================
                // APP ICON
                // =============================================================

                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 34,
                    color: Color(0xFF3D84A8),
                  ),
                ),

                const SizedBox(height: 14),

                // =============================================================
                // APP NAME
                // =============================================================

                const Text(
                  'Medelyra',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF292929),
                    fontFamily: 'serif',
                  ),
                ),

                const SizedBox(height: 4),

                // =============================================================
                // VERSION
                // =============================================================

                Text(
                  appVersion.isEmpty ? 'Version 1.0.0' : 'Version $appVersion',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                // =============================================================
                // DESCRIPTION CARD
                // =============================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE4E4E4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Medelyra is a medication management and reminder app '
                    'designed to help users organize their medications, '
                    'reminders, schedules, and health-related information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF505050),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // =============================================================
                // OPEN SOURCE LICENSES
                // =============================================================

                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(dialogContext);

                    showLicensePage(
                      context: context,
                      applicationName: 'Medelyra',
                      applicationVersion:
                          appVersion.isEmpty ? '1.0.0' : appVersion,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          color: Color(0xFF3D84A8),
                          size: 23,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Open Source Licenses',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF303030),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'View licenses for software used by Medelyra',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF777777),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // =============================================================
                // CLOSE
                // =============================================================

                SizedBox(
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
                      shadowColor: Colors.black.withOpacity(0.18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
  // SECTION TITLE
  // ===========================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF333333),
      ),
    );
  }
}

// =============================================================================
// SETTINGS TILE
// =============================================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE3E3E3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3D84A8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF777777),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF9A9A9A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SWITCH TILE
// =============================================================================

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3D84A8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF67C0D7),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DROPDOWN TILE
// =============================================================================

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3D84A8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(14),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
