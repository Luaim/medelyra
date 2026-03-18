import 'package:flutter/material.dart';
import 'nav_bar.dart';

class AppointmentReminderPage extends StatefulWidget {
  const AppointmentReminderPage({super.key});

  @override
  State<AppointmentReminderPage> createState() =>
      _AppointmentReminderPageState();
}

class _AppointmentReminderPageState extends State<AppointmentReminderPage> {
  final TextEditingController reasonController = TextEditingController();

  String selectedHospital = 'Select Hospital';
  int selectedHour = 12;
  int selectedMinute = 0;
  String selectedPeriod = 'AM';
  int selectedCategory = 1;

  final List<String> hospitals = [
    'Select Hospital',
    'Andah Clinic',
    'Selangor Hospital',
    'Putrajaya Hospital',
    'Sultan Idris Shah Hospital',
  ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

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

  void _changeHour(bool increase) {
    setState(() {
      if (increase) {
        selectedHour = selectedHour == 12 ? 1 : selectedHour + 1;
      } else {
        selectedHour = selectedHour == 1 ? 12 : selectedHour - 1;
      }
    });
  }

  void _changeMinute(bool increase) {
    setState(() {
      if (increase) {
        selectedMinute = (selectedMinute + 1) % 60;
      } else {
        selectedMinute = (selectedMinute - 1 + 60) % 60;
      }
    });
  }

  void _changePeriod() {
    setState(() {
      selectedPeriod = selectedPeriod == 'AM' ? 'PM' : 'AM';
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AppointmentSuccessDialog(),
    );
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
                  SizedBox(height: smallScreen ? 10 : 14),
                  const Center(
                    child: Text(
                      'New Appointment',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 12 : 16),
                  Center(
                    child: Image.asset(
                      'assets/doctorAppointment.png',
                      width: screenWidth * 0.28,
                      height: screenHeight * 0.14,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services_rounded,
                        size: 90,
                        color: Color(0xFF8BC6DB),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _categoryIcon(Icons.bubble_chart_outlined, 0),
                      _categoryIcon(Icons.remove_red_eye, 1),
                      _categoryIcon(Icons.health_and_safety_outlined, 2),
                      _categoryIcon(Icons.favorite, 3, color: Colors.red),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 18 : 24),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hospital ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF444444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFADADAD)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedHospital,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: hospitals.map((hospital) {
                          return DropdownMenuItem<String>(
                            value: hospital,
                            child: Text(
                              hospital,
                              style: TextStyle(
                                color: hospital == 'Select Hospital'
                                    ? Colors.grey.shade600
                                    : const Color(0xFF333333),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedHospital = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 24),
                  const Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF444444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _timePickerCard(),
                  SizedBox(height: smallScreen ? 18 : 24),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Reason for Appointment ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF444444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFADADAD)),
                    ),
                    child: TextField(
                      controller: reasonController,
                      maxLines: 4,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        hintText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        counterText: '',
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${reasonController.text.length}/150',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 22 : 28),
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _showSuccessDialog,
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Confirm Appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2A5A5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  Widget _categoryIcon(IconData icon, int index, {Color? color}) {
    final isSelected = selectedCategory == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = index;
        });
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7DADA) : const Color(0xFFECECEC),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 30,
          color: color ??
              (isSelected ? const Color(0xFF315C9E) : const Color(0xFF6A6A6A)),
        ),
      ),
    );
  }

  Widget _timePickerCard() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeArrow(
                () => _changeHour(true), Icons.keyboard_arrow_up_rounded),
            const SizedBox(width: 24),
            _timeArrow(
                () => _changeMinute(true), Icons.keyboard_arrow_up_rounded),
            const SizedBox(width: 24),
            _timeArrow(_changePeriod, Icons.keyboard_arrow_up_rounded),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeValue(selectedHour.toString().padLeft(2, '0')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
              ),
            ),
            _timeValue(selectedMinute.toString().padLeft(2, '0')),
            const SizedBox(width: 14),
            _timeValue(selectedPeriod, width: 58),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeArrow(
                () => _changeHour(false), Icons.keyboard_arrow_down_rounded),
            const SizedBox(width: 24),
            _timeArrow(
                () => _changeMinute(false), Icons.keyboard_arrow_down_rounded),
            const SizedBox(width: 24),
            _timeArrow(_changePeriod, Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ],
    );
  }

  Widget _timeArrow(VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 30,
        color: const Color(0xFF666666),
      ),
    );
  }

  Widget _timeValue(String value, {double width = 54}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _AppointmentSuccessDialog extends StatelessWidget {
  const _AppointmentSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFF47C84A),
              child: Icon(
                Icons.check,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Appointment Scheduled Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
