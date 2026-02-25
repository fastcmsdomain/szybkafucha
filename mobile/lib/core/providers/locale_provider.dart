import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

const _preferredLocaleStorageKey = 'preferred_locale';
const _supportedLanguageCodes = <String>{'pl', 'uk'};

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final notifier = LocaleNotifier(ref);

  ref.listen<AuthState>(authProvider, (previous, next) {
    final previousLang = previous?.user?.preferredLanguage;
    final nextLang = next.user?.preferredLanguage;
    if (nextLang != null && nextLang != previousLang) {
      notifier.syncFromUser(nextLang);
    }
  });

  return notifier;
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref) : super(_systemLocaleFallback()) {
    _initialize();
  }

  final Ref _ref;
  SharedPreferences? _prefs;

  static Locale _systemLocaleFallback() {
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    final normalized = _normalizeLanguageCode(system.languageCode);
    return Locale(normalized ?? 'pl');
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final storedCode = _prefs?.getString(_preferredLocaleStorageKey);
    final userCode = _ref.read(authProvider).user?.preferredLanguage;

    final resolvedCode =
        _normalizeLanguageCode(userCode) ??
        _normalizeLanguageCode(storedCode) ??
        _systemLocaleFallback().languageCode;

    await _applyLocale(Locale(resolvedCode), syncBackend: false);
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = _normalizeLanguageCode(locale.languageCode) ?? 'pl';
    await _applyLocale(Locale(normalized), syncBackend: true);
  }

  Future<void> syncFromUser(String languageCode) async {
    final normalized = _normalizeLanguageCode(languageCode);
    if (normalized == null) return;
    if (state.languageCode == normalized) return;
    await _applyLocale(Locale(normalized), syncBackend: false);
  }

  Future<void> _applyLocale(Locale locale, {required bool syncBackend}) async {
    state = locale;
    LocationService.setPreferredLanguage(locale.languageCode);
    await _prefs?.setString(_preferredLocaleStorageKey, locale.languageCode);

    if (!syncBackend) return;

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    try {
      final api = _ref.read(apiClientProvider);
      await api.put<void>(
        '/users/me',
        data: {'preferredLanguage': locale.languageCode},
      );
      await _ref
          .read(authProvider.notifier)
          .setPreferredLanguageLocal(locale.languageCode);
    } catch (error) {
      debugPrint('Failed to sync preferred language: $error');
    }
  }

  static String? _normalizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code.toLowerCase();
    if (_supportedLanguageCodes.contains(normalized)) {
      return normalized;
    }
    return null;
  }
}
