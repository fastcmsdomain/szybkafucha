import 'dart:async';
import 'dart:io';

import '../config/test_config.dart';

/// Synchronization utility for multi-device tests
/// Uses file-based markers to coordinate actions between simulators
class TestSync {
  static final Directory _syncDir = Directory(TestConfig.syncDir);

  /// Initialize sync directory (call at test start)
  static Future<void> initialize() async {
    if (!await _syncDir.exists()) {
      await _syncDir.create(recursive: true);
    }
  }

  /// Set a sync marker (signal to the other device)
  static Future<void> setMarker(String key, String value) async {
    final file = File('${TestConfig.syncDir}/$key');
    await file.writeAsString(value);
    print('[SYNC] Set marker: $key = $value');
  }

  /// Read a sync marker
  static Future<String?> getMarker(String key) async {
    final file = File('${TestConfig.syncDir}/$key');
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  /// Check if marker exists
  static Future<bool> hasMarker(String key) async {
    final file = File('${TestConfig.syncDir}/$key');
    return file.exists();
  }

  /// Wait for a marker from the other device
  static Future<String> waitForMarker(
    String key, {
    Duration? timeout,
    Duration? pollInterval,
  }) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final effectivePollInterval = pollInterval ?? TestConfig.pollInterval;
    final stopwatch = Stopwatch()..start();

    print('[SYNC] Waiting for marker: $key (timeout: ${effectiveTimeout.inSeconds}s)');

    while (stopwatch.elapsed < effectiveTimeout) {
      final value = await getMarker(key);
      if (value != null) {
        print('[SYNC] Received marker: $key = $value');
        return value;
      }
      await Future.delayed(effectivePollInterval);
    }

    throw TimeoutException(
      'Timeout waiting for marker: $key after ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Wait for marker to have specific value
  static Future<void> waitForMarkerValue(
    String key,
    String expectedValue, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    print('[SYNC] Waiting for marker: $key = $expectedValue');

    while (stopwatch.elapsed < effectiveTimeout) {
      final value = await getMarker(key);
      if (value == expectedValue) {
        print('[SYNC] Marker matched: $key = $expectedValue');
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
    }

    throw TimeoutException(
      'Timeout waiting for marker $key to equal $expectedValue',
    );
  }

  /// Clear a specific marker
  static Future<void> clearMarker(String key) async {
    final file = File('${TestConfig.syncDir}/$key');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clear all markers (call at test end or between scenarios)
  static Future<void> clearAllMarkers() async {
    if (await _syncDir.exists()) {
      await for (final entity in _syncDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
    print('[SYNC] Cleared all markers');
  }

  /// Log message with device role prefix
  static void log(DeviceRole role, String message) {
    final prefix = role == DeviceRole.client ? '[CLIENT]' : '[CONTRACTOR]';
    print('$prefix $message');
  }
}

/// Predefined sync marker keys for task lifecycle
class SyncMarkers {
  // Task creation phase
  static const String taskCreated = 'task_created';
  static const String taskId = 'task_id';
  static const String taskVisible = 'task_visible';

  // Acceptance phase
  static const String contractorAccepted = 'contractor_accepted';
  static const String clientConfirmed = 'client_confirmed';

  // Execution phase
  static const String taskInProgress = 'task_in_progress';
  static const String taskCompleted = 'task_completed';

  // Review phase
  static const String clientReviewed = 'client_reviewed';
  static const String contractorReviewed = 'contractor_reviewed';

  // Cancellation phase
  static const String taskCancelled = 'task_cancelled';
  static const String contractorCancelled = 'contractor_cancelled';
  static const String contractorRejected = 'contractor_rejected';

  // Test completion
  static const String testComplete = 'test_complete';
}
