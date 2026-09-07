import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    if (instance._initialized) return;

    tz.initializeTimeZones();

    final String timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo),
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await instance._notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: instance._onNotificationTapped,
    );

    instance._initialized = true;
  }

  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  void _onNotificationTapped(
    NotificationResponse response,
  ) {
    // Reserved for future navigation.
  }

  // ============================================================
  // ANDROID PERMISSION
  // ============================================================

  Future<bool> requestPermission() async {
    await initialize();

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      return false;
    }

    final notificationGranted =
        await androidImplementation.requestNotificationsPermission();

    final exactAlarmGranted =
        await androidImplementation.requestExactAlarmsPermission();

    return (notificationGranted ?? false) && (exactAlarmGranted ?? false);
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  Future<SharedPreferences> _getPreferences() async {
    return SharedPreferences.getInstance();
  }

  Future<bool> isMasterNotificationsEnabled() async {
    final prefs = await _getPreferences();
    return prefs.getBool('masterToggle') ?? true;
  }

  Future<bool> isMedicineReminderEnabled() async {
    final prefs = await _getPreferences();
    return prefs.getBool('medicineReminder') ?? true;
  }

  Future<bool> isMedicineSoundEnabled() async {
    final prefs = await _getPreferences();
    return prefs.getBool('medicineSound') ?? true;
  }

  Future<bool> isMedicineVibrationEnabled() async {
    final prefs = await _getPreferences();
    return prefs.getBool('medicineVibration') ?? true;
  }

  Future<bool> isAppointmentReminderEnabled() async {
    final prefs = await _getPreferences();
    return prefs.getBool('appointmentReminder') ?? true;
  }

  // ============================================================
  // APPOINTMENT REMINDER TIME
  // ============================================================

  Future<Duration> getAppointmentReminderDuration() async {
    final prefs = await _getPreferences();

    final reminderTime = prefs.getString('reminderTime') ?? '1 hour before';

    switch (reminderTime) {
      case '30 minutes before':
        return const Duration(minutes: 30);

      case '1 hour before':
        return const Duration(hours: 1);

      case '2 hours before':
        return const Duration(hours: 2);

      case '1 day before':
        return const Duration(days: 1);

      default:
        return const Duration(hours: 1);
    }
  }

  // ============================================================
  // MEDICINE NOTIFICATION ID
  // ============================================================

  int medicineNotificationId({
    required String medicineId,
    required DateTime date,
    required int timeIndex,
  }) {
    return '${medicineId}_${date.year}_${date.month}_${date.day}_$timeIndex'
            .hashCode &
        0x7fffffff;
  }

  // ============================================================
  // POSTPONED NOTIFICATION ID
  // ============================================================
  //
  // IMPORTANT:
  // Postponed notifications use their own deterministic ID.
  //
  // This allows us to cancel an existing postponed notification
  // before creating another one.
  //

  int postponedMedicineNotificationId({
    required String medicineId,
    required DateTime originalDate,
    required String originalTime,
  }) {
    return 'postponed_${medicineId}_${originalDate.year}_'
                '${originalDate.month}_${originalDate.day}_$originalTime'
            .hashCode &
        0x7fffffff;
  }

  // ============================================================
  // SCHEDULE MEDICINE NOTIFICATION
  // ============================================================

  Future<void> scheduleMedicineNotification({
    required int id,
    required String medicineName,
    required DateTime scheduledTime,
  }) async {
    await initialize();

    final prefs = await _getPreferences();

    final masterToggle = prefs.getBool('masterToggle') ?? true;

    final medicineReminder = prefs.getBool('medicineReminder') ?? true;

    if (!masterToggle || !medicineReminder) {
      return;
    }

    final notificationTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);

    // Never schedule something that is already in the past.
    if (!notificationTime.isAfter(now)) {
      return;
    }

    final medicineSound = prefs.getBool('medicineSound') ?? true;

    final medicineVibration = prefs.getBool('medicineVibration') ?? true;

    final androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: medicineSound,
      enableVibration: medicineVibration,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Time to take your medicine 💊',
      medicineName,
      notificationTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ============================================================
  // SCHEDULE POSTPONED MEDICINE NOTIFICATION
  // ============================================================

  Future<void> schedulePostponedMedicineNotification({
    required String medicineId,
    required String medicineName,
    required DateTime originalDate,
    required String originalTime,
    required DateTime postponedUntil,
  }) async {
    await initialize();

    final prefs = await _getPreferences();

    final masterToggle = prefs.getBool('masterToggle') ?? true;

    final medicineReminder = prefs.getBool('medicineReminder') ?? true;

    if (!masterToggle || !medicineReminder) {
      return;
    }

    final notificationTime = tz.TZDateTime.from(
      postponedUntil,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);

    if (!notificationTime.isAfter(now)) {
      return;
    }

    final notificationId = postponedMedicineNotificationId(
      medicineId: medicineId,
      originalDate: originalDate,
      originalTime: originalTime,
    );

    // Cancel any previous postponed notification
    // for this exact dose first.
    await _notifications.cancel(notificationId);

    final medicineSound = prefs.getBool('medicineSound') ?? true;

    final medicineVibration = prefs.getBool('medicineVibration') ?? true;

    final androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: medicineSound,
      enableVibration: medicineVibration,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Time to take your medicine 💊',
      medicineName,
      notificationTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ============================================================
  // CANCEL ORIGINAL MEDICINE DOSE
  // ============================================================

  Future<void> cancelMedicineDoseNotification({
    required String medicineId,
    required DateTime date,
    required int timeIndex,
  }) async {
    await initialize();

    final id = medicineNotificationId(
      medicineId: medicineId,
      date: date,
      timeIndex: timeIndex,
    );

    await _notifications.cancel(id);
  }

  // ============================================================
  // CANCEL POSTPONED MEDICINE NOTIFICATION
  // ============================================================

  Future<void> cancelPostponedMedicineNotification({
    required String medicineId,
    required DateTime originalDate,
    required String originalTime,
  }) async {
    await initialize();

    final id = postponedMedicineNotificationId(
      medicineId: medicineId,
      originalDate: originalDate,
      originalTime: originalTime,
    );

    await _notifications.cancel(id);
  }

  // ============================================================
  // CANCEL ALL NOTIFICATIONS FOR ONE MEDICINE
  // ============================================================

  Future<void> cancelMedicineNotifications({
    required String medicineId,
    required DateTime startDate,
    required List<String> times,
    required int? durationDays,
  }) async {
    await initialize();

    if (times.isEmpty) {
      return;
    }

    final daysToCancel = durationDays ?? 30;

    final baseDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    for (int day = 0; day < daysToCancel; day++) {
      final date = baseDate.add(
        Duration(days: day),
      );

      for (int timeIndex = 0; timeIndex < times.length; timeIndex++) {
        final notificationId = medicineNotificationId(
          medicineId: medicineId,
          date: date,
          timeIndex: timeIndex,
        );

        await _notifications.cancel(
          notificationId,
        );
      }
    }
  }

  // ============================================================
  // SCHEDULE APPOINTMENT NOTIFICATION
  // ============================================================

  Future<void> scheduleAppointmentNotification({
    required int id,
    required String appointmentType,
    required DateTime appointmentTime,
    required Duration reminderBefore,
  }) async {
    await initialize();

    final prefs = await _getPreferences();

    final masterToggle = prefs.getBool('masterToggle') ?? true;

    final appointmentReminder = prefs.getBool('appointmentReminder') ?? true;

    if (!masterToggle || !appointmentReminder) {
      return;
    }

    final notificationTime = tz.TZDateTime.from(
      appointmentTime.subtract(reminderBefore),
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);

    if (!notificationTime.isAfter(now)) {
      return;
    }

    final soundEnabled = prefs.getBool('medicineSound') ?? true;

    final vibrationEnabled = prefs.getBool('medicineVibration') ?? true;

    final androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for appointments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Upcoming appointment 🏥',
      appointmentType,
      notificationTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ============================================================
  // CANCEL ONE NOTIFICATION
  // ============================================================

  Future<void> cancel(int id) async {
    await initialize();

    await _notifications.cancel(id);
  }

  // ============================================================
  // CANCEL APPOINTMENT NOTIFICATION
  // ============================================================

  Future<void> cancelAppointmentNotification({
    required String appointmentId,
  }) async {
    await initialize();

    final notificationId = appointmentId.hashCode.abs();

    await _notifications.cancel(
      notificationId,
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  Future<void> cancelAll() async {
    await initialize();

    await _notifications.cancelAll();
  }
}
