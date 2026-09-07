import 'package:flutter/material.dart';
import 'package:medelyra/services/theme_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/nav_bar.dart';
import '../services/notification_service.dart';
import '../services/local_database_service.dart';

class PillReminderPage extends StatefulWidget {
  const PillReminderPage({super.key});

  @override
  State<PillReminderPage> createState() => _PillReminderPageState();
}

class _PillReminderPageState extends State<PillReminderPage> {
  final TextEditingController medicineNameController = TextEditingController();

  final TextEditingController doseController = TextEditingController();

  final TextEditingController instructionsController = TextEditingController();

  String selectedType = 'Pill';
  String selectedDuration = '7 Days';
  String selectedFrequency = 'Once Daily';

  DateTime selectedStartDate = DateTime.now();

  final List<TimeOfDay> selectedTimes = [
    TimeOfDay.now(),
  ];

  bool isSaving = false;

  final List<Map<String, dynamic>> medicineTypes = [
    {'label': 'Pill', 'icon': Icons.medication},
    {'label': 'Injection', 'icon': Icons.vaccines},
    {'label': 'Cream', 'icon': Icons.spa},
    {'label': 'Drop', 'icon': Icons.opacity},
    {'label': 'Inhaler', 'icon': Icons.air},
    {'label': 'Bandage', 'icon': Icons.healing},
    {'label': 'Syrup', 'icon': Icons.local_drink},
    {'label': 'Other', 'icon': Icons.medical_information},
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

  @override
  void dispose() {
    medicineNameController.dispose();
    doseController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // FREQUENCY
  // ------------------------------------------------------------

  void _changeFrequency(String value) {
    setState(() {
      selectedFrequency = value;

      switch (value) {
        case 'Once Daily':
          selectedTimes
            ..clear()
            ..add(TimeOfDay.now());
          break;

        case 'Twice Daily':
          selectedTimes
            ..clear()
            ..add(const TimeOfDay(hour: 8, minute: 0))
            ..add(const TimeOfDay(hour: 20, minute: 0));
          break;

        case '3 Times Daily':
          selectedTimes
            ..clear()
            ..add(const TimeOfDay(hour: 8, minute: 0))
            ..add(const TimeOfDay(hour: 14, minute: 0))
            ..add(const TimeOfDay(hour: 20, minute: 0));
          break;

        case '4 Times Daily':
          selectedTimes
            ..clear()
            ..add(const TimeOfDay(hour: 8, minute: 0))
            ..add(const TimeOfDay(hour: 12, minute: 0))
            ..add(const TimeOfDay(hour: 16, minute: 0))
            ..add(const TimeOfDay(hour: 20, minute: 0));
          break;

        case 'Every 8 Hours':
          selectedTimes
            ..clear()
            ..add(const TimeOfDay(hour: 8, minute: 0));
          break;

        case 'Every 12 Hours':
          selectedTimes
            ..clear()
            ..add(const TimeOfDay(hour: 8, minute: 0));
          break;

        case 'As Needed':
          selectedTimes.clear();
          break;

        case 'Custom Schedule':
          selectedTimes
            ..clear()
            ..add(TimeOfDay.now());
          break;
      }
    });
  }

  // ------------------------------------------------------------
  // TIME PICKER
  // ------------------------------------------------------------

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index],
    );

    if (picked != null) {
      setState(() {
        selectedTimes[index] = picked;
      });
    }
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTimes.add(picked);
      });
    }
  }

  void _removeCustomTime(int index) {
    if (selectedTimes.length <= 1) return;

    setState(() {
      selectedTimes.removeAt(index);
    });
  }

  // ------------------------------------------------------------
  // START DATE
  // ------------------------------------------------------------

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked;
      });
    }
  }

  // ------------------------------------------------------------
  // CALCULATE TIMES
  // ------------------------------------------------------------

  List<TimeOfDay> _getFinalTimes() {
    if (selectedFrequency == 'As Needed') {
      return [];
    }

    if (selectedFrequency == 'Every 8 Hours') {
      final start = selectedTimes.first;

      return [
        start,
        _addHours(start, 8),
        _addHours(start, 16),
      ];
    }

    if (selectedFrequency == 'Every 12 Hours') {
      final start = selectedTimes.first;

      return [
        start,
        _addHours(start, 12),
      ];
    }

    return selectedTimes;
  }

  TimeOfDay _addHours(TimeOfDay time, int hours) {
    final totalMinutes = time.hour * 60 + time.minute + hours * 60;

    final normalizedMinutes = totalMinutes % (24 * 60);

    return TimeOfDay(
      hour: normalizedMinutes ~/ 60,
      minute: normalizedMinutes % 60,
    );
  }

  // ------------------------------------------------------------
  // FORMAT TIME FOR LOCAL DATABASE
  // ------------------------------------------------------------

  String _formatTimeForDatabase(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ------------------------------------------------------------
  // DURATION
  // ------------------------------------------------------------

  int? _durationInDays() {
    switch (selectedDuration) {
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

  // ------------------------------------------------------------
  // SAVE REMINDER LOCALLY
  // ------------------------------------------------------------

  Future<void> _saveReminder() async {
    if (isSaving) return;

    final medicineName = medicineNameController.text.trim();
    final dose = doseController.text.trim();
    final instructions = instructionsController.text.trim();

    if (medicineName.isEmpty) {
      _showMessage('Please enter the medicine name.');
      return;
    }

    if (dose.isEmpty) {
      _showMessage('Please enter the dose or amount.');
      return;
    }

    if (selectedFrequency == 'Custom Schedule' && selectedTimes.isEmpty) {
      _showMessage('Please add at least one reminder time.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in before adding a reminder.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final finalTimes = _getFinalTimes();

      final durationDays = _durationInDays();

      DateTime? endDate;

      if (durationDays != null) {
        endDate = DateTime(
          selectedStartDate.year,
          selectedStartDate.month,
          selectedStartDate.day,
        ).add(
          Duration(days: durationDays - 1),
        );
      }

      final startDate = DateTime(
        selectedStartDate.year,
        selectedStartDate.month,
        selectedStartDate.day,
      );

      final now = DateTime.now();

      // Stable local ID.
      final medicineId =
          '${now.microsecondsSinceEpoch}_${medicineName.hashCode}';

      final medicineData = <String, dynamic>{
        'id': medicineId,
        'userId': user.uid,
        'medicineName': medicineName,
        'medicineType': selectedType,
        'dose': dose,
        'instructions': instructions,
        'frequency': selectedFrequency,

        // SQLite stores this as a single String.
        // Example: "08:00,20:00"
        'times': finalTimes.map(_formatTimeForDatabase).join(','),

        'duration': selectedDuration,
        'durationDays': durationDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // ----------------------------------------------------------
      // SAVE TO LOCAL SQLITE DATABASE
      // ----------------------------------------------------------

      await LocalDatabaseService.instance.insertMedicine(
        medicineData,
      );

      // ----------------------------------------------------------
      // REQUEST NOTIFICATION PERMISSION
      // ----------------------------------------------------------

      await NotificationService.instance.requestPermission();

      // ----------------------------------------------------------
      // SCHEDULE MEDICINE NOTIFICATIONS
      // ----------------------------------------------------------

      if (finalTimes.isNotEmpty) {
        final daysToSchedule = durationDays ?? 30;

        for (int day = 0; day < daysToSchedule; day++) {
          final date = startDate.add(
            Duration(days: day),
          );

          for (int timeIndex = 0; timeIndex < finalTimes.length; timeIndex++) {
            final time = finalTimes[timeIndex];

            final scheduledTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );

            // Don't schedule notifications that are already
            // in the past.
            if (scheduledTime.isBefore(DateTime.now())) {
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

      if (!mounted) return;

      _showMessage(
        'Medicine reminder added successfully.',
        success: true,
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not save reminder. Please try again.',
      );

      debugPrint('Save reminder error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF3D84A8) : Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ThemeService.surface(context, const Color(0xFFF6F6F6)),
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
                  'New Reminder',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // MEDICINE TYPE
              // --------------------------------------------------

              const Text(
                'Medicine Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: medicineTypes.map((item) {
                  final isSelected = selectedType == item['label'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = item['label'];
                      });
                    },
                    child: Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF3D84A8) : Colors.white,
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
                              fontSize: 11,
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

              // --------------------------------------------------
              // MEDICINE NAME
              // --------------------------------------------------

              const Text(
                'Medicine Name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: medicineNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter medicine name',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // DOSE
              // --------------------------------------------------

              const Text(
                'Dose / Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: doseController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Example: 1 tablet, 5 ml',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // FREQUENCY
              // --------------------------------------------------

              const Text(
                'Frequency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _dropdown(
                frequencyOptions,
                selectedFrequency,
                _changeFrequency,
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // TIMES
              // --------------------------------------------------

              if (selectedFrequency != 'As Needed') ...[
                const Text(
                  'Reminder Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedFrequency == 'Every 8 Hours')
                  _infoBox(
                    'Choose the starting time. '
                    'The next reminders will be 8 hours apart.',
                  ),
                if (selectedFrequency == 'Every 12 Hours')
                  _infoBox(
                    'Choose the starting time. '
                    'The second reminder will be 12 hours later.',
                  ),
                ..._buildTimeFields(),
                if (selectedFrequency == 'Custom Schedule') ...[
                  const SizedBox(height: 8),
                  _addTimeButton(),
                ],
              ] else ...[
                _infoBox(
                  'This medicine does not have a fixed time. '
                  'Use the instructions provided by your doctor '
                  'or pharmacist.',
                ),
              ],

              const SizedBox(height: 20),

              // --------------------------------------------------
              // START DATE
              // --------------------------------------------------

              const Text(
                'Start Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: _pickStartDate,
                child: _input(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedStartDate.day}/'
                        '${selectedStartDate.month}/'
                        '${selectedStartDate.year}',
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // DURATION
              // --------------------------------------------------

              const Text(
                'Duration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _dropdown(
                durationOptions,
                selectedDuration,
                (value) {
                  setState(() {
                    selectedDuration = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // INSTRUCTIONS
              // --------------------------------------------------

              const Text(
                'Instructions (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                child: TextField(
                  controller: instructionsController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Example: Take after food',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --------------------------------------------------
              // SAVE
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D84A8),
                    disabledBackgroundColor: const Color(0xFF9DBDCA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Reminder',
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

  // ------------------------------------------------------------
  // TIME FIELDS
  // ------------------------------------------------------------

  List<Widget> _buildTimeFields() {
    final List<Widget> widgets = [];

    if (selectedFrequency == 'Every 8 Hours' ||
        selectedFrequency == 'Every 12 Hours') {
      widgets.add(
        _timeField(
          index: 0,
          label: 'Starting Time',
        ),
      );

      final finalTimes = _getFinalTimes();

      if (finalTimes.length > 1) {
        widgets.add(
          const SizedBox(height: 10),
        );

        widgets.add(
          _schedulePreview(finalTimes),
        );
      }

      return widgets;
    }

    for (int i = 0; i < selectedTimes.length; i++) {
      String label;

      if (selectedTimes.length == 1) {
        label = 'Time';
      } else {
        label = 'Dose ${i + 1}';
      }

      widgets.add(
        _timeField(
          index: i,
          label: label,
          allowDelete: selectedFrequency == 'Custom Schedule',
        ),
      );

      if (i < selectedTimes.length - 1) {
        widgets.add(
          const SizedBox(height: 10),
        );
      }
    }

    return widgets;
  }

  Widget _timeField({
    required int index,
    required String label,
    bool allowDelete = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickTime(index),
          child: _input(
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF3D84A8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedTimes[index].format(context),
                  ),
                ),
                if (allowDelete)
                  IconButton(
                    onPressed: () => _removeCustomTime(index),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _schedulePreview(
    List<TimeOfDay> times,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your reminder times',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D84A8),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.map((time) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _addTimeButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _addCustomTime,
        icon: const Icon(
          Icons.add,
          color: Color(0xFF3D84A8),
        ),
        label: const Text(
          'Add Another Time',
          style: TextStyle(
            color: Color(0xFF3D84A8),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF3D84A8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO BOX
  // ------------------------------------------------------------

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFF3D84A8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3D84A8),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INPUT
  // ------------------------------------------------------------

  Widget _input({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // DROPDOWN
  // ------------------------------------------------------------

  Widget _dropdown(
    List<String> items,
    String value,
    Function(String) onChanged,
  ) {
    return _input(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
