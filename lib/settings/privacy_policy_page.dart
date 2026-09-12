import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // ===========================================================================
  // LIGHT MODE COLORS
  // ===========================================================================

  static const Color backgroundColor = Color(0xFFF8F6F8);
  static const Color cardColor = Colors.white;
  static const Color primaryBlue = Color.fromARGB(255, 45, 44, 44);
  static const Color darkText = Color(0xFF2B2B2B);
  static const Color bodyText = Color(0xFF555555);
  static const Color secondaryText = Color(0xFF777777);
  static const Color dividerColor = Color(0xFFE6E3E6);

  // ===========================================================================
  // DARK MODE COLORS
  // ===========================================================================

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkInput = Color(0xFF252525);
  static const Color darkBorder = Color(0xFF3A3A3A);

  static const Color darkPrimaryText = Colors.white;
  static const Color darkBodyText = Color(0xFFBDBDBD);
  static const Color darkSecondaryText = Color(0xFF9E9E9E);

  static const Color darkBlueTint = Color(0xFF24343A);
  static const Color darkFooter = Color(0xFF252525);
  static const Color darkFooterText = Color(0xFFBDBDBD);

  static const Color darkAccent = Color(0xFF6FA9C5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBackground = isDark ? darkBackground : backgroundColor;

    final primaryText = isDark ? darkPrimaryText : darkText;

    final bodyTextColor = isDark ? darkBodyText : bodyText;

    final secondaryTextColor = isDark ? darkSecondaryText : secondaryText;

    final accentColor = isDark ? darkAccent : primaryBlue;

    return Scaffold(
      backgroundColor: pageBackground,

      // =========================================================================
      // APP BAR
      // =========================================================================

      appBar: AppBar(
        backgroundColor: pageBackground,
        foregroundColor: primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            size: 26,
            color: primaryText,
          ),
        ),
        title: Text(
          l10n.privacyPolicy,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryText,
            fontFamily: 'serif',
          ),
        ),
      ),

      // =========================================================================
      // BODY
      // =========================================================================

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
                  // =================================================================
                  // PAGE INTRO
                  // =================================================================

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      4,
                      8,
                      4,
                      22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          l10n.privacyLastUpdated,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.privacyIntro,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: bodyTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================================
                  // 1. WHAT WE COLLECT
                  // =================================================================

                  _section(
                    context: context,
                    number: '01',
                    title: l10n.privacyWhatMedelyraCollects,
                    intro: l10n.privacyCollectsIntro,
                    bullets: [
                      l10n.privacyCollectNameEmail,
                      l10n.privacyCollectAccountInfo,
                      l10n.privacyCollectMedication,
                      l10n.privacyCollectReminders,
                      l10n.privacyCollectEmergencyContact,
                      l10n.privacyCollectVoluntaryInfo,
                    ],
                  ),

                  // =================================================================
                  // 2. HOW WE USE IT
                  // =================================================================

                  _section(
                    context: context,
                    number: '02',
                    title: l10n.privacyHowWeUseInformation,
                    intro: l10n.privacyHowWeUseIntro,
                    bullets: [
                      l10n.privacyUseManageAccount,
                      l10n.privacyUseMedication,
                      l10n.privacyUseReminders,
                      l10n.privacyUseEmergencyContact,
                      l10n.privacyUsePersonalizedFeatures,
                      l10n.privacyUseImproveApp,
                      l10n.privacyUseTechnicalSupport,
                    ],
                    footer: l10n.privacyNoSell,
                  ),

                  // =================================================================
                  // 3. HEALTH INFORMATION
                  // =================================================================

                  _section(
                    context: context,
                    number: '03',
                    title: l10n.privacyMedicationHealth,
                    intro: l10n.privacyMedicationHealthIntro,
                    paragraphs: [
                      l10n.privacyHealthParagraph1,
                      l10n.privacyHealthParagraph2,
                      l10n.privacyHealthParagraph3,
                    ],
                  ),

                  // =================================================================
                  // 4. EMERGENCY CONTACTS
                  // =================================================================

                  _section(
                    context: context,
                    number: '04',
                    title: l10n.privacyEmergencyContacts,
                    intro: l10n.privacyEmergencyContactsIntro,
                    paragraphs: [
                      l10n.privacyEmergencyParagraph1,
                      l10n.privacyEmergencyParagraph2,
                    ],
                  ),

                  // =================================================================
                  // 5. DATA STORAGE
                  // =================================================================

                  _section(
                    context: context,
                    number: '05',
                    title: l10n.privacyDataStorageSecurity,
                    intro: l10n.privacyDataStorageIntro,
                    paragraphs: [
                      l10n.privacyDataStorageParagraph1,
                      l10n.privacyDataStorageParagraph2,
                      l10n.privacyDataStorageParagraph3,
                    ],
                  ),

                  // =================================================================
                  // 6. THIRD PARTY
                  // =================================================================

                  _section(
                    context: context,
                    number: '06',
                    title: l10n.privacyThirdPartyServices,
                    intro: l10n.privacyThirdPartyIntro,
                    bullets: [
                      l10n.privacyFirebase,
                      l10n.privacyGoogleServices,
                    ],
                    footer: l10n.privacyThirdPartyFooter,
                  ),

                  // =================================================================
                  // 7. GOOGLE SIGN IN
                  // =================================================================

                  _section(
                    context: context,
                    number: '07',
                    title: l10n.privacyGoogleSignIn,
                    intro: l10n.privacyGoogleSignInIntro,
                    paragraphs: [
                      l10n.privacyGoogleParagraph1,
                      l10n.privacyGoogleParagraph2,
                    ],
                  ),

                  // =================================================================
                  // 8. YOUR CONTROL
                  // =================================================================

                  _section(
                    context: context,
                    number: '08',
                    title: l10n.privacyChoices,
                    intro: l10n.privacyChoicesIntro,
                    bullets: [
                      l10n.privacyChoiceReviewProfile,
                      l10n.privacyChoiceUpdateProfile,
                      l10n.privacyChoiceEmergencyContact,
                      l10n.privacyChoiceMedication,
                      l10n.privacyChoiceDeleteAccount,
                    ],
                    footer: l10n.privacyDeletionFooter,
                  ),

                  // =================================================================
                  // 9. DATA RETENTION
                  // =================================================================

                  _section(
                    context: context,
                    number: '09',
                    title: l10n.privacyDataRetention,
                    intro: l10n.privacyDataRetentionIntro,
                    paragraphs: [
                      l10n.privacyRetentionParagraph1,
                      l10n.privacyRetentionParagraph2,
                    ],
                  ),

                  // =================================================================
                  // 10. CHILDREN
                  // =================================================================

                  _section(
                    context: context,
                    number: '10',
                    title: l10n.privacyChildren,
                    paragraphs: [
                      l10n.privacyChildrenParagraph1,
                      l10n.privacyChildrenParagraph2,
                    ],
                  ),

                  // =================================================================
                  // 11. CHANGES
                  // =================================================================

                  _section(
                    context: context,
                    number: '11',
                    title: l10n.privacyChanges,
                    paragraphs: [
                      l10n.privacyChangesParagraph1,
                      l10n.privacyChangesParagraph2,
                    ],
                  ),

                  // =================================================================
                  // 12. CONTACT
                  // =================================================================

                  _section(
                    context: context,
                    number: '12',
                    title: l10n.privacyContactUs,
                    intro: l10n.privacyContactIntro,
                    email: 'support@Medelyra.app',
                  ),

                  // =================================================================
                  // BOTTOM NOTE
                  // =================================================================

                  const SizedBox(height: 4),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? darkBlueTint : const Color(0xFFEAF4F8),
                      borderRadius: BorderRadius.circular(14),
                      border: isDark
                          ? Border.all(
                              color: const Color(0xFF35545D),
                            )
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 21,
                          color: accentColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.privacyBottomNote,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: isDark
                                  ? darkFooterText
                                  : const Color(0xFF4B5A60),
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

  Widget _section({
    required BuildContext context,
    required String number,
    required String title,
    String? intro,
    List<String>? bullets,
    List<String>? paragraphs,
    String? footer,
    String? email,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sectionCardColor = isDark ? darkCard : cardColor;

    final primaryText = isDark ? darkPrimaryText : darkText;

    final bodyTextColor = isDark ? darkBodyText : bodyText;

    final borderColor = isDark ? darkBorder : dividerColor;

    final accentColor = isDark ? darkAccent : primaryBlue;

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
        color: sectionCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
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
          // ===================================================================
          // NUMBER + TITLE
          // ===================================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? darkBlueTint : const Color(0xFFEAF4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ===================================================================
          // INTRO
          // ===================================================================

          if (intro != null) ...[
            const SizedBox(height: 14),
            Text(
              intro,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: bodyTextColor,
              ),
            ),
          ],

          // ===================================================================
          // PARAGRAPHS
          // ===================================================================

          if (paragraphs != null)
            for (final paragraph in paragraphs) ...[
              const SizedBox(height: 12),
              Text(
                paragraph,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: bodyTextColor,
                ),
              ),
            ],

          // ===================================================================
          // BULLET LIST
          // ===================================================================

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
                      margin: const EdgeInsetsDirectional.only(
                        top: 7,
                        end: 10,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: bodyTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // ===================================================================
          // FOOTER
          // ===================================================================

          if (footer != null) ...[
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.only(
                top: 4,
              ),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark ? darkFooter : const Color(0xFFF7FAFB),
                borderRadius: BorderRadius.circular(10),
                border: isDark
                    ? Border.all(
                        color: const Color(0xFF333333),
                      )
                    : null,
              ),
              child: Text(
                footer,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? darkBodyText : const Color(0xFF555555),
                ),
              ),
            ),
          ],

          // ===================================================================
          // EMAIL
          // ===================================================================

          if (email != null) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? darkBlueTint : const Color(0xFFEAF4F8),
                borderRadius: BorderRadius.circular(10),
                border: isDark
                    ? Border.all(
                        color: const Color(0xFF35545D),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 19,
                    color: accentColor,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
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
