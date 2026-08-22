import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

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

    // Initialize timezone database
    tz.initializeTimeZones();

    // Get THIS DEVICE'S timezone
    final String timezoneInfo = await FlutterTimezone.getLocalTimezone();

    // Use the device's local timezone
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
    // Later we can use the notification payload
    // to open the correct medicine or appointment.
  }

  // ============================================================
  // ANDROID PERMISSION
  // ============================================================

  Future<bool> requestPermission() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      return false;
    }

    // Notification permission
    final notificationGranted =
        await androidImplementation.requestNotificationsPermission();

    // Exact alarm permission
    final exactAlarmGranted =
        await androidImplementation.requestExactAlarmsPermission();

    return (notificationGranted ?? false) && (exactAlarmGranted ?? false);
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

    final notificationTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Don't schedule notifications in the past
    if (notificationTime.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
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
  // SCHEDULE APPOINTMENT NOTIFICATION
  // ============================================================

  Future<void> scheduleAppointmentNotification({
    required int id,
    required String appointmentType,
    required DateTime appointmentTime,
    required Duration reminderBefore,
  }) async {
    await initialize();

    final notificationTime = tz.TZDateTime.from(
      appointmentTime.subtract(reminderBefore),
      tz.local,
    );

    // Don't schedule notifications in the past
    if (notificationTime.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for appointments',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
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
  // CANCEL ALL NOTIFICATIONS
  // ============================================================

  Future<void> cancelAll() async {
    await initialize();

    await _notifications.cancelAll();
  }
}
