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
  String snoozeTime = "10 minutes";

  final Color primaryBlue = const Color(0xFF67C0D7);

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

      snoozeTime = prefs.getString('snoozeTime') ?? "10 minutes";
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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
              title: const Text("Enable Notifications"),
              subtitle: const Text(
                "Turn on/off all app notifications",
              ),
              activeColor: Colors.white,
              activeTrackColor: primaryBlue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
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

          // ======================================================
          // SNOOZE
          // ======================================================

          _buildSectionTitle("Snooze"),

          _buildCard(
            child: _buildDropdownTile(
              title: "Default Snooze Duration",
              value: snoozeTime,
              items: const [
                "5 minutes",
                "10 minutes",
                "15 minutes",
                "30 minutes",
              ],
              onChanged: masterToggle
                  ? (value) async {
                      if (value == null) return;

                      setState(() {
                        snoozeTime = value;
                      });

                      await _saveString(
                        'snoozeTime',
                        value,
                      );
                    }
                  : null,
            ),
          ),
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      activeColor: Colors.white,
      activeTrackColor: primaryBlue,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey.shade300,
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
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
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
