import 'package:flutter/material.dart';
import 'nav_bar.dart';

class Managereminderspage extends StatefulWidget {
  const Managereminderspage({super.key});

  @override
  State<Managereminderspage> createState() => _ManagereminderspageState();
}

class _ManagereminderspageState extends State<Managereminderspage> {
  final Color primaryBlue = const Color(0xFF3D84A8);

  List<Map<String, dynamic>> reminders = [
    {
      "title": "Panadol",
      "subtitle": "After meal • Once Daily",
      "time": "8:00 AM",
      "type": "pill",
      "active": true,
    },
    {
      "title": "Dental Checkup",
      "subtitle": "Smile Clinic",
      "time": "12 Apr • 3:00 PM",
      "type": "appointment",
      "active": true,
    },
  ];

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/reminder');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/finder');
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
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1,
        onTap: (i) => _onBottomTap(context, i),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              const Text(
                "My Reminders",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Manage your reminders",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              /// LIST
              ...reminders.map((item) => _card(item)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON (same as home)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item["type"] == "pill"
                  ? Icons.medication_outlined
                  : Icons.calendar_today_outlined,
              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TIME BADGE (same style as home)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(87, 207, 207, 207),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item["time"],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                /// TITLE
                Text(
                  item["title"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                /// SUBTITLE
                Text(
                  item["subtitle"],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                /// ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _action("Edit", () {}),
                        const SizedBox(width: 16),
                        _action("Delete", () => _delete(item), isDelete: true),
                      ],
                    ),

                    /// SWITCH (aligned right)
                    Switch(
                      value: item["active"],
                      onChanged: (val) {
                        setState(() => item["active"] = val);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: primaryBlue,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(String text, VoidCallback onTap, {bool isDelete = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Text(
        text,
        style: TextStyle(
          color: isDelete ? Colors.red : primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _delete(Map item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Reminder"),
        content: const Text("Are you sure you want to delete this reminder?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => reminders.remove(item));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
