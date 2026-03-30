import 'package:flutter/material.dart';

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

  String? error;

  void _save() {
    if (newController.text != confirmController.text) {
      setState(() {
        error = 'Passwords do not match';
      });
      return;
    }

    setState(() => error = null);

    /// later: save password
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

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
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// CURRENT PASSWORD
            _passwordField(
              controller: currentController,
              hint: 'Current Password',
              show: showCurrent,
              toggle: () => setState(() => showCurrent = !showCurrent),
            ),

            /// NEW PASSWORD
            _passwordField(
              controller: newController,
              hint: 'New Password',
              show: showNew,
              toggle: () => setState(() => showNew = !showNew),
            ),

            /// CONFIRM PASSWORD
            _passwordField(
              controller: confirmController,
              hint: 'Confirm New Password',
              show: showConfirm,
              toggle: () => setState(() => showConfirm = !showConfirm),
            ),

            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 30),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D84A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// PASSWORD FIELD
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: !show,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: toggle,
            ),
          ),
        ),
      ),
    );
  }
}
