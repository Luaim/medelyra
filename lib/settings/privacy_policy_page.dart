import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // ===========================================================================
  // COLORS
  // ===========================================================================

  static const Color backgroundColor = Color(0xFFF8F6F8);
  static const Color cardColor = Colors.white;
  static const Color primaryBlue = Color.fromARGB(255, 45, 44, 44);
  static const Color darkText = Color(0xFF2B2B2B);
  static const Color bodyText = Color(0xFF555555);
  static const Color secondaryText = Color(0xFF777777);
  static const Color dividerColor = Color(0xFFE6E3E6);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,

      // =====================================================================
      // APP BAR
      // =====================================================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            size: 26,
            color: darkText,
          ),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkText,
            fontFamily: 'serif',
          ),
        ),
      ),

      // =====================================================================
      // BODY
      // =====================================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.045,
            vertical: 6,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================================================
                  // PAGE INTRO
                  // ===========================================================

                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      4,
                      8,
                      4,
                      22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        Text(
                          'Last updated: August 2026',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryText,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your privacy matters to us. This policy explains '
                          'what information Medelyra collects, how it is used, '
                          'and how you can control your information.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===========================================================
                  // 1. WHAT WE COLLECT
                  // ===========================================================

                  _section(
                    number: '01',
                    title: 'What Medelyra Collects',
                    intro: 'Depending on how you use the application, Medelyra '
                        'may store information that you choose to provide.',
                    bullets: const [
                      'Your name and email address',
                      'Account and authentication information',
                      'Medication information you enter',
                      'Medication reminders and schedules you create',
                      'Emergency contact information you add to your profile',
                      'Other information you voluntarily provide through the app',
                    ],
                  ),

                  // ===========================================================
                  // 2. HOW WE USE IT
                  // ===========================================================

                  _section(
                    number: '02',
                    title: 'How We Use Your Information',
                    intro: 'The information you provide helps Medelyra provide '
                        'its core features and keep your account working.',
                    bullets: const [
                      'Create and manage your Medelyra account',
                      'Store and display your medication information',
                      'Provide medication reminders and schedules',
                      'Store and display emergency contact information',
                      'Provide personalized app features',
                      'Maintain and improve the application',
                      'Help resolve technical problems and support requests',
                    ],
                    footer: 'We do not sell your personal information.',
                  ),

                  // ===========================================================
                  // 3. HEALTH INFORMATION
                  // ===========================================================

                  _section(
                    number: '03',
                    title: 'Medication & Health Information',
                    intro: 'Medelyra allows you to enter medication, reminder, '
                        'and other health-related information.',
                    paragraphs: const [
                      'This information is provided voluntarily by you and is '
                          'used to support the features of the application.',
                      'Medelyra is not a doctor, pharmacist, hospital, or '
                          'healthcare provider. The application does not replace '
                          'professional medical advice, diagnosis, or treatment.',
                      'Always follow the instructions provided by your qualified '
                          'healthcare professional.',
                    ],
                  ),

                  // ===========================================================
                  // 4. EMERGENCY CONTACTS
                  // ===========================================================

                  _section(
                    number: '04',
                    title: 'Emergency Contacts',
                    intro: 'Medelyra allows you to optionally add an emergency '
                        'contact to your profile.',
                    paragraphs: const [
                      'The emergency contact information you provide is stored '
                          'so that Medelyra can support its related profile '
                          'and emergency-contact features.',
                      'Please make sure you have the appropriate permission '
                          'before adding another person’s information to the app.',
                    ],
                  ),

                  // ===========================================================
                  // 5. DATA STORAGE
                  // ===========================================================

                  _section(
                    number: '05',
                    title: 'Data Storage & Security',
                    intro: 'Medelyra uses Firebase services to support account '
                        'authentication and application data storage.',
                    paragraphs: const [
                      'Information associated with your account may be stored '
                          'in cloud-based services used by the application.',
                      'We take reasonable measures to protect your information '
                          'from unauthorized access, alteration, disclosure, '
                          'or loss.',
                      'However, no electronic storage or transmission method '
                          'can be guaranteed to be completely secure.',
                    ],
                  ),

                  // ===========================================================
                  // 6. THIRD PARTY
                  // ===========================================================

                  _section(
                    number: '06',
                    title: 'Third-Party Services',
                    intro: 'Medelyra may use trusted third-party services to '
                        'provide certain application features.',
                    bullets: const [
                      'Firebase for authentication and data storage',
                      'Google services for optional Google Sign-In',
                    ],
                    footer:
                        'These services may process information when necessary '
                        'to provide their functionality. Their use of information '
                        'may also be governed by their own privacy policies.',
                  ),

                  // ===========================================================
                  // 7. GOOGLE SIGN IN
                  // ===========================================================

                  _section(
                    number: '07',
                    title: 'Google Sign-In',
                    intro:
                        'Google Sign-In is an optional way to create or access '
                        'your Medelyra account.',
                    paragraphs: const [
                      'When you choose Google Sign-In, Google may provide '
                          'information such as your name and email address to '
                          'Medelyra as part of the authentication process.',
                      'You can use email and password authentication instead '
                          'if you do not want to use Google Sign-In.',
                    ],
                  ),

                  // ===========================================================
                  // 8. YOUR CONTROL
                  // ===========================================================

                  _section(
                    number: '08',
                    title: 'Your Privacy Choices',
                    intro: 'You have control over the information you provide '
                        'through Medelyra.',
                    bullets: const [
                      'Review your profile information',
                      'Update information stored in your profile',
                      'Update or manage your emergency contact information',
                      'Manage your medication and reminder information',
                      'Request deletion of your account and associated information',
                    ],
                    footer: 'Account deletion functionality will be available '
                        'through the appropriate account or settings options.',
                  ),

                  // ===========================================================
                  // 9. DATA RETENTION
                  // ===========================================================

                  _section(
                    number: '09',
                    title: 'Data Retention',
                    intro: 'We retain information for as long as necessary to '
                        'provide Medelyra and maintain its features.',
                    paragraphs: const [
                      'When you request account deletion, information associated '
                          'with your account will be deleted according to the '
                          'application’s account deletion process.',
                      'Some information may need to be retained for legitimate '
                          'technical, security, or legal purposes where required.',
                    ],
                  ),

                  // ===========================================================
                  // 10. CHILDREN
                  // ===========================================================

                  _section(
                    number: '10',
                    title: 'Children’s Privacy',
                    paragraphs: const [
                      'Medelyra is not intended to knowingly collect personal '
                          'information from children without appropriate '
                          'authorization.',
                      'If you believe that a child has provided personal '
                          'information through the application without appropriate '
                          'permission, please contact us so we can review the situation.',
                    ],
                  ),

                  // ===========================================================
                  // 11. CHANGES
                  // ===========================================================

                  _section(
                    number: '11',
                    title: 'Changes to This Policy',
                    paragraphs: const [
                      'This Privacy Policy may be updated from time to time as '
                          'Medelyra develops new features or privacy requirements '
                          'change.',
                      'When significant changes are made, the updated policy '
                          'will be made available through the application.',
                    ],
                  ),

                  // ===========================================================
                  // 12. CONTACT
                  // ===========================================================

                  _section(
                    number: '12',
                    title: 'Contact Us',
                    intro: 'If you have questions, concerns, or requests about '
                        'this Privacy Policy or your information, contact us at:',
                    email: 'support@Medelyra.app',
                  ),

                  // ===========================================================
                  // BOTTOM NOTE
                  // ===========================================================

                  const SizedBox(height: 4),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 21,
                          color: primaryBlue,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This Privacy Policy is intended to explain how '
                            'Medelyra handles information within the application.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Color(0xFF4B5A60),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION CARD
  // ===========================================================================

  static Widget _section({
    required String number,
    required String title,
    String? intro,
    List<String>? bullets,
    List<String>? paragraphs,
    String? footer,
    String? email,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(
        17,
        17,
        17,
        17,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // NUMBER + TITLE
          // -------------------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // INTRO
          // -------------------------------------------------------------------

          if (intro != null) ...[
            const SizedBox(height: 14),
            Text(
              intro,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: bodyText,
              ),
            ),
          ],

          // -------------------------------------------------------------------
          // PARAGRAPHS
          // -------------------------------------------------------------------

          if (paragraphs != null)
            for (final paragraph in paragraphs) ...[
              const SizedBox(height: 12),
              Text(
                paragraph,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: bodyText,
                ),
              ),
            ],

          // -------------------------------------------------------------------
          // BULLET LIST
          // -------------------------------------------------------------------

          if (bullets != null) ...[
            const SizedBox(height: 10),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 9,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(
                        top: 7,
                        right: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // -------------------------------------------------------------------
          // FOOTER
          // -------------------------------------------------------------------

          if (footer != null) ...[
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.only(
                top: 4,
              ),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                footer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ],

          // -------------------------------------------------------------------
          // EMAIL
          // -------------------------------------------------------------------

          if (email != null) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 19,
                    color: primaryBlue,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
