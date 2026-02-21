import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/theme.dart';

class NotificationsPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationsPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationsPreferencesScreen> createState() =>
      _NotificationsPreferencesScreenState();
}

class _NotificationsPreferencesScreenState
    extends ConsumerState<NotificationsPreferencesScreen> {
  static const Map<String, bool> _defaultPreferences = {
    'messages': true,
    'taskUpdates': true,
    'payments': true,
    'ratingsAndTips': true,
    'newNearbyTasks': true,
    'kycUpdates': true,
  };

  static const List<String> _contractorOnlyKeys = [
    'newNearbyTasks',
    'kycUpdates',
  ];

  Map<String, bool>? _preferences;
  Map<String, bool>? _beforeMutePreferences;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRequestingPermission = false;
  AuthorizationStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadPreferences(), _loadPermissionStatus()]);
  }

  Future<void> _loadPreferences() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/users/me/notification-preferences',
      );

      if (!mounted) return;
      setState(() {
        _preferences = _normalizePreferences(response);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preferences = _normalizePreferences(null);
        _isLoading = false;
      });
      _showSnackBar(
        'Nie udało się pobrać ustawień powiadomień.',
        AppColors.error,
      );
    }
  }

  Future<void> _loadPermissionStatus() async {
    try {
      final service = ref.read(notificationServiceProvider);
      final settings = await service.getPermissionSettings();
      if (!mounted) return;
      setState(() {
        _permissionStatus = settings.authorizationStatus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _permissionStatus = null;
      });
    }
  }

  Future<void> _requestPermissionAgain() async {
    if (_isRequestingPermission) return;

    setState(() => _isRequestingPermission = true);
    try {
      final service = ref.read(notificationServiceProvider);
      final settings = await service.requestPermissionAgain();
      if (!mounted) return;
      setState(() => _permissionStatus = settings.authorizationStatus);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Nie udało się odczytać uprawnień systemowych.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _togglePreference(String key, bool value) async {
    if (_isSaving || _preferences == null) return;

    final previous = Map<String, bool>.from(_preferences!);
    final updated = Map<String, bool>.from(_preferences!)..[key] = value;

    setState(() => _preferences = updated);
    await _savePreferences(patch: {key: value}, previousPreferences: previous);
  }

  Future<void> _toggleMuteAll(bool isOn) async {
    if (_isSaving || _preferences == null) return;

    final visibleKeys = _visiblePreferenceKeys();
    final previous = Map<String, bool>.from(_preferences!);
    final updated = Map<String, bool>.from(_preferences!);
    Map<String, bool>? previousBeforeMute;

    if (!isOn) {
      previousBeforeMute = Map<String, bool>.from(_preferences!);
      for (final key in visibleKeys) {
        updated[key] = false;
      }
    } else {
      final restore = _beforeMutePreferences;
      if (restore != null) {
        for (final key in visibleKeys) {
          updated[key] = restore[key] ?? true;
        }
      } else {
        for (final key in visibleKeys) {
          updated[key] = true;
        }
      }
    }

    setState(() {
      _preferences = updated;
      if (!isOn) {
        _beforeMutePreferences = previousBeforeMute;
      }
    });

    await _savePreferences(
      patch: {for (final key in visibleKeys) key: updated[key] ?? false},
      previousPreferences: previous,
    );
  }

  Future<void> _savePreferences({
    required Map<String, bool> patch,
    required Map<String, bool> previousPreferences,
  }) async {
    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.put<Map<String, dynamic>>(
        '/users/me/notification-preferences',
        data: patch,
      );

      if (!mounted) return;
      setState(() {
        _preferences = _normalizePreferences(response);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preferences = previousPreferences;
      });
      _showSnackBar(_mapError(error), AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _mapError(Object error) {
    if (error is ApiException) return error.message;
    return 'Nie udało się zapisać ustawień. Spróbuj ponownie.';
  }

  Map<String, bool> _normalizePreferences(Map<String, dynamic>? raw) {
    final normalized = <String, bool>{..._defaultPreferences};
    if (raw == null) return _applyRoleVisibility(normalized);

    for (final key in _defaultPreferences.keys) {
      final value = raw[key];
      if (value is bool) {
        normalized[key] = value;
      }
    }

    return _applyRoleVisibility(normalized);
  }

  Map<String, bool> _applyRoleVisibility(Map<String, bool> source) {
    final user = ref.read(authProvider).user;
    final hasContractorRole = user?.isContractor ?? false;
    if (hasContractorRole) return source;

    final normalized = <String, bool>{...source};
    for (final key in _contractorOnlyKeys) {
      normalized[key] = false;
    }
    return normalized;
  }

  List<String> _visiblePreferenceKeys() {
    final user = ref.read(authProvider).user;
    final hasContractorRole = user?.isContractor ?? false;
    if (hasContractorRole) {
      return _defaultPreferences.keys.toList();
    }
    return _defaultPreferences.keys
        .where((key) => !_contractorOnlyKeys.contains(key))
        .toList();
  }

  bool _isMuted(Map<String, bool> preferences) {
    final visibleKeys = _visiblePreferenceKeys();
    return visibleKeys.every((key) => (preferences[key] ?? false) == false);
  }

  String _labelForKey(String key) {
    switch (key) {
      case 'messages':
        return 'Nowe wiadomości';
      case 'taskUpdates':
        return 'Statusy zleceń';
      case 'payments':
        return 'Płatności i wypłaty';
      case 'ratingsAndTips':
        return 'Oceny i napiwki';
      case 'newNearbyTasks':
        return 'Nowe zlecenia w pobliżu';
      case 'kycUpdates':
        return 'Weryfikacja konta (KYC)';
      default:
        return key;
    }
  }

  String _descriptionForKey(String key) {
    switch (key) {
      case 'messages':
        return 'Powiadomienia o nowych wiadomościach na czacie.';
      case 'taskUpdates':
        return 'Zmiany statusu aktywnych zleceń.';
      case 'payments':
        return 'Informacje o płatnościach, zwrotach i wypłatach.';
      case 'ratingsAndTips':
        return 'Nowe oceny i napiwki po wykonanej pracy.';
      case 'newNearbyTasks':
        return 'Nowe oferty zadań w Twojej okolicy.';
      case 'kycUpdates':
        return 'Status weryfikacji dokumentów i konta.';
      default:
        return '';
    }
  }

  String _permissionStatusLabel(AuthorizationStatus? status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Zgoda systemowa: Włączone';
      case AuthorizationStatus.provisional:
        return 'Zgoda systemowa: Tymczasowa';
      case AuthorizationStatus.denied:
        return 'Zgoda systemowa: Wyłączone';
      case AuthorizationStatus.notDetermined:
        return 'Zgoda systemowa: Nieustawione';
      case null:
        return 'Zgoda systemowa: Nieznana';
    }
  }

  Color _permissionColor(AuthorizationStatus? status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return AppColors.success;
      case AuthorizationStatus.denied:
        return AppColors.warning;
      case AuthorizationStatus.notDetermined:
      case null:
        return AppColors.gray600;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _preferences == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final preferences = _preferences!;
    final muted = _isMuted(preferences);
    final visibleKeys = _visiblePreferenceKeys();

    return Scaffold(
      appBar: AppBar(title: const Text('Powiadomienia')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.paddingMD),
                decoration: BoxDecoration(
                  color: _permissionColor(
                    _permissionStatus,
                  ).withValues(alpha: 0.08),
                  borderRadius: AppRadius.radiusMD,
                  border: Border.all(
                    color: _permissionColor(
                      _permissionStatus,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permissionStatusLabel(_permissionStatus),
                      style: AppTypography.bodyMedium.copyWith(
                        color: _permissionColor(_permissionStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.gapXS),
                    Text(
                      'Jeśli zgoda systemowa jest wyłączona, push może nie dochodzić mimo włączonych checkboxów.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.gapSM),
                    OutlinedButton(
                      onPressed: _isRequestingPermission
                          ? null
                          : _requestPermissionAgain,
                      child: Text(
                        _isRequestingPermission
                            ? 'Sprawdzanie...'
                            : 'Poproś ponownie o zgodę',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.paddingLG),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.radiusMD,
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: !muted,
                      onChanged: _isSaving ? null : _toggleMuteAll,
                      title: const Text('Wycisz wszystkie'),
                      subtitle: Text(
                        muted
                            ? 'Wszystkie kategorie są wyłączone.'
                            : 'Wszystkie kategorie są aktywne lub częściowo aktywne.',
                      ),
                    ),
                    const Divider(height: 1),
                    ...visibleKeys.map((key) {
                      return Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: preferences[key] ?? false,
                            onChanged: _isSaving
                                ? null
                                : (value) => _togglePreference(key, value),
                            title: Text(_labelForKey(key)),
                            subtitle: Text(_descriptionForKey(key)),
                          ),
                          if (key != visibleKeys.last) const Divider(height: 1),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              if (_isSaving) ...[
                SizedBox(height: AppSpacing.paddingMD),
                Text(
                  'Zapisywanie zmian...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
