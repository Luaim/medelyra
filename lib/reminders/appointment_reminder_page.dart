import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/nav_bar.dart';
import '../services/notification_service.dart';

class AppointmentReminderPage extends StatefulWidget {
  const AppointmentReminderPage({super.key});

  @override
  State<AppointmentReminderPage> createState() =>
      _AppointmentReminderPageState();
}

class _AppointmentReminderPageState extends State<AppointmentReminderPage> {
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();

  final Color primaryBlue = const Color(0xFF3D84A8);

  String selectedType = 'General';

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  bool isSaving = false;

  final List<Map<String, dynamic>> appointmentTypes = [
    {
      'label': 'General',
      'icon': Icons.local_hospital,
    },
    {
      'label': 'Eye',
      'icon': Icons.remove_red_eye,
    },
    {
      'label': 'Dental',
      'icon': Icons.medical_services,
    },
    {
      'label': 'Heart',
      'icon': Icons.favorite,
    },
  ];

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

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

  // ============================================================
  // PICK DATE
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(now) ? now : selectedDate,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ============================================================
  // PICK TIME
  // ============================================================

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // ============================================================
  // COMBINE DATE + TIME
  // ============================================================

  DateTime _combineDateAndTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  // ============================================================
  // SAVE APPOINTMENT
  // ============================================================

  Future<void> _saveAppointment() async {
    if (isSaving) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before creating an appointment.',
        isError: true,
      );
      return;
    }

    final hospital = hospitalController.text.trim();
    final reason = reasonController.text.trim();

    if (hospital.isEmpty) {
      _showMessage(
        'Please enter the hospital or clinic name.',
        isError: true,
      );
      return;
    }

    final appointmentDateTime = _combineDateAndTime();

    // Appointment must be in the future.
    if (appointmentDateTime.isBefore(DateTime.now())) {
      _showMessage(
        'Please select a future date and time.',
        isError: true,
      );
      return;
    }

    // ==========================================================
    // REMINDER
    // ==========================================================

    // Read the user's appointment reminder preference.
    final reminderBefore =
        await NotificationService.instance.getAppointmentReminderDuration();

    final notificationTime = appointmentDateTime.subtract(reminderBefore);

// The reminder itself must also be in the future.
    if (notificationTime.isBefore(DateTime.now())) {
      final reminderLabel = _formatReminderDuration(reminderBefore);

      _showMessage(
        'The appointment must be more than $reminderLabel from now '
        'to receive the reminder.',
        isError: true,
      );
      return;
    }

    try {
      // ========================================================
      // 1. REQUEST NOTIFICATION + EXACT ALARM PERMISSION
      // ========================================================

      final permissionGranted =
          await NotificationService.instance.requestPermission();

      if (!permissionGranted) {
        if (!mounted) return;

        _showMessage(
          'Please allow notifications and exact alarms '
          'for MedMinder in Android settings.',
          isError: true,
        );

        return;
      }

      // ========================================================
      // 2. SAVE APPOINTMENT TO FIRESTORE
      // ========================================================

      final appointmentDoc =
          await FirebaseFirestore.instance.collection('appointments').add({
        'userId': user.uid,
        'appointmentType': selectedType,
        'hospital': hospital,
        'dateTime': Timestamp.fromDate(appointmentDateTime),
        'reason': reason,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // 3. CREATE NOTIFICATION ID
      // ========================================================

      final notificationId = appointmentDoc.id.hashCode.abs();

      // ========================================================
      // 4. SCHEDULE NOTIFICATION
      // ========================================================

      await NotificationService.instance.scheduleAppointmentNotification(
        id: notificationId,
        appointmentType: '$selectedType appointment at $hospital',
        appointmentTime: appointmentDateTime,
        reminderBefore: reminderBefore,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      _showMessage(
        'Appointment saved. Reminder set for 1 hour before.',
        isError: false,
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/reminder',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      debugPrint(
        'Save appointment Firebase error: $e',
      );

      _showMessage(
        'Could not save appointment: '
        '${e.message ?? e.code}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'Save appointment error: $e',
      );

      _showMessage(
        'Could not save appointment. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
// FORMAT REMINDER DURATION
// ============================================================

  String _formatReminderDuration(Duration duration) {
    if (duration.inDays >= 1) {
      return '1 day';
    }

    if (duration.inHours >= 1) {
      final hours = duration.inHours;

      if (hours == 1) {
        return '1 hour';
      }

      return '$hours hours';
    }

    final minutes = duration.inMinutes;

    if (minutes == 1) {
      return '1 minute';
    }

    return '$minutes minutes';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : primaryBlue,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    reasonController.dispose();
    hospitalController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1,
        onTap: (i) => _onBottomTap(context, i),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.06,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'New Appointment',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // APPOINTMENT TYPE
              // ==================================================

              const Text(
                'Appointment Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: appointmentTypes.map((item) {
                  final bool isSelected = selectedType == item['label'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = item['label'];
                      });
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // HOSPITAL
              // ==================================================

              const Text(
                'Hospital / Clinic',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: hospitalController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter hospital or clinic name...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // DATE
              // ==================================================

              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickDate,
                child: _input(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedDate.day}/'
                        '${selectedDate.month}/'
                        '${selectedDate.year}',
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TIME
              // ==================================================

              const Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickTime,
                child: _input(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedTime.format(context),
                      ),
                      Icon(
                        Icons.access_time,
                        color: primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // REASON
              // ==================================================

              const Text(
                'Reason / Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Example: Follow-up appointment...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: primaryBlue.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Appointment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT CONTAINER
  // ============================================================

  Widget _input({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
