import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medminder/emergency/emergency_guide_details_page.dart';
import 'package:medminder/auth/forgot_password_page.dart';

import 'services/notification_service.dart';

import 'package:medminder/reminders/manage_reminders_page.dart';
import 'package:medminder/profile/notification_settings_page.dart';
import 'package:medminder/settings/edit_password_page.dart';
import 'package:medminder/settings/edit_profile_page.dart';
import 'package:medminder/settings/help_support_page.dart';
import 'package:medminder/settings/privacy_policy_page.dart';

import 'auth/signin_page.dart';
import 'auth/signup_page.dart';
import 'home/home_page.dart';
import 'reminders/reminder_page.dart';
import 'reminders/pill_reminder_page.dart';
import 'reminders/appointment_reminder_page.dart';
import 'emergency/finder_page.dart';
import 'emergency/sos_page.dart';
import 'profile/profile_page.dart';
import 'profile/settings_page.dart';
import 'auth/success_login_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications
  await NotificationService.initialize();

  runApp(const MedMinderApp());
}

class MedMinderApp extends StatelessWidget {
  const MedMinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedMinder',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF08007C),
        ),
      ),
      home: const SignInPage(),
      routes: {
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/reminder': (context) => const ReminderPage(),
        '/pillReminder': (context) => const PillReminderPage(),
        '/appointmentReminder': (context) => const AppointmentReminderPage(),
        '/finder': (context) => const FinderPage(),
        '/sos': (context) => const SosPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/successLogin': (context) => const SuccessLoginPage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/edit_password': (context) => const EditPasswordPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
        '/help_support': (context) => const HelpSupportPage(),
        '/notification_settings': (context) => const NotificationSettingsPage(),
        '/manageReminders': (context) => const Managereminderspage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/emergencyGuide': (context) {
          final guideId = ModalRoute.of(context)!.settings.arguments as String;
          return EmergencyGuideDetailsPage(
            guideId: guideId,
          );
        },
      },
    );
  }
}
