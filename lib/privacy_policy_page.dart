import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'MedMinder Privacy Policy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: 2026',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _section(
              '1. Introduction',
              'MedMinder is designed to help users manage medication and health reminders. '
                  'We respect your privacy and are committed to protecting your personal information.',
            ),
            _section(
              '2. Information We Collect',
              'We may collect the following information:\n\n'
                  '• Personal details (name, email, phone number)\n'
                  '• Health-related information (medications, reminders)\n'
                  '• Emergency contact information\n\n'
                  'We only collect data necessary to provide app functionality.',
            ),
            _section(
              '3. How We Use Your Information',
              'Your information is used to:\n\n'
                  '• Manage your reminders and schedules\n'
                  '• Provide personalized health tracking\n'
                  '• Improve app performance and features\n\n'
                  'We do not sell or share your data with third parties.',
            ),
            _section(
              '4. Data Storage & Security',
              'We take appropriate measures to protect your data. '
                  'Your information is stored securely and only accessible when needed for app functionality.',
            ),
            _section(
              '5. Third-Party Services',
              'MedMinder may use trusted third-party services (such as notifications or analytics) '
                  'to improve the app experience. These services do not access your personal health data.',
            ),
            _section(
              '6. Your Control',
              'You have full control over your data. You can edit or delete your information at any time '
                  'through the app settings.',
            ),
            _section(
              '7. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'support@medminder.app',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 🔥 SECTION WIDGET (CLEAN STYLE)
  Widget _section(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
