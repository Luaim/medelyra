import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medelyra/services/theme_service.dart';
import 'package:medelyra/services/language_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeService _themeService = ThemeService.instance;
  final LanguageService _languageService = LanguageService.instance;

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
      await FirebaseAuth.instance.signOut();

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('GOOGLE SIGN OUT INFO: $e');
      }

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('LOGOUT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      _showMessage(
        l10n.unableToLogOut,
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
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(dialogContext)!;

        return AlertDialog(
          backgroundColor:
              dark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F6F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFF3D84A8),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.logOut,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF292929),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.areYouSureLogout,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: dark ? const Color(0xFFBDBDBD) : const Color(0xFF555555),
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
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color:
                      dark ? const Color(0xFFBDBDBD) : const Color(0xFF666666),
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
              child: Text(
                l10n.logOut,
                style: const TextStyle(
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

    final firstConfirmation = await _showDeleteWarning();

    if (!firstConfirmation) return;

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

      await _reauthenticateUserIfNeeded(user);

      await firestore.collection('users').doc(uid).delete();

      await user.delete();

      await auth.signOut();

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('GOOGLE SIGN OUT AFTER DELETE: $e');
      }

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        final l10n = AppLocalizations.of(context)!;

        _showMessage(
          l10n.accountDeleted,
        );
      });
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('DELETE ACCOUNT FIREBASE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      String message;

      switch (e.code) {
        case 'requires-recent-login':
          message = l10n.securityRecentLogin;
          break;

        case 'network-request-failed':
          message = l10n.checkInternet;
          break;

        case 'user-token-expired':
          message = l10n.sessionExpired;
          break;

        case 'user-not-found':
          message = l10n.accountNoLongerExists;
          break;

        default:
          message = e.message ?? l10n.unableToDeleteAccount;
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('DELETE ACCOUNT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      _showMessage(
        l10n.unableToDeleteAccount,
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
      final providerIds =
          user.providerData.map((provider) => provider.providerId).toList();

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
            final dark = Theme.of(context).brightness == Brightness.dark;
            final l10n = AppLocalizations.of(context)!;

            return AlertDialog(
              backgroundColor:
                  dark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F6F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF3D84A8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.confirmYourPassword,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF292929),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.enterCurrentPassword,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: dark
                          ? const Color(0xFFBDBDBD)
                          : const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    style: TextStyle(
                      color: dark ? Colors.white : const Color(0xFF292929),
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.currentPassword,
                      hintStyle: TextStyle(
                        color: dark
                            ? const Color(0xFF888888)
                            : const Color(0xFF777777),
                      ),
                      filled: true,
                      fillColor: dark ? const Color(0xFF292929) : Colors.white,
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
                          color: dark
                              ? const Color(0xFFBDBDBD)
                              : const Color(0xFF666666),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE0E0E0),
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
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFBDBDBD)
                          : const Color(0xFF666666),
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
                  child: Text(
                    l10n.continueText,
                    style: const TextStyle(
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
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(dialogContext)!;

        return AlertDialog(
          backgroundColor:
              dark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F6F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC62828),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.deleteAccount,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF292929),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '${l10n.deleteAccountWarning}\n\n'
            '${l10n.deleteAccountWarningDetails}',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: dark ? const Color(0xFFBDBDBD) : const Color(0xFF555555),
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
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color:
                      dark ? const Color(0xFFBDBDBD) : const Color(0xFF666666),
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
              child: Text(
                l10n.continueText,
                style: const TextStyle(
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
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(dialogContext)!;

        return AlertDialog(
          backgroundColor:
              dark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F6F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            l10n.areYouAbsolutelySure,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF292929),
            ),
          ),
          content: Text(
            '${l10n.finalDeleteConfirmation}\n\n'
            '${l10n.deleteAccountFinalDetails}',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: dark ? const Color(0xFFBDBDBD) : const Color(0xFF555555),
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
              child: Text(
                l10n.keepMyAccount,
                style: const TextStyle(
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
              child: Text(
                l10n.deletePermanently,
                style: const TextStyle(
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

    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final bool busy = isLoggingOut || isDeletingAccount;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor:
            dark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: busy
              ? null
              : () {
                  Navigator.pop(context);
                },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: dark ? Colors.white : const Color(0xFF222222),
          ),
        ),
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xFF222222),
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

                // ACCOUNT
                _sectionTitle(l10n.account),

                const SizedBox(height: 10),

                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: l10n.editProfile,
                  subtitle: l10n.updatePersonalInformation,
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
                  title: l10n.changePassword,
                  subtitle: l10n.keepAccountSecure,
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

                // PREFERENCES
                _sectionTitle(l10n.preferences),

                const SizedBox(height: 10),

                _SwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.darkMode,
                  subtitle: l10n.switchAppAppearance,
                  value: _themeService.isDarkMode,
                  onChanged: busy
                      ? (_) {}
                      : (value) async {
                          await _themeService.setDarkMode(value);
                        },
                ),

                const SizedBox(height: 12),

                _DropdownTile(
                  icon: Icons.language_rounded,
                  title: l10n.language,
                  subtitle: l10n.chooseAppLanguage,
                  value: _languageService.isArabic ? l10n.arabic : l10n.english,
                  items: [
                    l10n.english,
                    l10n.arabic,
                  ],
                  onChanged: busy
                      ? (_) {}
                      : (value) async {
                          if (value == null) return;

                          final languageCode =
                              value == l10n.arabic ? 'ar' : 'en';

                          await _languageService.setLanguage(languageCode);
                        },
                ),

                SizedBox(
                  height: smallScreen ? 18 : 22,
                ),

                // MORE
                _sectionTitle(l10n.more),

                const SizedBox(height: 10),

                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  subtitle: l10n.readHowDataHandled,
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
                  title: l10n.helpSupport,
                  subtitle: l10n.getHelpUsingApp,
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
                  title: l10n.aboutMedelyra,
                  subtitle: l10n.appVersionInformation,
                  onTap: busy
                      ? () {}
                      : () {
                          _showAboutDialog();
                        },
                ),

                SizedBox(
                  height: smallScreen ? 24 : 30,
                ),

                // ACCOUNT ACTIONS
                _sectionTitle(l10n.accountActions),

                const SizedBox(height: 10),

                // DELETE ACCOUNT
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: dark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: busy ? null : _deleteAccount,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dark
                                ? const Color(0xFF5A2929)
                                : const Color(0xFFF0CACA),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                dark ? 0.18 : 0.03,
                              ),
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
                                color: dark
                                    ? const Color(0xFF351E1E)
                                    : const Color(0xFFFFEEEE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFC62828),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.deleteAccount,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: dark
                                          ? const Color(0xFFFF8A8A)
                                          : const Color(0xFF8E2424),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.deleteAccountDescription,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: dark
                                          ? const Color(0xFFB0B0B0)
                                          : const Color(0xFF777777),
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

                // LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _logout,
                    icon: isLoggingOut
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: dark
                                  ? const Color(0xFFFFB4B4)
                                  : const Color(0xFF6E1E1E),
                            ),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                          ),
                    label: Text(
                      isLoggingOut ? l10n.loggingOut : l10n.logout,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark
                          ? const Color(0xFF4A2525)
                          : const Color(0xFFF4B1B1),
                      disabledBackgroundColor: dark
                          ? const Color(0xFF3A2222)
                          : const Color(0xFFF4B1B1).withOpacity(0.6),
                      foregroundColor: dark
                          ? const Color(0xFFFFB4B4)
                          : const Color(0xFF6E1E1E),
                      disabledForegroundColor: dark
                          ? const Color(0xFF9A6A6A)
                          : const Color(0xFF6E1E1E).withOpacity(0.6),
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
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(dialogContext)!;

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
              color: dark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F6F8),
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
                // APP ICON
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF20343A)
                        : const Color(0xFFEAF6FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 34,
                    color: Color(0xFF3D84A8),
                  ),
                ),

                const SizedBox(height: 14),

                // APP NAME
                Text(
                  l10n.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF292929),
                    fontFamily: 'serif',
                  ),
                ),

                const SizedBox(height: 4),

                // VERSION
                Text(
                  l10n.version(
                    appVersion.isEmpty ? '1.0.0' : appVersion,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: dark
                        ? const Color(0xFF999999)
                        : const Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                // DESCRIPTION CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF292929) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE4E4E4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    l10n.medelyraAboutDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: dark
                          ? const Color(0xFFD0D0D0)
                          : const Color(0xFF505050),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // OPEN SOURCE LICENSES
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(dialogContext);

                    showLicensePage(
                      context: context,
                      applicationName: l10n.appName,
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
                      color: dark
                          ? const Color(0xFF20343A)
                          : const Color(0xFFEAF6FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          color: Color(0xFF3D84A8),
                          size: 23,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.openSourceLicenses,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? Colors.white
                                      : const Color(0xFF303030),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.viewLicenses,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark
                                      ? const Color(0xFFB0B0B0)
                                      : const Color(0xFF777777),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: dark
                              ? const Color(0xFFB0B0B0)
                              : const Color(0xFF777777),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // CLOSE
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
                    child: Text(
                      l10n.close,
                      style: const TextStyle(
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: dark ? const Color(0xFFE0E0E0) : const Color(0xFF333333),
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: dark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? const Color(0xFF303030) : const Color(0xFFE3E3E3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  dark ? 0.18 : 0.03,
                ),
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
                  color:
                      dark ? const Color(0xFF20343A) : const Color(0xFFEAF6FA),
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: dark
                            ? const Color(0xFFB0B0B0)
                            : const Color(0xFF777777),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: dark ? const Color(0xFF888888) : const Color(0xFF9A9A9A),
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF303030) : const Color(0xFFE3E3E3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              dark ? 0.18 : 0.03,
            ),
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
              color: dark ? const Color(0xFF20343A) : const Color(0xFFEAF6FA),
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: dark
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF777777),
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
            inactiveTrackColor: dark ? const Color(0xFF555555) : Colors.grey,
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF303030) : const Color(0xFFE3E3E3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              dark ? 0.18 : 0.03,
            ),
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
              color: dark ? const Color(0xFF20343A) : const Color(0xFFEAF6FA),
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: dark
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF777777),
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
            dropdownColor: dark ? const Color(0xFF292929) : Colors.white,
            iconEnabledColor:
                dark ? const Color(0xFFBDBDBD) : const Color(0xFF555555),
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF555555),
              fontSize: 14,
            ),
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
