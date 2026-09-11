import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================

  bool masterToggle = true;

  bool medicineReminder = true;
  bool medicineSound = true;
  bool medicineVibration = true;

  bool appointmentReminder = true;

  // Stored as stable internal values so localization does not
  // break the DropdownButton.
  //
  // 30m = 30 minutes
  // 1h  = 1 hour
  // 2h  = 2 hours
  // 1d  = 1 day
  String reminderTime = "1h";

  final Color primaryBlue = const Color(0xFF67C0D7);

  // ============================================================
  // DARK MODE COLORS
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

  Color get _appBarBackground =>
      _isDark ? const Color(0xFF121212) : Colors.white;

  Color get _cardBackground => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _primaryTextColor => _isDark ? Colors.white : Colors.black87;

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : Colors.black54;

  Color get _disabledTextColor =>
      _isDark ? const Color(0xFF707070) : Colors.grey;

  Color get _dropdownBackground =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _dropdownTextColor => _isDark ? Colors.white : Colors.black87;

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final savedReminderTime = prefs.getString('reminderTime') ?? "1h";

    setState(() {
      masterToggle = prefs.getBool('masterToggle') ?? true;

      medicineReminder = prefs.getBool('medicineReminder') ?? true;

      medicineSound = prefs.getBool('medicineSound') ?? true;

      medicineVibration = prefs.getBool('medicineVibration') ?? true;

      appointmentReminder = prefs.getBool('appointmentReminder') ?? true;

      // Convert old saved values to the new stable values.
      reminderTime = _normalizeReminderTime(savedReminderTime);
    });

    // If an old value was converted, save the new stable value.
    if (savedReminderTime != reminderTime) {
      await _saveString('reminderTime', reminderTime);
    }
  }

  // ============================================================
  // NORMALIZE OLD REMINDER VALUES
  // ============================================================

  String _normalizeReminderTime(String value) {
    switch (value) {
      // Old English values
      case "30 minutes before":
        return "30m";

      case "1 hour before":
        return "1h";

      case "2 hours before":
        return "2h";

      case "1 day before":
        return "1d";

      // New stable values
      case "30m":
      case "1h":
      case "2h":
      case "1d":
        return value;

      // Safe fallback
      default:
        return "1h";
    }
  }

  // ============================================================
  // SAVE SETTINGS
  // ============================================================

  Future<void> _saveBool(
    String key,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(
    String key,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: TextStyle(
            color: _primaryTextColor,
          ),
        ),
        backgroundColor: _appBarBackground,
        elevation: 0,
        foregroundColor: _primaryTextColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ======================================================
          // GENERAL
          // ======================================================

          _buildSectionTitle(l10n.general),

          _buildCard(
            child: SwitchListTile(
              value: masterToggle,
              onChanged: (value) async {
                setState(() {
                  masterToggle = value;
                });

                await _saveBool(
                  'masterToggle',
                  value,
                );
              },
              title: Text(
                l10n.enableNotifications,
                style: TextStyle(
                  color: _primaryTextColor,
                ),
              ),
              subtitle: Text(
                l10n.turnOnOffAllAppNotifications,
                style: TextStyle(
                  color: _secondaryTextColor,
                ),
              ),
              activeColor: Colors.white,
              activeTrackColor: primaryBlue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor:
                  _isDark ? const Color(0xFF555555) : Colors.grey.shade300,
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // MEDICINE REMINDERS
          // ======================================================

          _buildSectionTitle(l10n.medicineRemindersSection),

          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: l10n.medicineReminders,
                  value: medicineReminder,
                  onChanged: masterToggle
                      ? (value) async {
                          setState(() {
                            medicineReminder = value;
                          });

                          await _saveBool(
                            'medicineReminder',
                            value,
                          );
                        }
                      : null,
                ),
                _buildSwitchTile(
                  title: l10n.medicineSound,
                  value: medicineSound,
                  onChanged: masterToggle
                      ? (value) async {
                          setState(() {
                            medicineSound = value;
                          });

                          await _saveBool(
                            'medicineSound',
                            value,
                          );
                        }
                      : null,
                ),
                _buildSwitchTile(
                  title: l10n.medicineVibration,
                  value: medicineVibration,
                  onChanged: masterToggle
                      ? (value) async {
                          setState(() {
                            medicineVibration = value;
                          });

                          await _saveBool(
                            'medicineVibration',
                            value,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // APPOINTMENTS
          // ======================================================

          _buildSectionTitle(l10n.appointments),

          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: l10n.appointmentAlerts,
                  value: appointmentReminder,
                  onChanged: masterToggle
                      ? (value) async {
                          setState(() {
                            appointmentReminder = value;
                          });

                          await _saveBool(
                            'appointmentReminder',
                            value,
                          );
                        }
                      : null,
                ),
                _buildDropdownTile(
                  title: l10n.reminderTime,
                  value: reminderTime,
                  items: const [
                    "30m",
                    "1h",
                    "2h",
                    "1d",
                  ],
                  itemLabels: [
                    l10n.thirtyMinutesBefore,
                    l10n.oneHourBefore,
                    l10n.twoHoursBefore,
                    l10n.oneDayBefore,
                  ],
                  onChanged: masterToggle
                      ? (value) async {
                          if (value == null) return;

                          setState(() {
                            reminderTime = value;
                          });

                          await _saveString(
                            'reminderTime',
                            value,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================
  // SWITCH TILE
  // ============================================================

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? _primaryTextColor : _disabledTextColor,
        ),
      ),
      activeColor: Colors.white,
      activeTrackColor: primaryBlue,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor:
          _isDark ? const Color(0xFF555555) : Colors.grey.shade300,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        left: 4,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _isDark ? const Color(0xFFBDBDBD) : Colors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!_isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required List<String> itemLabels,
    required ValueChanged<String?>? onChanged,
  }) {
    final enabled = onChanged != null;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? _primaryTextColor : _disabledTextColor,
        ),
      ),
      trailing: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        underline: const SizedBox(),
        dropdownColor: _dropdownBackground,
        style: TextStyle(
          color: enabled ? _dropdownTextColor : _disabledTextColor,
        ),
        iconEnabledColor: enabled ? _secondaryTextColor : _disabledTextColor,
        iconDisabledColor: _disabledTextColor,
        items: List.generate(
          items.length,
          (index) => DropdownMenuItem<String>(
            value: items[index],
            child: Text(
              itemLabels[index],
              style: TextStyle(
                color: _dropdownTextColor,
              ),
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
