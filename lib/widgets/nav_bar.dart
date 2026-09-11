import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const accent = Color(0xFF2D6AE3);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final navBorder =
        isDark ? const Color(0xFF333333) : const Color(0xFFE3EAF5);

    final inactiveColor =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF6B7280);

    final selectedBackground =
        isDark ? const Color(0xFF24334D) : const Color(0xFFE8F0FF);

    final items = [
      _NavItem(
        icon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      _NavItem(
        icon: Icons.alarm_outlined,
        label: l10n.navReminders,
      ),
      _NavItem(
        icon: Icons.health_and_safety_outlined,
        label: l10n.navHealth,
      ),
      _NavItem(
        icon: Icons.medical_services_outlined,
        label: l10n.navSos,
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        label: l10n.navProfile,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: navBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: navBorder,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(14),
                    splashColor: accent.withOpacity(0.15),
                    highlightColor: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.10 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: isSelected ? accent : inactiveColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? accent : inactiveColor,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}
