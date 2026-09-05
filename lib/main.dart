import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medelyra/health_tools/health_tools_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:medelyra/auth/forgot_password_page.dart';
import 'package:medelyra/emergency/emergency_guide_details_page.dart';
import 'package:medelyra/profile/notification_settings_page.dart';
import 'package:medelyra/reminders/manage_reminders_page.dart';
import 'package:medelyra/settings/edit_password_page.dart';
import 'package:medelyra/settings/edit_profile_page.dart';
import 'package:medelyra/settings/help_support_page.dart';
import 'package:medelyra/settings/privacy_policy_page.dart';

import 'services/notification_service.dart';

import 'auth/signin_page.dart';
import 'auth/signup_page.dart';
import 'home/home_page.dart';
import 'reminders/reminder_page.dart';
import 'reminders/pill_reminder_page.dart';
import 'reminders/appointment_reminder_page.dart';
import 'emergency/sos_page.dart';
import 'profile/profile_page.dart';
import 'profile/settings_page.dart';

import 'onboarding/onboarding_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash screen visible while
  // Firebase and app startup information are loading.
  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  );

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications.
  await NotificationService.initialize();

  // Check whether onboarding has already been completed.
  final prefs = await SharedPreferences.getInstance();

  final onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

  Widget initialPage;

  if (!onboardingCompleted) {
    // First launch → Onboarding.
    initialPage = const OnboardingPage();
  } else {
    // Onboarding completed → check Firebase login.
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Already logged in → Home.
      initialPage = const HomePage();
    } else {
      // Logged out → Sign In.
      initialPage = const SignInPage();
    }
  }

  runApp(
    MedelyraApp(
      initialPage: initialPage,
    ),
  );

  // Flutter is now ready, so remove the native splash.
  FlutterNativeSplash.remove();
}

class MedelyraApp extends StatelessWidget {
  final Widget initialPage;

  const MedelyraApp({
    super.key,
    this.initialPage = const SignInPage(),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medelyra',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF08007C),
        ),
      ),
      home: initialPage,
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/reminder': (context) => const ReminderPage(),
        '/pillReminder': (context) => const PillReminderPage(),
        '/appointmentReminder': (context) => const AppointmentReminderPage(),
        '/health-tools': (context) => const HealthToolsPage(),
        '/sos': (context) => const SosPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
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
