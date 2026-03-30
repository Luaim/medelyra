import 'package:flutter/material.dart';
import 'package:medminder/edit_profile_page.dart';
import 'signin_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'reminder_page.dart';
import 'pill_reminder_page.dart';
import 'appointment_reminder_page.dart';
import 'finder_page.dart';
import 'sos_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'success_login_page.dart';

void main() {
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
      },
    );
  }
}
