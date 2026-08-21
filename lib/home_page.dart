import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryBlue = const Color(0xFF3D84A8);
  final Color green = const Color(0xFF43A047);
  final Color red = const Color(0xFFEF5350);
  final Color orange = const Color(0xFFF59E0B);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool showMedicines = true;

  DateTime selectedDate = DateTime.now();

  // We show 90 days:
  // 30 days before today + today + 60 days after today.
  List<DateTime> availableDates = [];
  int selectedDayIndex = 30;

  @override
  void initState() {
    super.initState();

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    availableDates = List.generate(
      91,
      (index) =>
          today.subtract(const Duration(days: 30)).add(Duration(days: index)),
    );

    selectedDate = today;
    selectedDayIndex = 30;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // NAVIGATION
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
  // DATE HELPERS
  // ============================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _dayName(DateTime date) {
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return days[date.weekday - 1];
  }

  // ============================================================
  // FIRESTORE STREAMS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _medicineStream() {
    final uid = currentUserId;

    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('medicines')
        .where('userId', isEqualTo: uid)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentStream() {
    final uid = currentUserId;

    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // ============================================================
  // MEDICINE DATE CHECK
  // ============================================================

  bool _medicineIsForDate(
    Map<String, dynamic> data,
    DateTime date,
  ) {
    DateTime? startDate;
    DateTime? endDate;

    final start = data['startDate'];
    final end = data['endDate'];

    if (start is Timestamp) {
      startDate = start.toDate();
    } else if (start is DateTime) {
      startDate = start;
    }

    if (end is Timestamp) {
      endDate = end.toDate();
    } else if (end is DateTime) {
      endDate = end;
    }

    if (startDate == null) {
      return true;
    }

    final day = _dateOnly(date);
    final startDay = _dateOnly(startDate);

    if (day.isBefore(startDay)) {
      return false;
    }

    if (endDate != null) {
      final endDay = _dateOnly(endDate);

      if (day.isAfter(endDay)) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // APPOINTMENT DATE CHECK
  // ============================================================

  bool _appointmentIsForDate(
    Map<String, dynamic> data,
    DateTime date,
  ) {
    final value = data['dateTime'];

    DateTime? appointmentDate;

    if (value is Timestamp) {
      appointmentDate = value.toDate();
    } else if (value is DateTime) {
      appointmentDate = value;
    }

    if (appointmentDate == null) {
      return false;
    }

    return _sameDate(
      appointmentDate,
      date,
    );
  }

  // ============================================================
  // MEDICINE TIMES
  // ============================================================

  String _formatFirestoreTime(dynamic value) {
    if (value == null) {
      return '';
    }

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date != null) {
      return TimeOfDay.fromDateTime(date).format(context);
    }

    if (value is String) {
      return value;
    }

    return '';
  }

  List<String> _medicineTimes(
    Map<String, dynamic> data,
  ) {
    final times = data['times'];

    if (times is List && times.isNotEmpty) {
      final result = times
          .map((time) => _formatFirestoreTime(time))
          .where((time) => time.isNotEmpty)
          .toList();

      if (result.isNotEmpty) {
        return result;
      }
    }

    final singleTime = data['time'];

    if (singleTime != null) {
      final result = _formatFirestoreTime(singleTime);

      if (result.isNotEmpty) {
        return [result];
      }
    }

    return [];
  }

  // ============================================================
  // DOSE KEY
  //
  // Every dose gets its own key:
  //
  // 2026-08-21_8_00_AM
  // 2026-08-21_9_00_PM
  //
  // This means taking the morning dose does NOT mark the
  // evening dose as taken.
  // ============================================================

  String _doseKey(
    DateTime date,
    String time,
  ) {
    final safeTime = time
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_')
        .replaceAll('/', '_');

    return '${_dateKey(date)}_$safeTime';
  }

  // ============================================================
  // GET DOSE STATUS
  // ============================================================

  Map<String, dynamic>? _getDoseStatus(
    Map<String, dynamic> medicine,
    String time,
  ) {
    final dailyStatus = medicine['dailyStatus'];

    if (dailyStatus is! Map) {
      return null;
    }

    final key = _doseKey(
      selectedDate,
      time,
    );

    final status = dailyStatus[key];

    if (status is Map) {
      return Map<String, dynamic>.from(status);
    }

    return null;
  }

  // ============================================================
  // SAVE DOSE STATUS
  // ============================================================

  Future<void> _saveDoseStatus({
    required String medicineId,
    required String time,
    required String status,
    DateTime? postponedUntil,
  }) async {
    try {
      final ref = _firestore.collection('medicines').doc(medicineId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('Medicine no longer exists.');
        }

        final data = snapshot.data() as Map<String, dynamic>;

        final existing = data['dailyStatus'];

        final Map<String, dynamic> dailyStatus =
            existing is Map ? Map<String, dynamic>.from(existing) : {};

        final key = _doseKey(
          selectedDate,
          time,
        );

        final Map<String, dynamic> newStatus = {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (postponedUntil != null) {
          newStatus['postponedUntil'] = Timestamp.fromDate(postponedUntil);
        }

        dailyStatus[key] = newStatus;

        transaction.update(
          ref,
          {
            'dailyStatus': dailyStatus,
          },
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update reminder: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // TAKEN
  // ============================================================

  Future<void> _markMedicineTaken({
    required String medicineId,
    required String time,
  }) async {
    await _saveDoseStatus(
      medicineId: medicineId,
      time: time,
      status: 'taken',
    );
  }

  // ============================================================
  // SKIP
  // ============================================================

  Future<void> _skipMedicine({
    required String medicineId,
    required String time,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Skip this dose?'),
          content: Text(
            'This will mark the $time dose as skipped for '
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Skip Dose',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _saveDoseStatus(
      medicineId: medicineId,
      time: time,
      status: 'skipped',
    );
  }

  // ============================================================
  // POSTPONE
  // ============================================================

  Future<void> _postponeMedicine({
    required String medicineId,
    required String time,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Choose a new reminder time',
    );

    if (selected == null) {
      return;
    }

    final postponedUntil = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selected.hour,
      selected.minute,
    );

    await _saveDoseStatus(
      medicineId: medicineId,
      time: time,
      status: 'postponed',
      postponedUntil: postponedUntil,
    );
  }

  // ============================================================
  // APPOINTMENT COMPLETED
  // ============================================================

  Future<void> _markAppointmentDone(
    String appointmentId,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update appointment: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0,
        onTap: (index) => _onBottomTap(
          context,
          index,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ==================================================
              // MONTH
              // ==================================================

              Text(
                '${_monthName(selectedDate.month)} '
                '${selectedDate.year}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF323232),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DATE SCROLLER
              // ==================================================

              SizedBox(
                height: 78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableDates.length,
                  itemBuilder: (_, index) {
                    final date = availableDates[index];

                    final selected = _sameDate(date, selectedDate);

                    final isToday = _sameDate(date, DateTime.now());

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDayIndex = index;
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.only(
                          right: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected ? const Color(0xFF5891FA) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayName(date),
                              style: TextStyle(
                                fontSize: 14,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: selected ? Colors.white : primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // TABS
              // ==================================================

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tab(
                      'Medicines',
                      showMedicines,
                      () {
                        setState(() {
                          showMedicines = true;
                        });
                      },
                    ),
                    _tab(
                      'Appointment',
                      !showMedicines,
                      () {
                        setState(() {
                          showMedicines = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // CONTENT
              // ==================================================

              if (currentUserId == null)
                _emptyState(
                  icon: Icons.login,
                  title: 'Please log in',
                  message: 'Log in to see your reminders.',
                )
              else if (showMedicines)
                _buildMedicines()
              else
                _buildAppointments(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINES
  // ============================================================

  Widget _buildMedicines() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _medicineStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _emptyState(
            icon: Icons.error_outline,
            title: 'Could not load medicines',
            message: 'Please check your connection and try again.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filtered = docs.where((doc) {
          return _medicineIsForDate(
            doc.data(),
            selectedDate,
          );
        }).toList();

        if (filtered.isEmpty) {
          return _emptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines on this date',
            message: 'You have no active medicine reminders for this day.',
          );
        }

        return Column(
          children: filtered.map((doc) {
            return _medicineCard(
              doc.id,
              doc.data(),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // MEDICINE CARD
  // ============================================================

  Widget _medicineCard(
    String documentId,
    Map<String, dynamic> item,
  ) {
    final medicineName = item['medicineName']?.toString() ?? 'Medicine';

    final dose = item['dose']?.toString() ?? '';

    final instructions = item['instructions']?.toString() ?? '';

    final frequency = item['frequency']?.toString() ?? '';

    final times = _medicineTimes(item);

    final subtitleParts = <String>[];

    if (dose.isNotEmpty) {
      subtitleParts.add(dose);
    }

    if (instructions.isNotEmpty) {
      subtitleParts.add(instructions);
    }

    if (frequency.isNotEmpty) {
      subtitleParts.add(frequency);
    }

    final subtitle = subtitleParts.join(' • ');

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ICON
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Color(0xFF3D84A8),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF868686),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // EACH DOSE
          // ======================================================

          ...times.map(
            (time) => _doseRow(
              medicineId: documentId,
              medicineName: medicineName,
              time: time,
              medicineData: item,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOSE ROW
  // ============================================================

  Widget _doseRow({
    required String medicineId,
    required String medicineName,
    required String time,
    required Map<String, dynamic> medicineData,
  }) {
    final status = _getDoseStatus(
      medicineData,
      time,
    );

    final statusValue = status?['status']?.toString();

    String? postponedText;

    if (statusValue == 'postponed') {
      final postponed = status?['postponedUntil'];

      if (postponed is Timestamp) {
        postponedText = TimeOfDay.fromDateTime(
          postponed.toDate(),
        ).format(context);
      }
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME + STATUS
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 19,
                color: statusValue == 'taken'
                    ? green
                    : statusValue == 'skipped'
                        ? red
                        : statusValue == 'postponed'
                            ? orange
                            : primaryBlue,
              ),
              const SizedBox(width: 7),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _statusBadge(
                statusValue,
                postponedText,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ====================================================
          // ACTIONS
          // ====================================================

          if (statusValue == 'taken')
            _takenButton()
          else if (statusValue == 'skipped')
            _skippedButton()
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        _markMedicineTaken(
                          medicineId: medicineId,
                          time: time,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Mark as Taken',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // POSTPONE
                InkWell(
                  onTap: () {
                    _postponeMedicine(
                      medicineId: medicineId,
                      time: time,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    child: Text(
                      'Postpone',
                      style: TextStyle(
                        color: Color(0xFF3D84A8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // SKIP
                InkWell(
                  onTap: () {
                    _skipMedicine(
                      medicineId: medicineId,
                      time: time,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // ====================================================
          // POSTPONED ACTION
          // ====================================================

          if (statusValue == 'postponed') ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reminder moved to '
                    '${postponedText ?? 'new time'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _markMedicineTaken(
                      medicineId: medicineId,
                      time: time,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      'Take Now',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String? status,
    String? postponedTime,
  ) {
    if (status == 'taken') {
      return _badge(
        'Taken',
        green,
      );
    }

    if (status == 'skipped') {
      return _badge(
        'Skipped',
        red,
      );
    }

    if (status == 'postponed') {
      return _badge(
        postponedTime != null ? 'Postponed • $postponedTime' : 'Postponed',
        orange,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _badge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // TAKEN BUTTON
  // ============================================================

  Widget _takenButton() {
    return Container(
      width: double.infinity,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 18,
          ),
          SizedBox(width: 6),
          Text(
            'Taken',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SKIPPED BUTTON
  // ============================================================

  Widget _skippedButton() {
    return Container(
      width: double.infinity,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_circle_outline,
            color: Color(0xFFEF5350),
            size: 18,
          ),
          SizedBox(width: 6),
          Text(
            'Skipped',
            style: TextStyle(
              color: Color(0xFFEF5350),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPOINTMENTS
  // ============================================================

  Widget _buildAppointments() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _appointmentStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _emptyState(
            icon: Icons.error_outline,
            title: 'Could not load appointments',
            message: 'Please check your connection and try again.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filtered = docs.where((doc) {
          return _appointmentIsForDate(
            doc.data(),
            selectedDate,
          );
        }).toList();

        if (filtered.isEmpty) {
          return _emptyState(
            icon: Icons.calendar_today_outlined,
            title: 'No appointments on this date',
            message: 'You have no appointments scheduled for this day.',
          );
        }

        return Column(
          children: filtered.map((doc) {
            return _appointmentCard(
              doc.id,
              doc.data(),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _appointmentCard(
    String documentId,
    Map<String, dynamic> item,
  ) {
    final title = item['appointmentType']?.toString() ?? 'Appointment';

    final hospital = item['hospital']?.toString() ?? '';

    final reason = item['reason']?.toString() ?? '';

    final value = item['dateTime'];

    DateTime? dateTime;

    if (value is Timestamp) {
      dateTime = value.toDate();
    }

    String timeText = 'Time not set';

    if (dateTime != null) {
      timeText = TimeOfDay.fromDateTime(
        dateTime,
      ).format(context);
    }

    final completed = item['completedAt'] != null;

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
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: completed ? green : primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(
                  timeText,
                  completed ? green : red,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hospital.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hospital,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (completed)
                  Container(
                    width: double.infinity,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 38,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _markAppointmentDone(
                          documentId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Mark as Completed',
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
    );
  }

  // ============================================================
  // TAB
  // ============================================================

  Widget _tab(
    String text,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: active
                ? const Color.fromARGB(
                    50,
                    88,
                    145,
                    250,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active
                    ? const Color(
                        0xFF5891FA,
                      )
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
