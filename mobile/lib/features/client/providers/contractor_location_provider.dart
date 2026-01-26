/// Contractor Location Provider
/// Client-side tracking of contractor real-time location during active task

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/websocket_config.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/providers/websocket_provider.dart';

/// Contractor location data
class ContractorLocation {
  final String contractorId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  ContractorLocation({
    required this.contractorId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Distance to this location (simplified calculation)
  double distanceTo(double clientLat, double clientLng) {
    const earthRadiusKm = 6371;
    final dLat = _toRad(latitude - clientLat);
    final dLng = _toRad(longitude - clientLng);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRad(clientLat)) * cos(_toRad(latitude)) * sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
}

/// State for tracking contractors on a task
class TaskContractorLocationsState {
  final Map<String, ContractorLocation> locations;
  final String? activeTaskId;
  final bool isListening;

  TaskContractorLocationsState({
    this.locations = const {},
    this.activeTaskId,
    this.isListening = false,
  });

  ContractorLocation? getLocation(String contractorId) {
    return locations[contractorId];
  }

  TaskContractorLocationsState copyWith({
    Map<String, ContractorLocation>? locations,
    String? activeTaskId,
    bool? isListening,
  }) {
    return TaskContractorLocationsState(
      locations: locations ?? this.locations,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      isListening: isListening ?? this.isListening,
    );
  }

  TaskContractorLocationsState addLocation(ContractorLocation location) {
    final updated = Map<String, ContractorLocation>.from(locations);
    updated[location.contractorId] = location;
    return copyWith(locations: updated);
  }

  TaskContractorLocationsState clearLocations() {
    return copyWith(locations: {});
  }
}

/// Contractor locations notifier
class ContractorLocationsNotifier
    extends StateNotifier<TaskContractorLocationsState> {
  ContractorLocationsNotifier(this._webSocketService)
      : super(TaskContractorLocationsState()) {
    _setupLocationListeners();
  }

  final WebSocketService _webSocketService;
  StreamSubscription<LocationUpdateEvent>? _locationSubscription;

  /// Join task to receive contractor location updates
  void joinTask(String taskId) {
    state = state.copyWith(activeTaskId: taskId, isListening: true);
    _webSocketService.joinTask(taskId);
  }

  /// Leave task (stop receiving updates)
  void leaveTask(String taskId) {
    state = state.copyWith(activeTaskId: null, isListening: false);
    _webSocketService.leaveTask(taskId);
    state = state.clearLocations();
  }

  /// Setup real-time location listeners
  void _setupLocationListeners() {
    // Register listener for location updates
    _webSocketService.on(
      WebSocketConfig.locationUpdate,
      (dynamic data) {
        if (data is LocationUpdateEvent) {
          final location = ContractorLocation(
            contractorId: data.userId,
            latitude: data.latitude,
            longitude: data.longitude,
            timestamp: data.timestamp,
          );
          state = state.addLocation(location);
        }
      },
    );
  }

  /// Update client position (for distance calculation)
  /// Not persisted, used for local calculations only
  double? getContractorDistance(
    String contractorId,
    double clientLatitude,
    double clientLongitude,
  ) {
    final location = state.getLocation(contractorId);
    if (location != null) {
      return location.distanceTo(clientLatitude, clientLongitude);
    }
    return null;
  }

  /// Estimate ETA to client location (simplified)
  /// Assumes average speed of 30 km/h in urban area
  Duration? getEstimatedETA(
    String contractorId,
    double clientLatitude,
    double clientLongitude,
  ) {
    final distanceKm = getContractorDistance(
      contractorId,
      clientLatitude,
      clientLongitude,
    );

    if (distanceKm == null) {
      return null;
    }

    const averageSpeedKmh = 30;
    final hoursToArrival = distanceKm / averageSpeedKmh;
    return Duration(minutes: (hoursToArrival * 60).toInt());
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

/// Contractor locations provider
final contractorLocationsProvider = StateNotifierProvider<
    ContractorLocationsNotifier,
    TaskContractorLocationsState>(
  (ref) {
    final webSocketService = ref.watch(webSocketServiceProvider);
    return ContractorLocationsNotifier(webSocketService);
  },
);

/// Get location of specific contractor
final contractorLocationProvider = Provider.family<ContractorLocation?, String>(
  (ref, contractorId) {
    final state = ref.watch(contractorLocationsProvider);
    return state.getLocation(contractorId);
  },
);

/// Calculate distance to contractor
final contractorDistanceProvider =
    Provider.family<double?, (String contractorId, double lat, double lng)>(
  (ref, params) {
    final notifier = ref.read(contractorLocationsProvider.notifier);
    return notifier.getContractorDistance(
      params.$1,
      params.$2,
      params.$3,
    );
  },
);

/// Estimate ETA for contractor
final contractorETAProvider =
    Provider.family<Duration?, (String contractorId, double lat, double lng)>(
  (ref, params) {
    final notifier = ref.read(contractorLocationsProvider.notifier);
    return notifier.getEstimatedETA(
      params.$1,
      params.$2,
      params.$3,
    );
  },
);
