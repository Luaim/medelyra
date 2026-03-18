import 'package:flutter/material.dart';
import 'nav_bar.dart';

class PillReminderPage extends StatefulWidget {
  const PillReminderPage({super.key});

  @override
  State<PillReminderPage> createState() => _PillReminderPageState();
}

class _PillReminderPageState extends State<PillReminderPage> {
  final TextEditingController medicineNameController = TextEditingController();

  String selectedMeal = 'After Breakfast';
  String selectedDuration = '1 Month';
  String selectedFrequency = 'Daily';

  int selectedHour = 12;
  int selectedMinute = 0;
  String selectedPeriod = 'AM';

  @override
  void dispose() {
    medicineNameController.dispose();
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
      builder: (context) => const _SuccessDialog(
        message: 'Medication Added Successfully',
      ),
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
                      'New Reminder',
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
                      'assets/pillBottle.png',
                      width: screenWidth * 0.26,
                      height: screenHeight * 0.14,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medication_rounded,
                        size: 90,
                        color: Color(0xFF6F8EEB),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 24),
                  const Text(
                    'Medicine name',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF444444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _customInput(
                    child: TextField(
                      controller: medicineNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Medicine Name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: smallScreen ? 18 : 24),
                  const Text(
                    'Time & Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF444444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _selectChip(
                          text: 'After Breakfast',
                          selected: selectedMeal == 'After Breakfast',
                          onTap: () {
                            setState(() {
                              selectedMeal = 'After Breakfast';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _selectChip(
                          text: 'After Dinner',
                          selected: selectedMeal == 'After Dinner',
                          onTap: () {
                            setState(() {
                              selectedMeal = 'After Dinner';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 18 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF444444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _customInput(
                              height: 46,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_month_rounded),
                                  SizedBox(width: 8),
                                  Text(
                                    '1 Month',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Frequency',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF444444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _customInput(
                              height: 46,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time_filled_rounded),
                                  SizedBox(width: 8),
                                  Text(
                                    'Daily',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: smallScreen ? 20 : 26),
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
                  SizedBox(height: smallScreen ? 24 : 30),
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _showSuccessDialog,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Add Reminder'),
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

  Widget _customInput({required Widget child, double height = 50}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFADADAD)),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _selectChip({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFEFEF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFD5D5D5) : const Color(0xFFE5E5E5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF444444),
            fontWeight: FontWeight.w500,
          ),
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

class _SuccessDialog extends StatelessWidget {
  final String message;

  const _SuccessDialog({required this.message});

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
