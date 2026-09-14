import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/local_database_service.dart';
import '../services/local_appointment_service.dart';
import '../services/notification_service.dart';
import '../widgets/nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ============================================================
  // LOCALIZATION
  // ============================================================

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  // ============================================================
  // STATUS COLORS
  // ============================================================

  final Color primaryBlue = const Color(0xFF3D84A8);
  final Color green = const Color(0xFF43A047);
  final Color red = const Color(0xFFEF5350);
  final Color orange = const Color(0xFFF59E0B);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool showMedicines = true;
  bool _isLoading = true;

  DateTime selectedDate = DateTime.now();

  // ============================================================
  // THEME COLORS
  //
  // These automatically change depending on light/dark mode.
  // Light mode values are kept close to the original design.
  // ============================================================

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6FA);

  Color get _cardColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _secondaryCardColor =>
      _isDarkMode ? const Color(0xFF242424) : const Color(0xFFF8F9FC);

  Color get _dateCardColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _iconBackgroundColor =>
      _isDarkMode ? const Color(0xFF263B44) : const Color(0xFFEFF2FA);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF2F2F2) : const Color(0xFF323232);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFB5B5B5) : const Color(0xFF868686);

  Color get _tabBackgroundColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _inactiveTabColor =>
      _isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;

  // ============================================================
  // LOCAL DATA
  // ============================================================

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _appointments = [];

  // Key:
  // medicineId + date + time
  Map<String, Map<String, dynamic>> _doseStatuses = {};

  // ============================================================
  // HOME DATE RANGE
  // ============================================================

  List<DateTime> availableDates = [];
  int selectedDayIndex = 2;

  @override
  void initState() {
    super.initState();

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    availableDates = List.generate(
      33,
      (index) {
        return today
            .subtract(const Duration(days: 2))
            .add(Duration(days: index));
      },
    );

    selectedDate = today;
    selectedDayIndex = 2;

    _loadHomeData();
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
  // LOAD HOME DATA
  // ============================================================

  Future<void> _loadHomeData() async {
    final uid = currentUserId;

    if (uid == null) {
      if (!mounted) return;

      setState(() {
        _medicines = [];
        _appointments = [];
        _doseStatuses = {};
        _isLoading = false;
      });

      return;
    }

    try {
      final medicines = await LocalDatabaseService.instance.getMedicines(uid);

      final appointments =
          await LocalAppointmentService.instance.getAppointments(uid);

      final doseStatuses =
          await LocalDatabaseService.instance.getMedicineDoseStatusesForDate(
        userId: uid,
        date: _dateKey(selectedDate),
      );

      final Map<String, Map<String, dynamic>> statusMap = {};

      for (final status in doseStatuses) {
        final medicineId = status['medicineId']?.toString() ?? '';
        final date = status['date']?.toString() ?? '';
        final time = status['time']?.toString() ?? '';

        if (medicineId.isEmpty || date.isEmpty || time.isEmpty) {
          continue;
        }

        final key = _localDoseKey(
          medicineId: medicineId,
          date: date,
          time: time,
        );

        statusMap[key] = status;
      }

      if (!mounted) return;

      setState(() {
        _medicines = medicines;
        _appointments = appointments;
        _doseStatuses = statusMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('HOME LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotLoadReminders(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  String _monthName(DateTime date) {
    return DateFormat(
      'MMMM',
      _l10n.localeName,
    ).format(date);
  }

  String _dayName(DateTime date) {
    return DateFormat(
      'EEE',
      _l10n.localeName,
    ).format(date);
  }

  // ============================================================
  // MEDICINE TYPE ICON
  // ============================================================

  IconData _medicineTypeIcon(dynamic type) {
    final value = type?.toString().toLowerCase().trim();

    if (value == null || value.isEmpty) {
      return Icons.medication_outlined;
    }

    if (value.contains('pill') || value.contains('tablet')) {
      return Icons.medication_outlined;
    }

    if (value.contains('capsule')) {
      return Icons.medication_liquid_outlined;
    }

    if (value.contains('syringe') || value.contains('injection')) {
      return Icons.vaccines_outlined;
    }

    if (value.contains('liquid') ||
        value.contains('syrup') ||
        value.contains('solution')) {
      return Icons.local_drink_outlined;
    }

    if (value.contains('drop')) {
      return Icons.visibility_outlined;
    }

    if (value.contains('cream') || value.contains('ointment')) {
      return Icons.sanitizer_outlined;
    }

    if (value.contains('inhaler')) {
      return Icons.air_outlined;
    }

    return Icons.medication_outlined;
  }

  // ============================================================
  // APPOINTMENT TYPE ICON
  // ============================================================

  IconData _appointmentTypeIcon(dynamic type) {
    final value = type?.toString().toLowerCase().trim();

    switch (value) {
      case 'general':
        return Icons.local_hospital_outlined;

      case 'eye':
      case 'ophthalmology':
        return Icons.remove_red_eye_outlined;

      case 'dental':
      case 'dentist':
        return Icons.medical_services_outlined;

      case 'heart':
      case 'cardiology':
        return Icons.favorite_outline;

      default:
        return Icons.calendar_today_outlined;
    }
  }

  // ============================================================
  // LOCAL DOSE KEY
  // ============================================================

  String _localDoseKey({
    required String medicineId,
    required String date,
    required String time,
  }) {
    return '$medicineId|$date|$time';
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

    if (start is DateTime) {
      startDate = start;
    } else if (start is String && start.isNotEmpty) {
      startDate = DateTime.tryParse(start);
    }

    if (end is DateTime) {
      endDate = end;
    } else if (end is String && end.isNotEmpty) {
      endDate = DateTime.tryParse(end);
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

    if (value is DateTime) {
      appointmentDate = value;
    } else if (value is String && value.isNotEmpty) {
      appointmentDate = DateTime.tryParse(value);
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
  // MEDICINE TIME FORMAT
  // ============================================================

  String _formatLocalTime(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    final upper = trimmed.toUpperCase();

    if (upper.contains('AM') || upper.contains('PM')) {
      return trimmed;
    }

    final parts = trimmed.split(':');

    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        final time = TimeOfDay(
          hour: hour,
          minute: minute,
        );

        return time.format(context);
      }
    }

    return trimmed;
  }

  // ============================================================
  // MEDICINE TIMES
  // ============================================================

  List<String> _medicineTimes(
    Map<String, dynamic> data,
  ) {
    final times = data['times'];

    if (times is String && times.trim().isNotEmpty) {
      return times
          .split(',')
          .map((time) => _formatLocalTime(time))
          .where((time) => time.isNotEmpty)
          .toList();
    }

    if (times is List && times.isNotEmpty) {
      final result = times
          .map((time) {
            if (time is String) {
              return _formatLocalTime(time);
            }

            return time?.toString() ?? '';
          })
          .where((time) => time.isNotEmpty)
          .toList();

      if (result.isNotEmpty) {
        return result;
      }
    }

    final singleTime = data['time'];

    if (singleTime is String && singleTime.isNotEmpty) {
      return [_formatLocalTime(singleTime)];
    }

    return [];
  }

  // ============================================================
  // GET DOSE STATUS
  // ============================================================

  Map<String, dynamic>? _getDoseStatus(
    String medicineId,
    String time,
  ) {
    final date = _dateKey(selectedDate);

    final key = _localDoseKey(
      medicineId: medicineId,
      date: date,
      time: time,
    );

    return _doseStatuses[key];
  }

  // ============================================================
  // MEDICINE NOTIFICATION ID
  // ============================================================

  int _medicineNotificationId({
    required String medicineId,
    required DateTime date,
    required int timeIndex,
  }) {
    return NotificationService.instance.medicineNotificationId(
      medicineId: medicineId,
      date: date,
      timeIndex: timeIndex,
    );
  }

  // ============================================================
  // FIND MEDICINE TIME INDEX
  // ============================================================

  int _medicineTimeIndex({
    required Map<String, dynamic> medicine,
    required String time,
  }) {
    final times = _medicineTimes(medicine);

    final index = times.indexOf(time);

    if (index >= 0) {
      return index;
    }

    return 0;
  }

  // ============================================================
  // CANCEL ORIGINAL DOSE NOTIFICATION
  // ============================================================

  Future<void> _cancelOriginalDoseNotification({
    required String medicineId,
    required Map<String, dynamic> medicine,
    required String time,
  }) async {
    try {
      final timeIndex = _medicineTimeIndex(
        medicine: medicine,
        time: time,
      );

      final notificationId = _medicineNotificationId(
        medicineId: medicineId,
        date: selectedDate,
        timeIndex: timeIndex,
      );

      await NotificationService.instance.cancel(
        notificationId,
      );

      debugPrint(
        'Cancelled original medicine notification: '
        '$notificationId',
      );
    } catch (e) {
      debugPrint(
        'Could not cancel original medicine notification: $e',
      );
    }
  }

  // ============================================================
  // CANCEL EXISTING POSTPONED NOTIFICATION
  // ============================================================

  Future<void> _cancelExistingPostponedNotification({
    required String medicineId,
    required Map<String, dynamic>? status,
  }) async {
    if (status == null) {
      return;
    }

    final statusValue = status['status']?.toString();

    if (statusValue != 'postponed') {
      return;
    }

    final postponed = status['postponedUntil'];

    DateTime? postponedDate;

    if (postponed is DateTime) {
      postponedDate = postponed;
    } else if (postponed is String && postponed.isNotEmpty) {
      postponedDate = DateTime.tryParse(postponed);
    }

    if (postponedDate == null) {
      return;
    }

    final notificationId = _postponedNotificationId(
      medicineId: medicineId,
      postponedUntil: postponedDate,
    );

    await NotificationService.instance.cancel(
      notificationId,
    );

    debugPrint(
      'Cancelled previous postponed notification: '
      '$notificationId',
    );
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
    final uid = currentUserId;

    if (uid == null) {
      return;
    }

    try {
      final date = _dateKey(selectedDate);

      await LocalDatabaseService.instance.upsertMedicineDoseStatus(
        medicineId: medicineId,
        userId: uid,
        date: date,
        time: time,
        status: status,
        postponedUntil: postponedUntil,
      );

      await _loadHomeData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotUpdateReminder(e.toString()),
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
    required String medicineName,
    required String time,
  }) async {
    try {
      Map<String, dynamic>? medicine;

      for (final item in _medicines) {
        if (item['id']?.toString() == medicineId) {
          medicine = item;
          break;
        }
      }

      if (medicine != null) {
        await _cancelOriginalDoseNotification(
          medicineId: medicineId,
          medicine: medicine,
          time: time,
        );

        final existingStatus = _getDoseStatus(
          medicineId,
          time,
        );

        await _cancelExistingPostponedNotification(
          medicineId: medicineId,
          status: existingStatus,
        );
      }

      await _saveDoseStatus(
        medicineId: medicineId,
        time: time,
        status: 'taken',
      );
    } catch (e) {
      debugPrint(
        'MARK TAKEN ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotMarkMedicineTaken(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SKIP
  // ============================================================

  Future<void> _skipMedicine({
    required String medicineId,
    required String medicineName,
    required String time,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _l10n.skipThisDose,
          ),
          content: Text(
            _l10n.skipDoseConfirmation(
              time,
              DateFormat.yMd(
                _l10n.localeName,
              ).format(selectedDate),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                _l10n.cancel,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                _l10n.skipDose,
                style: const TextStyle(
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

    try {
      Map<String, dynamic>? medicine;

      for (final item in _medicines) {
        if (item['id']?.toString() == medicineId) {
          medicine = item;
          break;
        }
      }

      if (medicine != null) {
        await _cancelOriginalDoseNotification(
          medicineId: medicineId,
          medicine: medicine,
          time: time,
        );

        final existingStatus = _getDoseStatus(
          medicineId,
          time,
        );

        await _cancelExistingPostponedNotification(
          medicineId: medicineId,
          status: existingStatus,
        );
      }

      await _saveDoseStatus(
        medicineId: medicineId,
        time: time,
        status: 'skipped',
      );
    } catch (e) {
      debugPrint(
        'SKIP MEDICINE ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotSkipReminder(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // POSTPONED NOTIFICATION ID
  // ============================================================

  int _postponedNotificationId({
    required String medicineId,
    required DateTime postponedUntil,
  }) {
    return '${medicineId}_postponed_'
                '${postponedUntil.year}_'
                '${postponedUntil.month}_'
                '${postponedUntil.day}_'
                '${postponedUntil.hour}_'
                '${postponedUntil.minute}'
            .hashCode &
        0x7fffffff;
  }

  // ============================================================
  // SCHEDULE POSTPONED NOTIFICATION
  // ============================================================

  Future<void> _schedulePostponedNotification({
    required String medicineId,
    required String medicineName,
    required DateTime postponedUntil,
  }) async {
    final notificationId = _postponedNotificationId(
      medicineId: medicineId,
      postponedUntil: postponedUntil,
    );

    await NotificationService.instance.scheduleMedicineNotification(
      id: notificationId,
      medicineName: medicineName,
      scheduledTime: postponedUntil,
    );

    debugPrint(
      'Scheduled postponed notification: '
      '$notificationId at $postponedUntil',
    );
  }

  // ============================================================
  // POSTPONE
  // ============================================================

  Future<void> _postponeMedicine({
    required String medicineId,
    required String medicineName,
    required String time,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: _l10n.chooseNewReminderTime,
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

    if (!postponedUntil.isAfter(DateTime.now())) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.chooseLaterTime,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    try {
      final uid = currentUserId;

      if (uid == null) {
        return;
      }

      Map<String, dynamic>? medicine;

      for (final item in _medicines) {
        if (item['id']?.toString() == medicineId) {
          medicine = item;
          break;
        }
      }

      // Cancel original reminder.
      if (medicine != null) {
        await _cancelOriginalDoseNotification(
          medicineId: medicineId,
          medicine: medicine,
          time: time,
        );
      }

      // Cancel previous postponed reminder.
      final existingStatus = _getDoseStatus(
        medicineId,
        time,
      );

      await _cancelExistingPostponedNotification(
        medicineId: medicineId,
        status: existingStatus,
      );

      // Save postponed state.
      final date = _dateKey(selectedDate);

      await LocalDatabaseService.instance.upsertMedicineDoseStatus(
        medicineId: medicineId,
        userId: uid,
        date: date,
        time: time,
        status: 'postponed',
        postponedUntil: postponedUntil,
      );

      // Schedule only the new notification.
      await _schedulePostponedNotification(
        medicineId: medicineId,
        medicineName: medicineName,
        postponedUntil: postponedUntil,
      );

      await _loadHomeData();
    } catch (e) {
      debugPrint(
        'POSTPONE NOTIFICATION ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotPostponeReminder(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // APPOINTMENT COMPLETED
  // ============================================================

  Future<void> _markAppointmentDone(
    String appointmentId,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      await LocalAppointmentService.instance.markAppointmentCompleted(
        appointmentId,
        user.uid,
      );

      await _loadHomeData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n.couldNotUpdateAppointment(e.toString()),
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
      backgroundColor: _pageBackground,
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
                '${_monthName(selectedDate)} '
                '${selectedDate.year}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
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

                    final selected = _sameDate(
                      date,
                      selectedDate,
                    );

                    final isToday = _sameDate(
                      date,
                      DateTime.now(),
                    );

                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          selectedDayIndex = index;
                          selectedDate = date;
                          _isLoading = true;
                        });

                        await _loadHomeData();
                      },
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.only(
                          right: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF5891FA)
                              : _dateCardColor,
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayName(date),
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    selected ? Colors.white : _primaryTextColor,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                    selected ? Colors.white : _primaryTextColor,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                _l10n.today,
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
                  color: _tabBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tab(
                      _l10n.medicines,
                      showMedicines,
                      () {
                        setState(() {
                          showMedicines = true;
                        });
                      },
                    ),
                    _tab(
                      _l10n.appointment,
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
                  title: _l10n.pleaseLogIn,
                  message: _l10n.logInToSeeReminders,
                )
              else if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
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
    final filtered = _medicines.where((medicine) {
      final active = medicine['active'] == 1 || medicine['active'] == true;

      if (!active) {
        return false;
      }

      return _medicineIsForDate(
        medicine,
        selectedDate,
      );
    }).toList();

    if (filtered.isEmpty) {
      return _emptyState(
        icon: Icons.medication_outlined,
        title: _l10n.noMedicinesOnThisDate,
        message: _l10n.noActiveMedicineReminders,
      );
    }

    return Column(
      children: filtered.map((medicine) {
        final id = medicine['id']?.toString() ?? '';

        return _medicineCard(
          id,
          medicine,
        );
      }).toList(),
    );
  }

  // ============================================================
  // MEDICINE CARD
  // ============================================================

  Widget _medicineCard(
    String documentId,
    Map<String, dynamic> item,
  ) {
    final medicineName = item['medicineName']?.toString() ?? _l10n.medicine;

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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.03,
                  ),
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
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: _iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _medicineTypeIcon(
                    item['type'] ??
                        item['medicineType'] ??
                        item['medicationType'],
                  ),
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryTextColor,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...times.map(
            (time) => _doseRow(
              medicineId: documentId,
              medicineName: medicineName,
              medicine: item,
              time: time,
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
    required Map<String, dynamic> medicine,
    required String time,
  }) {
    final status = _getDoseStatus(
      medicineId,
      time,
    );

    final statusValue = status?['status']?.toString();

    String? postponedText;

    if (statusValue == 'postponed') {
      final postponed = status?['postponedUntil'];

      DateTime? postponedDate;

      if (postponed is DateTime) {
        postponedDate = postponed;
      } else if (postponed is String && postponed.isNotEmpty) {
        postponedDate = DateTime.tryParse(postponed);
      }

      if (postponedDate != null) {
        postponedText = TimeOfDay.fromDateTime(
          postponedDate,
        ).format(context);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _secondaryCardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
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
                          medicineName: medicineName,
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
                      child: Text(
                        _l10n.markAsTaken,
                        style: const TextStyle(
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
                      medicineName: medicineName,
                      time: time,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    child: Text(
                      _l10n.postpone,
                      style: TextStyle(
                        color: primaryBlue,
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
                      medicineName: medicineName,
                      time: time,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    child: Text(
                      _l10n.skip,
                      style: const TextStyle(
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
                    _l10n.reminderMovedTo(
                      postponedText ?? _l10n.newTime,
                    ),
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
                      medicineName: medicineName,
                      time: time,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      _l10n.takeNow,
                      style: const TextStyle(
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
        _l10n.taken,
        green,
      );
    }

    if (status == 'skipped') {
      return _badge(
        _l10n.skipped,
        red,
      );
    }

    if (status == 'postponed') {
      return _badge(
        postponedTime != null
            ? '${_l10n.postponed} • $postponedTime'
            : _l10n.postponed,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _l10n.taken,
            style: const TextStyle(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Color(0xFFEF5350),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _l10n.skipped,
            style: const TextStyle(
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
    final filtered = _appointments.where((appointment) {
      final active =
          appointment['active'] == 1 || appointment['active'] == true;

      if (!active) {
        return false;
      }

      return _appointmentIsForDate(
        appointment,
        selectedDate,
      );
    }).toList();

    if (filtered.isEmpty) {
      return _emptyState(
        icon: Icons.calendar_today_outlined,
        title: _l10n.noAppointmentsOnThisDate,
        message: _l10n.noAppointmentsScheduled,
      );
    }

    return Column(
      children: filtered.map((appointment) {
        final id = appointment['id']?.toString() ?? '';

        return _appointmentCard(
          id,
          appointment,
        );
      }).toList(),
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _appointmentCard(
    String documentId,
    Map<String, dynamic> item,
  ) {
    final title = item['appointmentType']?.toString() ?? _l10n.appointmentTitle;

    final hospital = item['hospital']?.toString() ?? '';

    final reason = item['reason']?.toString() ?? '';

    final value = item['dateTime'];

    DateTime? dateTime;

    if (value is DateTime) {
      dateTime = value;
    } else if (value is String && value.isNotEmpty) {
      dateTime = DateTime.tryParse(value);
    }

    String timeText = _l10n.timeNotSet;

    if (dateTime != null) {
      timeText = TimeOfDay.fromDateTime(
        dateTime,
      ).format(context);
    }

    final completed = item['completedAt'] != null &&
        item['completedAt'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _isDarkMode
            ? []
            : [
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
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: _iconBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _appointmentTypeIcon(
                item['appointmentType'],
              ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                  ),
                ),
                if (hospital.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hospital,
                    style: TextStyle(
                      fontSize: 13,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: _secondaryTextColor,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          _l10n.completed,
                          style: const TextStyle(
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
                      child: Text(
                        _l10n.markAsCompleted,
                        style: const TextStyle(
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
                    : _inactiveTabColor,
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
        color: _cardColor,
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
