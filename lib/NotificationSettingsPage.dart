import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool masterToggle = true;

  bool medicineReminder = true;
  bool medicineSound = true;
  bool medicineVibration = true;

  bool appointmentReminder = true;

  String reminderTime = "1 hour before";
  String snoozeTime = "10 minutes";

  final Color primaryBlue = const Color(0xFF67C0D7);

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
          _buildSectionTitle("General"),
          _buildCard(
            child: SwitchListTile(
              value: masterToggle,
              onChanged: (value) {
                setState(() => masterToggle = value);
              },
              title: const Text("Enable Notifications"),
              subtitle: const Text("Turn on/off all app notifications"),
              activeColor: Colors.white,
              activeTrackColor: primaryBlue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle("Medicine Reminders"),
          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "Reminder Alerts",
                  value: medicineReminder,
                  onChanged: masterToggle
                      ? (value) => setState(() => medicineReminder = value)
                      : null,
                ),
                _buildSwitchTile(
                  title: "Sound",
                  value: medicineSound,
                  onChanged: masterToggle
                      ? (value) => setState(() => medicineSound = value)
                      : null,
                ),
                _buildSwitchTile(
                  title: "Vibration",
                  value: medicineVibration,
                  onChanged: masterToggle
                      ? (value) => setState(() => medicineVibration = value)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle("Appointments"),
          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: "Appointment Alerts",
                  value: appointmentReminder,
                  onChanged: masterToggle
                      ? (value) => setState(() => appointmentReminder = value)
                      : null,
                ),
                _buildDropdownTile(
                  title: "Reminder Time",
                  value: reminderTime,
                  items: [
                    "30 minutes before",
                    "1 hour before",
                    "2 hours before",
                    "1 day before",
                  ],
                  onChanged: masterToggle
                      ? (value) => setState(() => reminderTime = value!)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle("Snooze"),
          _buildCard(
            child: _buildDropdownTile(
              title: "Default Snooze Duration",
              value: snoozeTime,
              items: [
                "5 minutes",
                "10 minutes",
                "15 minutes",
                "30 minutes",
              ],
              onChanged: masterToggle
                  ? (value) => setState(() => snoozeTime = value!)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  //  Reusable switch tile
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
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

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

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
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
