import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/l10n.dart';
import 'core/router/router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme.dart';
import 'core/widgets/notification_initializer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (if enabled in development)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Set up background message handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } on UnsupportedError catch (e) {
    // Firebase disabled in development mode
    print('ℹ️  Firebase is disabled for development');
    print('ℹ️  To enable: Complete Phase 1 setup in FIREBASE_SETUP_GUIDE.md');
  } catch (e) {
    // Firebase initialization error
    print('⚠️ Firebase initialization failed: $e');
    print('⚠️ App will run without push notifications');
    print('⚠️ Ensure Firebase credentials are configured in firebase_options.dart');
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SzybkaFuchaApp(),
    ),
  );
}

class SzybkaFuchaApp extends ConsumerWidget {
  const SzybkaFuchaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return NotificationInitializer(
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        // Locale settings for Polish
        locale: const Locale('pl', 'PL'),
        supportedLocales: const [
          Locale('pl', 'PL'),
          Locale('en', 'US'), // Fallback
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
