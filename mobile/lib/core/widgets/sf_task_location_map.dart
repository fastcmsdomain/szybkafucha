import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';
import 'sf_location_marker.dart';

class SFTaskLocationMap extends ConsumerStatefulWidget {
  final LatLng taskLocation;
  final double height;

  const SFTaskLocationMap({
    super.key,
    required this.taskLocation,
    this.height = 180,
  });

  @override
  ConsumerState<SFTaskLocationMap> createState() => _SFTaskLocationMapState();
}

class _SFTaskLocationMapState extends ConsumerState<SFTaskLocationMap> {
  static const double _taskZoom = 13.0;
  static const double _myLocationZoom = 10.0;

  final MapController _mapController = MapController();
  LatLng? _currentUserLocation;
  double _currentZoom = _taskZoom;
  bool _isLocating = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.radiusMD,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.taskLocation,
                initialZoom: _taskZoom,
                minZoom: 5,
                maxZoom: 18,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && mounted) {
                    setState(() => _currentZoom = position.zoom);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'pl.szybkafucha.mobile',
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(
                    cachingProvider: const DisabledMapCachingProvider(),
                  ),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.taskLocation,
                      width: 44,
                      height: 54,
                      child: TaskMarker(position: widget.taskLocation).build(context),
                    ),
                    if (_currentUserLocation != null)
                      Marker(
                        point: _currentUserLocation!,
                        width: 24,
                        height: 24,
                        child: CurrentLocationMarker(
                          position: _currentUserLocation!,
                        ).build(context),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: AppSpacing.paddingSM,
              bottom: AppSpacing.paddingSM,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapButton(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                  ),
                  SizedBox(height: AppSpacing.gapXS),
                  _buildMapButton(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                  ),
                  SizedBox(height: AppSpacing.gapXS),
                  _buildMapButton(
                    icon: Icons.my_location,
                    onPressed: _moveToCurrentLocation,
                    isLoading: _isLocating,
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  _buildMapButton(
                    icon: Icons.center_focus_strong,
                    onPressed: _resetView,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required Future<void> Function() onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      borderRadius: AppRadius.radiusSM,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.radiusSM,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: AppColors.gray700,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _zoomIn() async {
    final newZoom = (_currentZoom + 1).clamp(5.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    if (mounted) {
      setState(() => _currentZoom = newZoom);
    }
  }

  Future<void> _zoomOut() async {
    final newZoom = (_currentZoom - 1).clamp(5.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    if (mounted) {
      setState(() => _currentZoom = newZoom);
    }
  }

  Future<void> _resetView() async {
    _mapController.move(widget.taskLocation, _taskZoom);
    if (mounted) {
      setState(() => _currentZoom = _taskZoom);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    final service = ref.read(locationServiceProvider);
    final permissionStatus = await service.checkPermission();

    if (!mounted) return;

    if (permissionStatus == LocationPermissionStatus.deniedForever) {
      setState(() => _isLocating = false);
      _showLocationMessage(
        'Dostęp do lokalizacji jest zablokowany. Włącz go w ustawieniach aplikacji.',
      );
      return;
    }

    if (permissionStatus == LocationPermissionStatus.serviceDisabled) {
      setState(() => _isLocating = false);
      _showLocationMessage('Włącz usługi lokalizacji, aby użyć tej funkcji.');
      return;
    }

    if (permissionStatus != LocationPermissionStatus.granted) {
      final newStatus = await service.requestPermission();
      if (!mounted) return;

      if (newStatus != LocationPermissionStatus.granted) {
        setState(() => _isLocating = false);
        _showLocationMessage('Udostępnij lokalizację, aby wycentrować mapę.');
        return;
      }
    }

    final latLng = await service.getCurrentLatLng();
    if (!mounted) return;

    if (latLng == null) {
      setState(() => _isLocating = false);
      _showLocationMessage('Nie udało się pobrać lokalizacji. Spróbuj ponownie.');
      return;
    }

    if (!LocationService.isInPoland(latLng)) {
      setState(() => _isLocating = false);
      _showLocationMessage('Lokalizacja jest poza obszarem działania aplikacji.');
      return;
    }

    _mapController.move(latLng, _myLocationZoom);
    setState(() {
      _currentUserLocation = latLng;
      _currentZoom = _myLocationZoom;
      _isLocating = false;
    });
  }

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
