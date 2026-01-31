import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:szybka_fucha/core/l10n/l10n.dart';
import 'package:szybka_fucha/core/router/router.dart';
import 'package:szybka_fucha/core/theme/theme.dart';
import 'package:szybka_fucha/core/widgets/notification_initializer.dart';
import 'package:szybka_fucha/core/widgets/websocket_initializer.dart';

/// Test app wrapper for integration tests
/// Configures the app to use real backend (not dev mode)
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _TestAppContent(),
    );
  }
}

class _TestAppContent extends ConsumerWidget {
  const _TestAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return WebSocketInitializer(
      child: NotificationInitializer(
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          // Locale settings for Polish
          locale: const Locale('pl', 'PL'),
          supportedLocales: const [
            Locale('pl', 'PL'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}

/// Simplified test app without WebSocket/Notifications for faster tests
class TestAppSimple extends StatelessWidget {
  const TestAppSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _TestAppSimpleContent(),
    );
  }
}

class _TestAppSimpleContent extends ConsumerWidget {
  const _TestAppSimpleContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('pl', 'PL'),
      supportedLocales: const [
        Locale('pl', 'PL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
