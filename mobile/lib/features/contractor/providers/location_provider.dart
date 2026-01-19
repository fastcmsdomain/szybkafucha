/// Location Provider
/// Contractor location tracking and broadcasting via WebSocket

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/providers/websocket_provider.dart';

/// Location tracking state
class LocationTrackingState {
  final bool isTracking;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastUpdateTime;
  final String? error;

  LocationTrackingState({
    this.isTracking = false,
    this.currentLatitude,
    this.currentLongitude,
    this.lastUpdateTime,
    this.error,
  });

  LocationTrackingState copyWith({
    bool? isTracking,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastUpdateTime,
    String? error,
  }) {
    return LocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      error: error ?? this.error,
    );
  }
}

/// Location tracking notifier
class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  LocationTrackingNotifier(this._webSocketService)
      : super(LocationTrackingState()) {
    // Mock location simulation for dev mode
    _initializeMockTracking();
  }

  final WebSocketService _webSocketService;
  Timer? _locationUpdateTimer;
  Timer? _mockLocationTimer;

  /// Start tracking contractor location
  void startTracking({
    required double initialLatitude,
    required double initialLongitude,
    Duration updateInterval = const Duration(seconds: 15),
  }) {
    state = state.copyWith(
      isTracking: true,
      currentLatitude: initialLatitude,
      currentLongitude: initialLongitude,
      lastUpdateTime: DateTime.now(),
      error: null,
    );

    // Send initial location
    _sendLocationUpdate(initialLatitude, initialLongitude);

    // Set up periodic location broadcasting
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(updateInterval, (_) {
      // In production, get actual GPS location here
      // For now, simulate slight movements
      _simulateLocationUpdate();
    });
  }

  /// Stop tracking location
  void stopTracking() {
    _locationUpdateTimer?.cancel();
    _mockLocationTimer?.cancel();
    state = state.copyWith(isTracking: false);
  }

  /// Send location update to backend via WebSocket
  void _sendLocationUpdate(double latitude, double longitude) {
    try {
      _webSocketService.emitLocationUpdate(
        latitude: latitude,
        longitude: longitude,
      );

      state = state.copyWith(
        currentLatitude: latitude,
        currentLongitude: longitude,
        lastUpdateTime: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to send location: $e');
    }
  }

  /// Simulate location updates (dev mode)
  void _simulateLocationUpdate() {
    if (state.currentLatitude == null || state.currentLongitude == null) {
      return;
    }

    // Simulate small movements (within ~100 meters)
    final random = DateTime.now().millisecond % 100 / 100;
    final deltaLat = (random - 0.5) * 0.001; // ~100m variation
    final deltaLng = (random - 0.5) * 0.001;

    final newLat = state.currentLatitude! + deltaLat;
    final newLng = state.currentLongitude! + deltaLng;

    _sendLocationUpdate(newLat, newLng);
  }

  /// Initialize mock tracking (for testing without real GPS)
  void _initializeMockTracking() {
    // Starts with mock data when startTracking is called
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mockLocationTimer?.cancel();
    super.dispose();
  }
}

/// Location tracking provider
final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>(
  (ref) {
    final webSocketService = ref.watch(webSocketServiceProvider);
    return LocationTrackingNotifier(webSocketService);
  },
);

/// Current contractor location provider
final currentLocationProvider = Provider<({double lat, double lng})?>(
  (ref) {
    final tracking = ref.watch(locationTrackingProvider);
    if (tracking.currentLatitude != null && tracking.currentLongitude != null) {
      return (
        lat: tracking.currentLatitude!,
        lng: tracking.currentLongitude!,
      );
    }
    return null;
  },
);

/// Location tracking status provider
final isLocationTrackingProvider = Provider<bool>(
  (ref) => ref.watch(locationTrackingProvider).isTracking,
);
