import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(
          create: (context) => SosProvider(contacts: context.read<ContactsProvider>()),
        ),
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
      child: _AuthBinder(
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
      ),
    );
  }
}

/// Keeps the per-user-scoped providers (contacts, settings, sentinel,
/// listen, SOS history) bound to whichever Firestore user is currently
/// signed in, and unbound (back to defaults, no Firestore listeners) when
/// signed out. Lives above the [Navigator] so it applies regardless of
/// which screen is showing.
class _AuthBinder extends StatefulWidget {
  const _AuthBinder({required this.child});

  final Widget child;

  @override
  State<_AuthBinder> createState() => _AuthBinderState();
}

class _AuthBinderState extends State<_AuthBinder> {
  String? _boundUid;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == _boundUid) return;
    _boundUid = uid;

    final contacts = context.read<ContactsProvider>();
    final settings = context.read<SettingsProvider>();
    final sentinel = context.read<SentinelProvider>();
    final listen = context.read<ListenProvider>();
    final sos = context.read<SosProvider>();

    if (uid != null) {
      contacts.bindUser(uid);
      settings.bindUser(uid);
      sentinel.bindUser(uid);
      listen.bindUser(uid);
      sos.bindUser(uid);
    } else {
      contacts.unbind();
      settings.unbind();
      sentinel.unbindUser();
      listen.unbindUser();
      sos.unbind();
    }
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
