import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API configuration for Szybka Fucha.
///
/// On physical iOS/Android devices, [initialize] auto-discovers the dev
/// backend on the local network so you never need to pass
/// `--dart-define=DEV_SERVER_URL` manually.
abstract class ApiConfig {
  /// Enable dev mode to bypass backend and use mock data.
  static const bool devModeEnabled = true;

  /// Default backend port for development.
  static const int devPort = 3000;

  /// SharedPreferences key used to cache a previously discovered server URL.
  static const String _cachedUrlKey = '_dev_server_url';

  /// URL resolved during [initialize]. When non-null, takes precedence over
  /// the compile-time / platform defaults in [devServerUrl].
  static String? _resolvedServerUrl;

  // ---------------------------------------------------------------------------
  // Initialization (call once from main() before runApp)
  // ---------------------------------------------------------------------------

  /// Discover the correct dev server URL for the current device.
  ///
  /// **Precedence:**
  /// 1. `--dart-define=DEV_SERVER_URL=…` (compile-time override)
  /// 2. `localhost` reachability test (passes on Simulator / local backend)
  /// 3. Previously cached URL from a successful LAN discovery
  /// 4. Parallel /24 subnet scan for a host serving [devPort]
  ///
  /// In release mode or on web this is a no-op.
  static Future<void> initialize() async {
    if (kReleaseMode || kIsWeb) return;

    const defined = String.fromEnvironment('DEV_SERVER_URL', defaultValue: '');
    if (defined.isNotEmpty) {
      _resolvedServerUrl = _ensurePort(defined);
      debugPrint('🌐 API: DEV_SERVER_URL=$_resolvedServerUrl');
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) return;

    // iOS – quick localhost check (works on Simulator)
    if (await _isReachable('127.0.0.1', devPort)) {
      debugPrint('🌐 API: localhost:$devPort reachable (Simulator)');
      return;
    }

    debugPrint('🔍 API: Physical device detected – discovering backend on LAN…');

    final cached = await _tryCachedUrl();
    if (cached != null) {
      _resolvedServerUrl = cached;
      debugPrint('🌐 API: Using cached URL=$_resolvedServerUrl');
      return;
    }

    final host = await _discoverBackendOnLan();
    if (host != null) {
      _resolvedServerUrl = 'http://$host:$devPort';
      debugPrint('🌐 API: Found backend at $_resolvedServerUrl');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedUrlKey, _resolvedServerUrl!);
      } catch (_) {}
      return;
    }

    debugPrint('⚠️  API: Backend not found on local network.');
    debugPrint('    Run: cd mobile && ./scripts/run_ios.sh');
    debugPrint(
      '    Or:  flutter run --dart-define=DEV_SERVER_URL=http://<MAC_IP>:$devPort',
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static String _ensurePort(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        !uri.hasPort &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return '${uri.scheme}://${uri.host}:$devPort';
    }
    return url;
  }

  static Future<bool> _isReachable(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 800),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _tryCachedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedUrlKey);
      if (cached == null) return null;
      final uri = Uri.parse(cached);
      if (await _isReachable(uri.host, uri.port)) return cached;
    } catch (_) {}
    return null;
  }

  /// Scan the local /24 subnet for a host with [devPort] open.
  /// All 253 connection attempts run in parallel; the method returns as
  /// soon as the first host responds (typically < 500 ms on a home WiFi).
  static Future<String?> _discoverBackendOnLan() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          if (!_isPrivateIp(addr.address)) continue;

          final parts = addr.address.split('.');
          final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
          debugPrint('🔍 API: Scanning $subnet.0/24 for port $devPort …');

          final completer = Completer<String?>();
          var remaining = 0;

          for (var i = 1; i <= 254; i++) {
            final candidate = '$subnet.$i';
            if (candidate == addr.address) continue;
            remaining++;

            _isReachable(
              candidate,
              devPort,
              timeout: const Duration(milliseconds: 500),
            ).then((ok) {
              remaining--;
              if (ok && !completer.isCompleted) {
                completer.complete(candidate);
              } else if (remaining == 0 && !completer.isCompleted) {
                completer.complete(null);
              }
            });
          }

          Future.delayed(const Duration(seconds: 4), () {
            if (!completer.isCompleted) completer.complete(null);
          });

          final result = await completer.future;
          if (result != null) return result;
        }
      }
    } catch (e) {
      debugPrint('⚠️  API: LAN scan error: $e');
    }
    return null;
  }

  static bool _isPrivateIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]) ?? 0;
    final b = int.tryParse(parts[1]) ?? 0;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  // ---------------------------------------------------------------------------
  // Public getters (unchanged external API)
  // ---------------------------------------------------------------------------

  /// Server base URL for development (without `/api/v1`).
  /// Override at run time with:
  ///   `--dart-define=DEV_SERVER_URL=http://...`
  ///
  /// Defaults:
  /// - iOS Simulator: `http://localhost:3000`
  /// - Android Emulator: `http://10.0.2.2:3000` (host machine)
  ///
  /// Physical device (iOS/Android): auto-discovered via [initialize],
  /// or pass explicitly:
  ///   `--dart-define=DEV_SERVER_URL=http://192.168.1.114:3000`
  static String get devServerUrl {
    if (_resolvedServerUrl != null) return _resolvedServerUrl!;

    const defined = String.fromEnvironment('DEV_SERVER_URL', defaultValue: '');
    if (defined.isEmpty) {
      if (kIsWeb) return 'http://localhost:$devPort';
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => 'http://10.0.2.2:$devPort',
        _ => 'http://localhost:$devPort',
      };
    }
    final uri = Uri.tryParse(defined);
    if (uri != null &&
        !uri.hasPort &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return '${uri.origin}:$devPort';
    }
    return defined;
  }

  /// Server base URL for staging (without /api/v1)
  static const String stagingServerUrl = 'https://staging-api.szybkafucha.pl';

  /// Server base URL for production (without /api/v1)
  static const String prodServerUrl = 'https://api.szybkafucha.pl';

  /// Current server base URL (change based on build flavor)
  static String get serverUrl => devServerUrl;

  /// Base URL for development
  static String get devBaseUrl => '$devServerUrl/api/v1';

  /// Base URL for staging
  static String get stagingBaseUrl => '$stagingServerUrl/api/v1';

  /// Base URL for production
  static String get prodBaseUrl => '$prodServerUrl/api/v1';

  /// Current base URL (change based on build flavor)
  static String get baseUrl => devBaseUrl;

  /// Get full URL for avatar/media paths.
  /// Converts relative paths like /uploads/avatars/file.jpg to full URLs.
  static String? getFullMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      final mediaUri = Uri.tryParse(relativePath);
      final apiUri = Uri.tryParse(serverUrl);

      if (mediaUri != null &&
          apiUri != null &&
          _isLocalhost(mediaUri.host) &&
          !_isLocalhost(apiUri.host)) {
        return mediaUri
            .replace(
              scheme: apiUri.scheme,
              host: apiUri.host,
              port: apiUri.hasPort ? apiUri.port : null,
            )
            .toString();
      }
      return relativePath;
    }
    return '$serverUrl$relativePath';
  }

  static bool _isLocalhost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

  /// Connection timeout in milliseconds
  static const int connectTimeout = 30000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  /// Send timeout in milliseconds
  static const int sendTimeout = 30000;

  /// API version header
  static const String apiVersionHeader = 'X-API-Version';
  static const String apiVersion = '1.0';
}
