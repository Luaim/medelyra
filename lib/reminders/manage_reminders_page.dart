import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/nav_bar.dart';
import '../services/notification_service.dart';
import '../services/local_database_service.dart';
import '../services/local_appointment_service.dart';
import '../services/theme_service.dart';

class Managereminderspage extends StatefulWidget {
  const Managereminderspage({super.key});

  @override
  State<Managereminderspage> createState() => _ManagereminderspageState();
}

class _ManagereminderspageState extends State<Managereminderspage> {
  final Color primaryBlue = const Color(0xFF3D84A8);

  final ThemeService _themeService = ThemeService.instance;

  bool get _isDark => _themeService.isDarkMode;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);

  Color get _cardBackground => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _dialogBackground =>
      _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F7FC);

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF252525) : Colors.white;

  Color get _borderColor =>
      _isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : Colors.grey;

  Color get _dialogLabelColor =>
      _isDark ? const Color(0xFFBDBDBD) : Colors.grey.shade700;

  Color get _iconBackground =>
      _isDark ? const Color(0xFF26343A) : const Color(0xFFEFF2FA);

  Color get _timeBadgeBackground => _isDark
      ? const Color(0xFF2D2D2D)
      : const Color.fromARGB(87, 207, 207, 207);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> reminders = [];

  // ============================================================
  // MEDICINE OPTIONS
  // ============================================================

  final List<Map<String, dynamic>> medicineTypes = [
    {
      'label': 'Pill',
      'icon': Icons.medication_outlined,
    },
    {
      'label': 'Injection',
      'icon': Icons.vaccines_outlined,
    },
    {
      'label': 'Cream',
      'icon': Icons.spa_outlined,
    },
    {
      'label': 'Drop',
      'icon': Icons.opacity_outlined,
    },
    {
      'label': 'Inhaler',
      'icon': Icons.air_outlined,
    },
    {
      'label': 'Bandage',
      'icon': Icons.healing_outlined,
    },
    {
      'label': 'Syrup',
      'icon': Icons.local_drink_outlined,
    },
    {
      'label': 'Other',
      'icon': Icons.medical_information_outlined,
    },
  ];

  final List<String> frequencyOptions = [
    'Once Daily',
    'Twice Daily',
    '3 Times Daily',
    '4 Times Daily',
    'Every 8 Hours',
    'Every 12 Hours',
    'As Needed',
    'Custom Schedule',
  ];

  final List<String> durationOptions = [
    '1 Day',
    '3 Days',
    '7 Days',
    '14 Days',
    '1 Month',
    'Ongoing',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // ============================================================
  // LOAD REMINDERS
  // ============================================================

  Future<void> _loadReminders() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Please sign in again.';
      });

      return;
    }

    try {
      // ==========================================================
      // LOAD BOTH REMINDER TYPES LOCALLY
      // ==========================================================
      final medicineRows =
          await LocalDatabaseService.instance.getMedicines(user.uid);

      final appointmentRows =
          await LocalAppointmentService.instance.getAppointments(user.uid);

      final List<Map<String, dynamic>> loaded = [];

      // ==========================================================
      // MEDICINES
      // ==========================================================
      for (final data in medicineRows) {
        final rawTimes = data['times'];
        final List<String> times = rawTimes is String
            ? rawTimes
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : rawTimes is List
                ? rawTimes.map((e) => e.toString()).toList()
                : <String>[];

        final timeText = times.isEmpty ? 'No time' : times.join(' • ');

        final String instructions =
            (data['instructions'] ?? '').toString().trim();
        final String frequency = (data['frequency'] ?? '').toString().trim();

        String subtitle = '';

        if (instructions.isNotEmpty && frequency.isNotEmpty) {
          subtitle = '$instructions • $frequency';
        } else if (frequency.isNotEmpty) {
          subtitle = frequency;
        } else if (instructions.isNotEmpty) {
          subtitle = instructions;
        } else {
          subtitle = 'Medicine reminder';
        }

        loaded.add({
          'id': data['id'].toString(),
          'collection': 'medicines',
          'title': data['medicineName'] ?? 'Medicine',
          'subtitle': subtitle,
          'time': timeText,
          'type': 'pill',
          'active': data['active'] == 1 || data['active'] == true,
          'data': Map<String, dynamic>.from(data),
        });
      }

      // ==========================================================
      // APPOINTMENTS
      // ==========================================================
      for (final data in appointmentRows) {
        DateTime? appointmentDateTime;
        final rawDateTime = data['dateTime'];

        if (rawDateTime is String && rawDateTime.isNotEmpty) {
          appointmentDateTime = DateTime.tryParse(rawDateTime);
        }

        String timeText = 'No date';

        if (appointmentDateTime != null) {
          timeText =
              '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year} • '
              '${_formatTime(appointmentDateTime)}';
        }

        final String hospital = (data['hospital'] ?? '').toString().trim();
        final String appointmentType =
            (data['appointmentType'] ?? 'Appointment').toString();

        loaded.add({
          'id': data['id'].toString(),
          'collection': 'appointments',
          'title': appointmentType,
          'subtitle': hospital.isEmpty ? 'Appointment' : hospital,
          'time': timeText,
          'type': 'appointment',
          'active': data['active'] == 1 || data['active'] == true,
          'data': Map<String, dynamic>.from(data),
        });
      }

      // Medicines first, appointments second.
      loaded.sort((a, b) {
        if (a['type'] == b['type']) return 0;
        return a['type'] == 'pill' ? -1 : 1;
      });

      if (!mounted) return;

      setState(() {
        reminders = loaded;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Could not load reminders.';
      });

      debugPrint('Load reminders error: $e');
    }
  }

  DateTime? _parseLocalDate(
    dynamic value, {
    DateTime? fallback,
  }) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  int? _storedInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  List<TimeOfDay> _storedTimesAsTimeOfDay(dynamic value) {
    if (value is List) {
      return value
          .map((e) => _parseStoredTime(e.toString()))
          .whereType<TimeOfDay>()
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map(_parseStoredTime)
          .whereType<TimeOfDay>()
          .toList();
    }

    return [];
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // FORMAT TIME OF DAY
  // ============================================================

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // PARSE STORED TIME
  // ============================================================

  TimeOfDay? _parseStoredTime(String value) {
    final parts = value.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  // ============================================================
  // TIME DATABASE FORMAT
  // ============================================================

  String _formatTimeForDatabase(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ============================================================
  // ADD HOURS
  // ============================================================

  TimeOfDay _addHours(TimeOfDay time, int hours) {
    final totalMinutes = time.hour * 60 + time.minute + hours * 60;

    final normalizedMinutes = totalMinutes % (24 * 60);

    return TimeOfDay(
      hour: normalizedMinutes ~/ 60,
      minute: normalizedMinutes % 60,
    );
  }

  // ============================================================
  // GET TIMES FOR FREQUENCY
  // ============================================================

  List<TimeOfDay> _timesForFrequency(
    String frequency,
    TimeOfDay startingTime,
  ) {
    switch (frequency) {
      case 'Once Daily':
        return [startingTime];

      case 'Twice Daily':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];

      case '3 Times Daily':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];

      case '4 Times Daily':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];

      case 'Every 8 Hours':
        return [
          startingTime,
          _addHours(startingTime, 8),
          _addHours(startingTime, 16),
        ];

      case 'Every 12 Hours':
        return [
          startingTime,
          _addHours(startingTime, 12),
        ];

      case 'As Needed':
        return [];

      case 'Custom Schedule':
        return [startingTime];

      default:
        return [startingTime];
    }
  }

  // ============================================================
  // DURATION
  // ============================================================

  int? _durationInDays(String duration) {
    switch (duration) {
      case '1 Day':
        return 1;

      case '3 Days':
        return 3;

      case '7 Days':
        return 7;

      case '14 Days':
        return 14;

      case '1 Month':
        return 30;

      case 'Ongoing':
        return null;

      default:
        return 7;
    }
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================

  Future<void> _toggleReminder(
    Map<String, dynamic> item,
    bool value,
  ) async {
    final String collection = item['collection'].toString();
    final String id = item['id'].toString();

    try {
      final now = DateTime.now().toIso8601String();

      if (collection == 'medicines') {
        await LocalDatabaseService.instance.updateMedicine(
          id,
          {
            'active': value ? 1 : 0,
            'updatedAt': now,
          },
        );

        final data = Map<String, dynamic>.from(item['data']);

        if (!value) {
          await _cancelMedicineNotifications(
            medicineId: id,
            data: data,
          );
        } else {
          final times = _storedTimesAsTimeOfDay(data['times']);
          final startDate = _parseLocalDate(
                data['startDate'],
                fallback: DateTime.now(),
              ) ??
              DateTime.now();
          final durationDays = _storedInt(data['durationDays']);

          await NotificationService.instance.requestPermission();

          await _scheduleMedicineNotifications(
            medicineId: id,
            medicineName: (data['medicineName'] ?? 'Medicine').toString(),
            times: times,
            durationDays: durationDays,
            startDate: startDate,
          );
        }
      } else {
        await LocalAppointmentService.instance.updateAppointment(
          id,
          {
            'active': value ? 1 : 0,
            'updatedAt': now,
          },
        );

        final data = Map<String, dynamic>.from(item['data']);
        final notificationId = id.hashCode.abs();

        if (!value) {
          await NotificationService.instance.cancel(
            notificationId,
          );
        } else {
          final appointmentTime = _parseLocalDate(data['dateTime']);

          if (appointmentTime != null) {
            final permissionGranted =
                await NotificationService.instance.requestPermission();

            if (!permissionGranted) {
              throw Exception('Notification permission was not granted.');
            }

            final reminderBefore = await NotificationService.instance
                .getAppointmentReminderDuration();

            await NotificationService.instance.scheduleAppointmentNotification(
              id: notificationId,
              appointmentType: '${data['appointmentType'] ?? 'Appointment'} '
                  'at ${data['hospital'] ?? ''}',
              appointmentTime: appointmentTime,
              reminderBefore: reminderBefore,
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        item['active'] = value;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update reminder.'),
        ),
      );

      debugPrint('Toggle reminder error: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _delete(Map<String, dynamic> item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete Reminder',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${item['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final String collection = item['collection'].toString();
      final String id = item['id'].toString();

      if (collection == 'medicines') {
        await _cancelMedicineNotifications(
          medicineId: id,
          data: Map<String, dynamic>.from(item['data']),
        );

        await LocalDatabaseService.instance.deleteMedicine(id);
      } else {
        await NotificationService.instance.cancel(
          id.hashCode.abs(),
        );

        await LocalAppointmentService.instance.deleteAppointment(id);
      }

      if (!mounted) return;

      setState(() {
        reminders.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete reminder.'),
        ),
      );

      debugPrint('Delete reminder error: $e');
    }
  }

  // ============================================================
  // EDIT ROUTER
  // ============================================================

  Future<void> _editReminder(
    Map<String, dynamic> item,
  ) async {
    if (item['collection'] == 'medicines') {
      await _editMedicine(item);
    } else {
      await _editAppointment(item);
    }
  }

  // ============================================================
  // EDIT MEDICINE
  // ============================================================

  Future<void> _editMedicine(
    Map<String, dynamic> item,
  ) async {
    final data = Map<String, dynamic>.from(item['data']);

    final nameController = TextEditingController(
      text: (data['medicineName'] ?? '').toString(),
    );

    final doseController = TextEditingController(
      text: (data['dose'] ?? '').toString(),
    );

    final instructionsController = TextEditingController(
      text: (data['instructions'] ?? '').toString(),
    );

    String medicineType = (data['medicineType'] ?? 'Pill').toString();

    if (!medicineTypes.any(
      (item) => item['label'] == medicineType,
    )) {
      medicineType = 'Other';
    }

    String frequency = (data['frequency'] ?? 'Once Daily').toString();

    if (!frequencyOptions.contains(frequency)) {
      frequency = 'Once Daily';
    }

    String duration = (data['duration'] ?? '7 Days').toString();

    if (!durationOptions.contains(duration)) {
      duration = '7 Days';
    }

    DateTime startDate = _parseLocalDate(
          data['startDate'],
          fallback: DateTime.now(),
        ) ??
        DateTime.now();

    List<TimeOfDay> times = _storedTimesAsTimeOfDay(data['times']);

    if (times.isEmpty && frequency != 'As Needed') {
      times = [TimeOfDay.now()];
    }

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                  maxHeight: 720,
                ),
                decoration: BoxDecoration(
                  color: _dialogBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        20,
                        14,
                        14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.medication_outlined,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Edit Medicine',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(
                              dialogContext,
                              false,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          18,
                          22,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dialogSectionTitle('Basic Information'),
                            const SizedBox(height: 12),
                            _modernTextField(
                              controller: nameController,
                              label: 'Medicine Name',
                              hint: 'Enter medicine name',
                              icon: Icons.medication_outlined,
                            ),
                            const SizedBox(height: 14),
                            _modernDropdown(
                              label: 'Medicine Type',
                              icon: Icons.category_outlined,
                              value: medicineType,
                              items: medicineTypes
                                  .map((e) => e['label'].toString())
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  medicineType = value;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            _modernTextField(
                              controller: doseController,
                              label: 'Dose / Amount',
                              hint: 'Example: 1 tablet, 5 ml',
                              icon: Icons.scale_outlined,
                            ),
                            const SizedBox(height: 22),
                            _dialogSectionTitle('Schedule'),
                            const SizedBox(height: 12),
                            _modernDropdown(
                              label: 'Frequency',
                              icon: Icons.repeat,
                              value: frequency,
                              items: frequencyOptions,
                              onChanged: (value) {
                                setDialogState(() {
                                  frequency = value;

                                  if (value == 'As Needed') {
                                    times = [];
                                  } else {
                                    final startingTime = times.isNotEmpty
                                        ? times.first
                                        : TimeOfDay.now();

                                    times = _timesForFrequency(
                                      value,
                                      startingTime,
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            if (frequency != 'As Needed')
                              _buildMedicineTimesEditor(
                                context: context,
                                frequency: frequency,
                                times: times,
                                setDialogState: setDialogState,
                              )
                            else
                              _editInfoBox(
                                'This medicine has no fixed reminder time.',
                                icon: Icons.info_outline,
                              ),
                            const SizedBox(height: 14),
                            _modernDateField(
                              label: 'Start Date',
                              date: startDate,
                              onTap: () async {
                                final now = DateTime.now();
                                final firstDate = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final initialDate = startDate.isBefore(
                                  firstDate,
                                )
                                    ? firstDate
                                    : startDate;

                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: initialDate,
                                  firstDate: firstDate,
                                  lastDate: DateTime(2035),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = picked;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            _modernDropdown(
                              label: 'Duration',
                              icon: Icons.timelapse_outlined,
                              value: duration,
                              items: durationOptions,
                              onChanged: (value) {
                                setDialogState(() {
                                  duration = value;
                                });
                              },
                            ),
                            const SizedBox(height: 22),
                            _dialogSectionTitle('Additional Information'),
                            const SizedBox(height: 12),
                            _modernTextField(
                              controller: instructionsController,
                              label: 'Instructions (Optional)',
                              hint: 'Example: Take after food',
                              icon: Icons.notes_outlined,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        12,
                        22,
                        18,
                      ),
                      decoration: BoxDecoration(
                        color: _dialogBackground,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                false,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                side: BorderSide(
                                  color: _borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) {
                                  _dialogError(
                                    dialogContext,
                                    'Please enter the medicine name.',
                                  );
                                  return;
                                }

                                if (doseController.text.trim().isEmpty) {
                                  _dialogError(
                                    dialogContext,
                                    'Please enter the dose or amount.',
                                  );
                                  return;
                                }

                                if (frequency == 'Custom Schedule' &&
                                    times.isEmpty) {
                                  _dialogError(
                                    dialogContext,
                                    'Please add at least one reminder time.',
                                  );
                                  return;
                                }

                                Navigator.pop(dialogContext, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      doseController.dispose();
      instructionsController.dispose();
      return;
    }

    try {
      final finalTimes = frequency == 'As Needed' ? <TimeOfDay>[] : times;
      final durationDays = _durationInDays(duration);

      DateTime? endDate;

      if (durationDays != null) {
        endDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).add(Duration(days: durationDays - 1));
      }

      await _cancelMedicineNotifications(
        medicineId: item['id'],
        data: data,
      );

      final now = DateTime.now();

      await LocalDatabaseService.instance.updateMedicine(
        item['id'],
        {
          'medicineName': nameController.text.trim(),
          'medicineType': medicineType,
          'dose': doseController.text.trim(),
          'instructions': instructionsController.text.trim(),
          'frequency': frequency,
          'times': finalTimes.map(_formatTimeForDatabase).join(','),
          'duration': duration,
          'durationDays': durationDays,
          'startDate': DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          ).toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );

      if (item['active'] == true) {
        final permissionGranted =
            await NotificationService.instance.requestPermission();

        if (permissionGranted) {
          await _scheduleMedicineNotifications(
            medicineId: item['id'],
            medicineName: nameController.text.trim(),
            times: finalTimes,
            durationDays: durationDays,
            startDate: startDate,
          );
        }
      }

      nameController.dispose();
      doseController.dispose();
      instructionsController.dispose();

      await _loadReminders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine updated successfully.'),
        ),
      );
    } catch (e) {
      nameController.dispose();
      doseController.dispose();
      instructionsController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update medicine.'),
        ),
      );

      debugPrint('Edit medicine error: $e');
    }
  }

  // ============================================================
  // MEDICINE TIME EDITOR
  // ============================================================

  Widget _buildMedicineTimesEditor({
    required BuildContext context,
    required String frequency,
    required List<TimeOfDay> times,
    required StateSetter setDialogState,
  }) {
    if (frequency == 'Every 8 Hours' || frequency == 'Every 12 Hours') {
      final startingTime = times.isNotEmpty ? times.first : TimeOfDay.now();

      final previewTimes = _timesForFrequency(
        frequency,
        startingTime,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminder Time',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          _timeSelector(
            context: context,
            time: startingTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startingTime,
              );

              if (picked != null) {
                setDialogState(() {
                  times = _timesForFrequency(
                    frequency,
                    picked,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 10),
          _schedulePreviewSmall(
            previewTimes,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Times',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        ...List.generate(
          times.length,
          (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _timeSelector(
                context: context,
                time: times[index],
                showDelete: frequency == 'Custom Schedule',
                onDelete: () {
                  if (times.length <= 1) {
                    return;
                  }

                  setDialogState(() {
                    times.removeAt(index);
                  });
                },
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: times[index],
                  );

                  if (picked != null) {
                    setDialogState(() {
                      times[index] = picked;
                    });
                  }
                },
              ),
            );
          },
        ),
        if (frequency == 'Custom Schedule')
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (picked != null) {
                  setDialogState(() {
                    times.add(picked);
                  });
                }
              },
              icon: Icon(
                Icons.add,
                color: primaryBlue,
                size: 19,
              ),
              label: Text(
                'Add Another Time',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: primaryBlue,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TIME SELECTOR
  // ============================================================

  Widget _timeSelector({
    required BuildContext context,
    required TimeOfDay time,
    required VoidCallback onTap,
    bool showDelete = false,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        decoration: BoxDecoration(
          color: _fieldBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatTimeOfDay(time),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showDelete)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close,
                  size: 19,
                  color: Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(
                Icons.chevron_right,
                color: _secondaryTextColor,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE PREVIEW
  // ============================================================

  Widget _schedulePreviewSmall(
    List<TimeOfDay> times,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule_outlined,
            color: primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: times.map(
                (time) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBackground,
                      borderRadius: BorderRadius.circular(
                        9,
                      ),
                    ),
                    child: Text(
                      _formatTimeOfDay(time),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANCEL MEDICINE NOTIFICATIONS
  // ============================================================

  Future<void> _cancelMedicineNotifications({
    required String medicineId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final startDate = _parseLocalDate(
            data['startDate'],
            fallback: DateTime.now(),
          ) ??
          DateTime.now();

      int daysToCancel = _storedInt(data['durationDays']) ?? 30;

      if (daysToCancel > 365) {
        daysToCancel = 365;
      }

      if (daysToCancel < 1) {
        daysToCancel = 30;
      }

      final oldTimes = _storedTimesAsTimeOfDay(data['times']);

      for (int day = 0; day < daysToCancel; day++) {
        final date = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).add(Duration(days: day));

        for (int timeIndex = 0; timeIndex < oldTimes.length; timeIndex++) {
          final notificationId =
              '${medicineId}_${date.year}_${date.month}_${date.day}_$timeIndex'
                      .hashCode &
                  0x7fffffff;

          await NotificationService.instance.cancel(notificationId);
        }
      }
    } catch (e) {
      debugPrint('Cancel medicine notifications error: $e');
    }
  }

  // ============================================================
  // SCHEDULE MEDICINE NOTIFICATIONS
  // ============================================================

  Future<void> _scheduleMedicineNotifications({
    required String medicineId,
    required String medicineName,
    required List<TimeOfDay> times,
    required int? durationDays,
    required DateTime startDate,
  }) async {
    if (times.isEmpty) {
      return;
    }

    final daysToSchedule = durationDays ?? 30;

    for (int day = 0; day < daysToSchedule; day++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(
        Duration(days: day),
      );

      for (int timeIndex = 0; timeIndex < times.length; timeIndex++) {
        final time = times[timeIndex];

        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (scheduledTime.isBefore(
          DateTime.now(),
        )) {
          continue;
        }

        final notificationId =
            '${medicineId}_${date.year}_${date.month}_${date.day}_$timeIndex'
                    .hashCode &
                0x7fffffff;

        await NotificationService.instance.scheduleMedicineNotification(
          id: notificationId,
          medicineName: medicineName,
          scheduledTime: scheduledTime,
        );
      }
    }
  }

  // ============================================================
  // EDIT APPOINTMENT
  // ============================================================

  Future<void> _editAppointment(
    Map<String, dynamic> item,
  ) async {
    final data = Map<String, dynamic>.from(item['data']);

    final hospitalController = TextEditingController(
      text: (data['hospital'] ?? '').toString(),
    );

    final reasonController = TextEditingController(
      text: (data['reason'] ?? '').toString(),
    );

    String appointmentType = (data['appointmentType'] ?? 'General').toString();

    if (![
      'General',
      'Eye',
      'Dental',
      'Heart',
    ].contains(appointmentType)) {
      appointmentType = 'General';
    }

    DateTime appointmentDate = _parseLocalDate(
          data['dateTime'],
          fallback: DateTime.now().add(const Duration(hours: 1)),
        ) ??
        DateTime.now().add(const Duration(hours: 1));

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                  maxHeight: 650,
                ),
                decoration: BoxDecoration(
                  color: _dialogBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        20,
                        14,
                        14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Edit Appointment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(
                              dialogContext,
                              false,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          18,
                          22,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dialogSectionTitle('Appointment Details'),
                            const SizedBox(height: 12),
                            _modernDropdown(
                              label: 'Appointment Type',
                              icon: Icons.local_hospital_outlined,
                              value: appointmentType,
                              items: const [
                                'General',
                                'Eye',
                                'Dental',
                                'Heart',
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  appointmentType = value;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            _modernTextField(
                              controller: hospitalController,
                              label: 'Hospital / Clinic',
                              hint: 'Enter hospital or clinic name',
                              icon: Icons.local_hospital_outlined,
                            ),
                            const SizedBox(height: 22),
                            _dialogSectionTitle('Date & Time'),
                            const SizedBox(height: 12),
                            _modernDateField(
                              label: 'Appointment Date',
                              date: appointmentDate,
                              onTap: () async {
                                final now = DateTime.now();
                                final firstDate = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final initialDate = appointmentDate.isBefore(
                                  firstDate,
                                )
                                    ? firstDate
                                    : appointmentDate;

                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: initialDate,
                                  firstDate: firstDate,
                                  lastDate: DateTime(2035),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    appointmentDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      appointmentDate.hour,
                                      appointmentDate.minute,
                                    );
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            _timeSelector(
                              context: context,
                              time: TimeOfDay.fromDateTime(appointmentDate),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(
                                    appointmentDate,
                                  ),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    appointmentDate = DateTime(
                                      appointmentDate.year,
                                      appointmentDate.month,
                                      appointmentDate.day,
                                      picked.hour,
                                      picked.minute,
                                    );
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 22),
                            _dialogSectionTitle('Notes'),
                            const SizedBox(height: 12),
                            _modernTextField(
                              controller: reasonController,
                              label: 'Reason / Notes',
                              hint: 'Example: Follow-up appointment',
                              icon: Icons.notes_outlined,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        12,
                        22,
                        18,
                      ),
                      decoration: BoxDecoration(
                        color: _dialogBackground,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                false,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                side: BorderSide(
                                  color: _borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (hospitalController.text.trim().isEmpty) {
                                  _dialogError(
                                    dialogContext,
                                    'Please enter the hospital or clinic name.',
                                  );
                                  return;
                                }

                                if (appointmentDate.isBefore(
                                  DateTime.now(),
                                )) {
                                  _dialogError(
                                    dialogContext,
                                    'Please select a future date and time.',
                                  );
                                  return;
                                }

                                Navigator.pop(dialogContext, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      hospitalController.dispose();
      reasonController.dispose();
      return;
    }

    try {
      final notificationId = item['id'].hashCode.abs();

      await NotificationService.instance.cancel(
        notificationId,
      );

      final now = DateTime.now().toIso8601String();

      await LocalAppointmentService.instance.updateAppointment(
        item['id'],
        {
          'appointmentType': appointmentType,
          'hospital': hospitalController.text.trim(),
          'reason': reasonController.text.trim(),
          'dateTime': appointmentDate.toIso8601String(),
          'updatedAt': now,
        },
      );

      if (item['active'] == true) {
        final permissionGranted =
            await NotificationService.instance.requestPermission();

        if (permissionGranted) {
          final reminderBefore = await NotificationService.instance
              .getAppointmentReminderDuration();

          await NotificationService.instance.scheduleAppointmentNotification(
            id: notificationId,
            appointmentType: '$appointmentType appointment at '
                '${hospitalController.text.trim()}',
            appointmentTime: appointmentDate,
            reminderBefore: reminderBefore,
          );
        }
      }

      hospitalController.dispose();
      reasonController.dispose();

      await _loadReminders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment updated successfully.'),
        ),
      );
    } catch (e) {
      hospitalController.dispose();
      reasonController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update appointment.'),
        ),
      );

      debugPrint('Edit appointment error: $e');
    }
  }

  // ============================================================
  // DIALOG SECTION TITLE
  // ============================================================

  Widget _dialogSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _dialogLabelColor,
        letterSpacing: 0.2,
      ),
    );
  }

  // ============================================================
  // MODERN TEXT FIELD
  // ============================================================

  Widget _modernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            bottom: maxLines > 1 ? 45 : 0,
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: _fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MODERN DROPDOWN
  // ============================================================

  Widget _modernDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: primaryBlue,
          size: 20,
        ),
        filled: true,
        fillColor: _fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),
      items: items.map(
        (item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  // ============================================================
  // MODERN DATE FIELD
  // ============================================================

  Widget _modernDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: primaryBlue,
            size: 20,
          ),
          suffixIcon: Icon(
            Icons.chevron_right,
            color: _secondaryTextColor,
          ),
          filled: true,
          fillColor: _fieldBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: _borderColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: _borderColor,
            ),
          ),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  Widget _editInfoBox(
    String text, {
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryBlue,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: primaryBlue,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG ERROR
  // ============================================================

  void _dialogError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomTap(
    BuildContext context,
    int index,
  ) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
        break;

      case 1:
        Navigator.pushReplacementNamed(
          context,
          '/reminder',
        );
        break;

      case 2:
        Navigator.pushReplacementNamed(
          context,
          '/finder',
        );
        break;

      case 3:
        Navigator.pushReplacementNamed(
          context,
          '/sos',
        );
        break;

      case 4:
        Navigator.pushReplacementNamed(
          context,
          '/profile',
        );
        break;
    }
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
        child: RefreshIndicator(
          onRefresh: _loadReminders,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Reminders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your reminders',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 40,
                      ),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  _errorState()
                else if (reminders.isEmpty)
                  _emptyState()
                else
                  ...reminders.map(_card),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 42,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadReminders,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 50,
            color: primaryBlue,
          ),
          const SizedBox(height: 12),
          const Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your medicine and appointment reminders will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card(
    Map<String, dynamic> item,
  ) {
    final bool isMedicine = item['type'] == 'pill';

    final bool active = item['active'] == true;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.03,
            ),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // ICON
          // ======================================================

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _iconBackground,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              isMedicine
                  ? Icons.medication_outlined
                  : Icons.calendar_today_outlined,
              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _timeBadgeBackground,
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Text(
                    item['time'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'],
                  style: TextStyle(
                    fontSize: 13,
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _action(
                          'Edit',
                          () => _editReminder(
                            item,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        _action(
                          'Delete',
                          () => _delete(
                            item,
                          ),
                          isDelete: true,
                        ),
                      ],
                    ),
                    Switch(
                      value: active,
                      onChanged: (value) {
                        _toggleReminder(
                          item,
                          value,
                        );
                      },
                      activeColor: Colors.white,
                      activeTrackColor: primaryBlue,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: _isDark
                          ? const Color(0xFF4A4A4A)
                          : Colors.grey.shade300,
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

  // ============================================================
  // ACTION
  // ============================================================

  Widget _action(
    String text,
    VoidCallback onTap, {
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 4,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDelete ? Colors.red : primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
