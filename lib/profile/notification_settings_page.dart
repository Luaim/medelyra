import 'package:flutter/material.dart';
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

  String reminderTime = "1 hour before";

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

    setState(() {
      masterToggle = prefs.getBool('masterToggle') ?? true;

      medicineReminder = prefs.getBool('medicineReminder') ?? true;

      medicineSound = prefs.getBool('medicineSound') ?? true;

      medicineVibration = prefs.getBool('medicineVibration') ?? true;

      appointmentReminder = prefs.getBool('appointmentReminder') ?? true;

      reminderTime = prefs.getString('reminderTime') ?? "1 hour before";
    });
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
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: Text(
          "Notifications",
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

          _buildSectionTitle("General"),

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
                "Enable Notifications",
                style: TextStyle(
                  color: _primaryTextColor,
                ),
              ),
              subtitle: Text(
                "Turn on/off all app notifications",
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

          _buildSectionTitle("Medicine Reminders"),

          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "Medicine Reminders",
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
                  title: "Medicine Sound",
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
                  title: "Medicine Vibration",
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

          _buildSectionTitle("Appointments"),

          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "Appointment Alerts",
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
                  title: "Reminder Time",
                  value: reminderTime,
                  items: const [
                    "30 minutes before",
                    "1 hour before",
                    "2 hours before",
                    "1 day before",
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
        value: value,
        underline: const SizedBox(),
        dropdownColor: _dropdownBackground,
        style: TextStyle(
          color: enabled ? _dropdownTextColor : _disabledTextColor,
        ),
        iconEnabledColor: enabled ? _secondaryTextColor : _disabledTextColor,
        iconDisabledColor: _disabledTextColor,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: _dropdownTextColor,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
