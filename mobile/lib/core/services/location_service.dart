import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Location permission status for UI display
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

/// Location service for GPS access and geocoding
class LocationService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'SzybkaFucha/1.0';

  /// Poland geographic bounds (approximate)
  static const double _polandNorth = 54.9;
  static const double _polandSouth = 49.0;
  static const double _polandEast = 24.2;
  static const double _polandWest = 14.1;

  /// Check if coordinates are within Poland bounds
  static bool isInPoland(LatLng latLng) {
    return latLng.latitude >= _polandSouth &&
           latLng.latitude <= _polandNorth &&
           latLng.longitude >= _polandWest &&
           latLng.longitude <= _polandEast;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermissionStatus> checkPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  /// Request location permission with Polish context
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  /// Get current GPS position
  Future<Position?> getCurrentPosition() async {
    try {
      final permissionStatus = await requestPermission();

      if (permissionStatus != LocationPermissionStatus.granted) {
        debugPrint('Location permission not granted: $permissionStatus');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Get current position as LatLng
  Future<LatLng?> getCurrentLatLng() async {
    final position = await getCurrentPosition();
    if (position == null) return null;
    return LatLng(position.latitude, position.longitude);
  }

  /// Reverse geocode position to address using Nominatim
  Future<String?> getAddressFromPosition(Position position) async {
    return getAddressFromLatLng(LatLng(position.latitude, position.longitude));
  }

  /// Reverse geocode LatLng to address using Nominatim
  Future<String?> getAddressFromLatLng(LatLng latLng) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?'
        'lat=${latLng.latitude}&'
        'lon=${latLng.longitude}&'
        'format=json&'
        'addressdetails=1&'
        'accept-language=pl',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatAddress(data);
      }

      debugPrint('Reverse geocode failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Search for addresses in Poland using Nominatim
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.trim().length < 3) return [];

    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?'
        'q=${Uri.encodeComponent(query)}&'
        'countrycodes=pl&'
        'format=json&'
        'addressdetails=1&'
        'limit=5&'
        'accept-language=pl',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => AddressSuggestion.fromNominatim(item))
            .toList();
      }

      debugPrint('Address search failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error searching addresses: $e');
      return [];
    }
  }

  /// Format address from Nominatim response
  String? _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return data['display_name'] as String?;

    final parts = <String>[];

    // Street with number
    final road = address['road'] as String?;
    final houseNumber = address['house_number'] as String?;
    if (road != null) {
      if (houseNumber != null) {
        parts.add('$road $houseNumber');
      } else {
        parts.add(road);
      }
    }

    // City or town
    final city = address['city'] ??
                 address['town'] ??
                 address['village'] ??
                 address['municipality'];
    if (city != null) {
      parts.add(city as String);
    }

    // Postal code
    final postcode = address['postcode'] as String?;
    if (postcode != null && parts.isNotEmpty) {
      parts.insert(parts.length - 1, postcode);
    }

    return parts.isEmpty ? data['display_name'] as String? : parts.join(', ');
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for denied forever permissions)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Address suggestion from Nominatim search
class AddressSuggestion {
  final String displayName;
  final String shortName;
  final LatLng latLng;
  final String? street;
  final String? city;
  final String? postcode;

  AddressSuggestion({
    required this.displayName,
    required this.shortName,
    required this.latLng,
    this.street,
    this.city,
    this.postcode,
  });

  factory AddressSuggestion.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;

    // Extract components
    final street = address?['road'] as String?;
    final houseNumber = address?['house_number'] as String?;
    final city = address?['city'] ??
                 address?['town'] ??
                 address?['village'] ??
                 address?['municipality'];
    final postcode = address?['postcode'] as String?;
    final state = address?['state'] as String?;

    // Build short name for display
    final shortParts = <String>[];
    if (street != null) {
      if (houseNumber != null) {
        shortParts.add('$street $houseNumber');
      } else {
        shortParts.add(street);
      }
    }
    if (city != null) {
      shortParts.add(city as String);
    }
    if (state != null && city != state) {
      shortParts.add(state);
    }

    return AddressSuggestion(
      displayName: json['display_name'] as String? ?? '',
      shortName: shortParts.isEmpty
          ? (json['display_name'] as String? ?? '')
          : shortParts.join(', '),
      latLng: LatLng(
        double.parse(json['lat'] as String),
        double.parse(json['lon'] as String),
      ),
      street: street != null && houseNumber != null
          ? '$street $houseNumber'
          : street,
      city: city as String?,
      postcode: postcode,
    );
  }

  @override
  String toString() => shortName;
}
