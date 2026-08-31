import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/contacts_provider.dart';
import 'providers/fake_call_provider.dart';
import 'providers/listen_provider.dart';
import 'providers/recordings_provider.dart';
import 'providers/sentinel_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sos_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/home_screen.dart';
import 'screens/listen_screen.dart';
import 'screens/location_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recordings_screen.dart';
import 'screens/sentinel_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tutorial_screen.dart';
import 'theme/app_theme.dart';

/// Named route constants — screens navigate with these rather than magic
/// strings scattered through the codebase.
class Routes {
  Routes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const forgot = '/forgot';
  static const home = '/home';
  static const sos = '/sos';
  static const contacts = '/contacts';
  static const location = '/location';
  static const recordings = '/recordings';
  static const fakeCall = '/fake-call';
  static const tutorial = '/tutorial';
  static const settings = '/settings';
  static const profile = '/profile';
  static const sentinel = '/sentinel';
  static const checkin = '/checkin';
  static const listen = '/listen';
}

class SheSecureApp extends StatelessWidget {
  const SheSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FakeCallProvider()),
        ChangeNotifierProvider(create: (_) => RecordingsProvider()),
        ChangeNotifierProvider(
          create: (context) => SentinelProvider(sos: context.read<SosProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ListenProvider(sos: context.read<SosProvider>()),
        ),
      ],
      child: MaterialApp(
        title: 'She Secure',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: Routes.splash,
        routes: {
          Routes.splash: (_) => const SplashScreen(),
          Routes.onboarding: (_) => const OnboardingScreen(),
          Routes.auth: (_) => const AuthScreen(),
          Routes.forgot: (_) => const ForgotPasswordScreen(),
          Routes.home: (_) => const HomeScreen(),
          Routes.sos: (_) => const SosScreen(),
          Routes.contacts: (_) => const ContactsScreen(),
          Routes.location: (_) => const LocationScreen(),
          Routes.recordings: (_) => const RecordingsScreen(),
          Routes.fakeCall: (_) => const FakeCallScreen(),
          Routes.tutorial: (_) => const TutorialScreen(),
          Routes.settings: (_) => const SettingsScreen(),
          Routes.profile: (_) => const ProfileScreen(),
          Routes.sentinel: (_) => const SentinelScreen(),
          Routes.checkin: (_) => const CheckinScreen(),
          Routes.listen: (_) => const ListenScreen(),
        },
      ),
    );
  }
}
