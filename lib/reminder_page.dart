import 'package:flutter/material.dart';
import 'nav_bar.dart';

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
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final smallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1,
        onTap: (index) => _onBottomTap(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: smallScreen ? 20 : 30),
                  const Text(
                    'Medicine & Appointment reminder',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 24 : 30),
                  _ReminderOptionCard(
                    title: 'Pill Reminder',
                    imagePath: 'assets/pillReminder.png',
                    fallbackIcon: Icons.access_time_filled_rounded,
                    onPressed: () {
                      Navigator.pushNamed(context, '/pillReminder');
                    },
                  ),
                  SizedBox(height: smallScreen ? 18 : 22),
                  _ReminderOptionCard(
                    title: 'Appointment Reminder',
                    imagePath: 'assets/appointmentReminder.png',
                    fallbackIcon: Icons.calendar_month_rounded,
                    onPressed: () {
                      Navigator.pushNamed(context, '/appointmentReminder');
                    },
                  ),
                  SizedBox(height: smallScreen ? 26 : 34),
                  Center(
                    child: Image.asset(
                      'assets/reminderBottom.png',
                      width: screenWidth * 0.58,
                      height: screenHeight * 0.24,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: screenWidth * 0.58,
                        height: screenHeight * 0.24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.schedule_send_rounded,
                          size: 90,
                          color: Color(0xFF7A8BE8),
                        ),
                      ),
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
}

class _ReminderOptionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final IconData fallbackIcon;
  final VoidCallback onPressed;

  const _ReminderOptionCard({
    required this.title,
    required this.imagePath,
    required this.fallbackIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFCFF0F0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon,
                  size: 46,
                  color: const Color(0xFF315C9E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67C0D7),
                foregroundColor: const Color(0xFF1E3A43),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(
                    color: Color(0xFF2A6E7E),
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
