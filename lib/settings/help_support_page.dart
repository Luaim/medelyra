import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? expandedIndex;

  static const Color primaryBlue = Color(0xFF3D84A8);
  static const Color darkBlue = Color(0xFF2F6F8F);
  static const Color backgroundColor = Color(0xFFF8F6F8);
  static const Color darkText = Color(0xFF292929);
  static const Color secondaryText = Color(0xFF666666);
  static const Color lightBlue = Color(0xFFEAF4F8);

  final List<Map<String, dynamic>> faqs = [
    {
      'q': 'How do I create a MedMinder account?',
      'a':
          'You can create an account using your email and password or continue with Google. You must agree to the Terms & Conditions before creating an account.',
      'icon': Icons.person_add_alt_1_outlined,
    },
    {
      'q': 'How do I add a medicine reminder?',
      'a':
          'Open the medication or reminder section of MedMinder, choose the option to add a reminder, enter the required medication and schedule information, then save it.',
      'icon': Icons.medication_outlined,
    },
    {
      'q': 'Will I receive medication reminders?',
      'a':
          'MedMinder can provide reminders based on the medication schedules you create. Make sure notifications are enabled for MedMinder in your device settings.',
      'icon': Icons.notifications_none_outlined,
    },
    {
      'q': 'How do I edit my profile?',
      'a':
          'Open your profile and use the available profile options to update your personal information. You can also manage your emergency contact information there.',
      'icon': Icons.manage_accounts_outlined,
    },
    {
      'q': 'How do I add an emergency contact?',
      'a':
          'Open your profile and add your emergency contact information. The emergency contact information you provide is stored as part of your MedMinder profile.',
      'icon': Icons.contact_emergency_outlined,
    },
    {
      'q': 'How do I edit or delete a reminder?',
      'a':
          'Open your reminder list and select the reminder you want to manage. From there, use the available options to update or remove the reminder.',
      'icon': Icons.edit_calendar_outlined,
    },
    {
      'q': 'I forgot my password. What should I do?',
      'a':
          'On the Sign In page, select "Forgot Password?" and follow the instructions to reset your password.',
      'icon': Icons.lock_reset_outlined,
    },
    {
      'q': 'How do I update my medication information?',
      'a':
          'Open the medication information you want to change and edit the available details. Save your changes when you are finished.',
      'icon': Icons.edit_note_outlined,
    },
  ];

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
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: darkText,
            fontFamily: 'serif',
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 25,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      // =====================================================================
      // BODY
      // =====================================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            width * 0.045,
            8,
            width * 0.045,
            30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================================================
                  // HERO
                  // ===========================================================

                  _buildHeroCard(),

                  const SizedBox(height: 26),

                  // ===========================================================
                  // FAQ HEADER
                  // ===========================================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Common Questions',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quick answers to help you use MedMinder.',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Small FAQ indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${faqs.length} topics',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // ===========================================================
                  // FAQ LIST
                  // ===========================================================

                  ...List.generate(
                    faqs.length,
                    (index) {
                      return _buildFaqCard(
                        index: index,
                        question: faqs[index]['q'] as String,
                        answer: faqs[index]['a'] as String,
                        icon: faqs[index]['icon'] as IconData,
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // ===========================================================
                  // SUPPORT CARD
                  // ===========================================================

                  _buildSupportCard(),

                  const SizedBox(height: 18),

                  // ===========================================================
                  // APP INFORMATION
                  // ===========================================================

                  Center(
                    child: Column(
                      children: [
                        Text(
                          'MedMinder',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Medication reminders made simple.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
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

  // ===========================================================================
  // HERO CARD
  // ===========================================================================

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF4F8),
            Color(0xFFF5F9FB),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD7E8EE),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 16),

          // Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Find answers to common questions or get in touch with our support team.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FAQ CARD
  // ===========================================================================

  Widget _buildFaqCard({
    required int index,
    required String question,
    required String answer,
    required IconData icon,
  }) {
    final bool isOpen = expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isOpen ? const Color(0xFFC9E0E9) : const Color(0xFFE9E6E9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isOpen ? 0.07 : 0.035,
            ),
            blurRadius: isOpen ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () {
            setState(() {
              expandedIndex = isOpen ? null : index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // -------------------------------------------------------------
                // QUESTION ROW
                // -------------------------------------------------------------

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Question icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isOpen ? primaryBlue : const Color(0xFFEAF4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 21,
                        color: isOpen ? Colors.white : darkBlue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Question
                    Expanded(
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Arrow
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),

                // -------------------------------------------------------------
                // ANSWER
                // -------------------------------------------------------------

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: isOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(
                      left: 52,
                      right: 8,
                      top: 13,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        answer,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          color: secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SUPPORT CARD
  // ===========================================================================

  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2F6F8F),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------------
          // HEADER
          // ---------------------------------------------------------------

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Need more help?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          const Text(
            'If you cannot find what you are looking for, you can contact the MedMinder support team.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------------------
          // EMAIL
          // ---------------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'support@medminder.app',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy email',
                  visualDensity: VisualDensity.compact,
                  onPressed: _copySupportEmail,
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: Colors.white70,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ---------------------------------------------------------------
          // CONTACT BUTTON
          // ---------------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _showContactDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: darkBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COPY SUPPORT EMAIL
  // ===========================================================================

  void _copySupportEmail() {
    Clipboard.setData(
      const ClipboardData(
        text: 'support@medminder.app',
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Support email copied to clipboard.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  // ===========================================================================
  // CONTACT DIALOG
  // ===========================================================================

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -----------------------------------------------------------
                // ICON
                // -----------------------------------------------------------

                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 30,
                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 15),

                // -----------------------------------------------------------
                // TITLE
                // -----------------------------------------------------------

                const Text(
                  'Contact MedMinder Support',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'For account, reminder, notification, or technical questions, contact us at:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 15),

                // -----------------------------------------------------------
                // EMAIL
                // -----------------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'support@medminder.app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // -----------------------------------------------------------
                // COPY BUTTON
                // -----------------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: 'support@medminder.app',
                        ),
                      );

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Support email copied to clipboard.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Copy Email Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // -----------------------------------------------------------
                // CLOSE
                // -----------------------------------------------------------

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 14,
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
}
