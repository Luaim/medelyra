import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  bool isLoading = false;

  String? error;

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

    final currentPassword = currentController.text.trim();
    final newPassword = newController.text.trim();
    final confirmPassword = confirmController.text.trim();

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

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        error = 'Your session has expired. Please sign in again.';
      });
      return;
    }

    if (user.email == null || user.email!.isEmpty) {
      setState(() {
        error = 'Unable to update your password for this account.';
      });
      return;
    }

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

      // Clear fields after successful update.
      currentController.clear();
      newController.clear();
      confirmController.clear();

      setState(() {
        isLoading = false;
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

      // Give the user a moment to see the success message,
      // then return to Settings.
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

        default:
          message = e.message ?? 'Unable to update your password.';
      }

      setState(() {
        isLoading = false;
        error = message;
      });
    } catch (e) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Update your password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Make sure your new password is secure',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CURRENT PASSWORD
              // ==================================================

              _passwordField(
                controller: currentController,
                hint: 'Current Password',
                show: showCurrent,
                toggle: () {
                  setState(() {
                    showCurrent = !showCurrent;
                  });
                },
              ),

              // ==================================================
              // NEW PASSWORD
              // ==================================================

              _passwordField(
                controller: newController,
                hint: 'New Password',
                show: showNew,
                toggle: () {
                  setState(() {
                    showNew = !showNew;
                  });
                },
              ),

              // ==================================================
              // CONFIRM PASSWORD
              // ==================================================

              _passwordField(
                controller: confirmController,
                hint: 'Confirm New Password',
                show: showConfirm,
                toggle: () {
                  setState(() {
                    showConfirm = !showConfirm;
                  });
                },
              ),

              // ==================================================
              // ERROR
              // ==================================================

              if (error != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // ==================================================
              // UPDATE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D84A8),
                    disabledBackgroundColor:
                        const Color(0xFF3D84A8).withOpacity(0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.grey,
            ),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: isLoading ? null : toggle,
            ),
          ),
        ),
      ),
    );
  }
}
