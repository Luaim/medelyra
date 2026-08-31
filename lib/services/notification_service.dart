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

    // Initialize timezone database.
    tz.initializeTimeZones();

    // Get THIS DEVICE'S timezone.
    final String timezoneInfo = await FlutterTimezone.getLocalTimezone();

    // Use the device's local timezone.
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
    // Later we can use the payload to open
    // the correct medicine or appointment.
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

    // Do not schedule if medicine notifications are disabled.
    if (!masterToggle || !medicineReminder) {
      return;
    }

    final notificationTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Do not schedule notifications in the past.
    if (notificationTime.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
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
  // CANCEL MEDICINE NOTIFICATIONS
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

    // Ongoing medicines currently schedule up to 30 days.
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

        await _notifications.cancel(notificationId);
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

    // Do not schedule if appointment notifications are disabled.
    if (!masterToggle || !appointmentReminder) {
      return;
    }

    final notificationTime = tz.TZDateTime.from(
      appointmentTime.subtract(reminderBefore),
      tz.local,
    );

    // Do not schedule notifications in the past.
    if (notificationTime.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
      return;
    }

    // Use the medicine sound/vibration settings for the
    // notification behavior until separate appointment
    // sound/vibration settings are added to the UI.
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

    await _notifications.cancel(notificationId);
  }

  // ============================================================
  // CANCEL ALL NOTIFICATIONS
  // ============================================================

  Future<void> cancelAll() async {
    await initialize();

    await _notifications.cancelAll();
  }
}
