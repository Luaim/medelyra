import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/nav_bar.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/reminder');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/health-tools');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/sos');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ============================================================
    // THEME COLORS
    // ============================================================

    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

    final titleColor = isDark ? Colors.white : const Color(0xFF2D2D2D);

    final subtitleColor = isDark ? const Color(0xFFB8B8B8) : Colors.grey;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final optionCardColor =
        isDark ? const Color(0xFF202124) : const Color(0xFFEAF6F8);

    final iconContainerColor = isDark ? const Color(0xFF252525) : Colors.white;

    final helperBackgroundColor =
        isDark ? const Color(0xFF1D2938) : const Color(0xFFEAF2FF);

    final helperTextColor =
        isDark ? const Color(0xFFD0D0D0) : const Color(0xFF4A4A4A);

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.20)
        : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1,
        onTap: (index) => _onBottomTap(
          context,
          index,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // TITLE
                  // ==================================================

                  Text(
                    l10n.reminders,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    l10n.manageMedicineAndAppointments,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ==================================================
                  // PILL REMINDER
                  // ==================================================

                  _ReminderOptionCard(
                    title: l10n.pillReminder,
                    subtitle: l10n.trackDailyMedications,
                    imagePath: 'assets/pillReminder.png',
                    fallbackIcon: Icons.medication_rounded,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pillReminder',
                      );
                    },
                    cardColor: optionCardColor,
                    iconContainerColor: iconContainerColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    shadowColor: shadowColor,
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // APPOINTMENT REMINDER
                  // ==================================================

                  _ReminderOptionCard(
                    title: l10n.appointmentReminder,
                    subtitle: l10n.neverMissDoctorVisits,
                    imagePath: 'assets/appointmentReminder.png',
                    fallbackIcon: Icons.calendar_month_rounded,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/appointmentReminder',
                      );
                    },
                    cardColor: optionCardColor,
                    iconContainerColor: iconContainerColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    shadowColor: shadowColor,
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // VIEW MY REMINDERS
                  // ==================================================

                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/manageReminders',
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.list_alt,
                            color: Color(0xFF3D84A8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.viewMyReminders,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFBDBDBD)
                                : const Color(0xFF555555),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // HELPER / TIP
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: helperBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF3D84A8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.reminderTip,
                            style: TextStyle(
                              fontSize: 13,
                              color: helperTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// REMINDER OPTION CARD
// ================================================================

class _ReminderOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData fallbackIcon;
  final VoidCallback onPressed;

  final Color cardColor;
  final Color iconContainerColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color shadowColor;

  const _ReminderOptionCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.fallbackIcon,
    required this.onPressed,
    required this.cardColor,
    required this.iconContainerColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // ========================================================
            // ICON
            // ========================================================

            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    size: 32,
                    color: const Color(0xFF3D84A8),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // ========================================================
            // TEXT
            // ========================================================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ========================================================
            // ADD BUTTON
            // ========================================================

            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF3D84A8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
