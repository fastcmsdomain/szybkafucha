import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

/// Provider for LocationService instance
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for current location permission status
final locationPermissionProvider = FutureProvider<LocationPermissionStatus>((ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.checkPermission();
});

/// Provider to request location permission
final requestLocationPermissionProvider = FutureProvider.family<LocationPermissionStatus, void>((ref, _) async {
  final service = ref.read(locationServiceProvider);
  return await service.requestPermission();
});

/// Provider for current GPS position
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.getCurrentPosition();
});

/// Provider for current GPS position as LatLng
final currentLatLngProvider = FutureProvider<LatLng?>((ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.getCurrentLatLng();
});

/// Provider for reverse geocoding a position to address
final reverseGeocodeProvider = FutureProvider.family<String?, LatLng>((ref, latLng) async {
  final service = ref.read(locationServiceProvider);
  return await service.getAddressFromLatLng(latLng);
});

/// Provider for address search suggestions
final addressSearchProvider = FutureProvider.family<List<AddressSuggestion>, String>((ref, query) async {
  final service = ref.read(locationServiceProvider);
  return await service.searchAddresses(query);
});

/// State notifier for managing location selection in forms
class LocationSelectionNotifier extends StateNotifier<LocationSelectionState> {
  final LocationService _locationService;

  LocationSelectionNotifier(this._locationService)
      : super(const LocationSelectionState());

  /// Set location from GPS
  Future<void> setFromGps() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Nie udało się pobrać lokalizacji. Sprawdź uprawnienia.',
        );
        return;
      }

      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _locationService.getAddressFromLatLng(latLng);

      state = state.copyWith(
        isLoading: false,
        latLng: latLng,
        address: address ?? 'Nieznany adres',
        isFromGps: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd: ${e.toString()}',
      );
    }
  }

  /// Set location from address selection
  void setFromAddress(AddressSuggestion suggestion) {
    state = state.copyWith(
      latLng: suggestion.latLng,
      address: suggestion.shortName,
      isFromGps: false,
      isLoading: false,
      error: null,
    );
  }

  /// Set location manually by tapping on map
  Future<void> setFromMapTap(LatLng latLng) async {
    state = state.copyWith(isLoading: true, latLng: latLng, error: null);

    try {
      final address = await _locationService.getAddressFromLatLng(latLng);
      state = state.copyWith(
        isLoading: false,
        address: address ?? 'Nieznany adres',
        isFromGps: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        address: 'Wybrana lokalizacja',
        error: null,
      );
    }
  }

  /// Clear selection
  void clear() {
    state = const LocationSelectionState();
  }
}

/// State for location selection
class LocationSelectionState {
  final LatLng? latLng;
  final String? address;
  final bool isFromGps;
  final bool isLoading;
  final String? error;

  const LocationSelectionState({
    this.latLng,
    this.address,
    this.isFromGps = false,
    this.isLoading = false,
    this.error,
  });

  bool get hasLocation => latLng != null;

  LocationSelectionState copyWith({
    LatLng? latLng,
    String? address,
    bool? isFromGps,
    bool? isLoading,
    String? error,
  }) {
    return LocationSelectionState(
      latLng: latLng ?? this.latLng,
      address: address ?? this.address,
      isFromGps: isFromGps ?? this.isFromGps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for location selection state (used in create task form)
final locationSelectionProvider =
    StateNotifierProvider<LocationSelectionNotifier, LocationSelectionState>((ref) {
  final service = ref.read(locationServiceProvider);
  return LocationSelectionNotifier(service);
});
