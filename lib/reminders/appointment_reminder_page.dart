import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/nav_bar.dart';
import '../services/notification_service.dart';
import '../services/local_appointment_service.dart';

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

  // ============================================================
  // THEME COLORS
  // Light mode values are kept exactly as before.
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

  Color get _cardBackground => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF252525) : Colors.white;

  Color get _borderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : Colors.black54;

  Color get _primaryTextColor => _isDark ? Colors.white : Colors.black87;

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
        Navigator.pushReplacementNamed(context, '/health-tools');
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

    if (appointmentDateTime.isBefore(DateTime.now())) {
      _showMessage(
        'Please select a future date and time.',
        isError: true,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // 1. GET REMINDER PREFERENCE
      // ========================================================

      final reminderBefore =
          await NotificationService.instance.getAppointmentReminderDuration();

      final notificationTime = appointmentDateTime.subtract(reminderBefore);

      if (notificationTime.isBefore(DateTime.now())) {
        final reminderLabel = _formatReminderDuration(reminderBefore);

        if (!mounted) return;

        _showMessage(
          'The appointment must be more than $reminderLabel from now '
          'to receive the reminder.',
          isError: true,
        );

        return;
      }

      // ========================================================
      // 2. REQUEST NOTIFICATION PERMISSION
      // ========================================================

      final permissionGranted =
          await NotificationService.instance.requestPermission();

      if (!permissionGranted) {
        if (!mounted) return;

        _showMessage(
          'Please allow notifications and exact alarms '
          'for Medelyra in Android settings.',
          isError: true,
        );

        return;
      }

      // ========================================================
      // 3. CREATE LOCAL APPOINTMENT ID
      // ========================================================

      final now = DateTime.now();

      final appointmentId =
          '${now.microsecondsSinceEpoch}_${hospital.hashCode}';

      // ========================================================
      // 4. SAVE APPOINTMENT LOCALLY
      // ========================================================

      final appointmentData = <String, dynamic>{
        'id': appointmentId,
        'userId': user.uid,
        'appointmentType': selectedType,
        'hospital': hospital,
        'dateTime': appointmentDateTime.toIso8601String(),
        'reason': reason,
        'active': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await LocalAppointmentService.instance.insertAppointment(
        appointmentData,
      );

      // ========================================================
      // 5. SCHEDULE LOCAL NOTIFICATION
      // ========================================================

      final notificationId = appointmentId.hashCode.abs();

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
        'Appointment saved. Reminder set for '
        '${_formatReminderDuration(reminderBefore)} before.',
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
      final days = duration.inDays;

      if (days == 1) {
        return '1 day';
      }

      return '$days days';
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
      backgroundColor: _pageBackground,
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

              // ==================================================
              // TITLE
              // ==================================================

              Center(
                child: Text(
                  'New Appointment',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // APPOINTMENT TYPE
              // ==================================================

              Text(
                'Appointment Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
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
                        color: isSelected ? primaryBlue : _cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _borderColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item['icon'],
                            color:
                                isSelected ? Colors.white : _secondaryTextColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : _secondaryTextColor,
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

              Text(
                'Hospital / Clinic',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: hospitalController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    color: _primaryTextColor,
                  ),
                  cursorColor: primaryBlue,
                  decoration: InputDecoration(
                    hintText: 'Enter hospital or clinic name...',
                    hintStyle: TextStyle(
                      color: _secondaryTextColor,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // DATE
              // ==================================================

              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
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
                        style: TextStyle(
                          color: _primaryTextColor,
                        ),
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

              Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
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
                        style: TextStyle(
                          color: _primaryTextColor,
                        ),
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

              Text(
                'Reason / Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _fieldBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _borderColor,
                  ),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 4,
                  style: TextStyle(
                    color: _primaryTextColor,
                  ),
                  cursorColor: primaryBlue,
                  decoration: InputDecoration(
                    hintText: 'Example: Follow-up appointment...',
                    hintStyle: TextStyle(
                      color: _secondaryTextColor,
                    ),
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
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
