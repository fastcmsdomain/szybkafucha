import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/theme.dart';
import 'sf_location_marker.dart';

/// Reusable map widget for Szybka Fucha app
///
/// Features:
/// - OpenStreetMap tiles via flutter_map
/// - Custom markers for task location, contractor, client
/// - Zoom controls with AppColors styling
/// - Optional interactive mode (tap to select location)
class SFMapView extends StatefulWidget {
  /// Center point of the map
  final LatLng center;

  /// Initial zoom level (default 14)
  final double zoom;

  /// List of markers to display
  final List<SFMarker> markers;

  /// Whether the map is interactive (can pan/zoom)
  final bool interactive;

  /// Whether to show zoom controls
  final bool showZoomControls;

  /// Callback when map is tapped (only if interactive)
  final void Function(LatLng)? onTap;

  /// Map height (null for unbounded)
  final double? height;

  /// Border radius for the map container
  final BorderRadius? borderRadius;
  /// Padding to keep markers visible when overlays (e.g., bottom sheets) cover part of the map
  final EdgeInsets? cameraFitPadding;

  const SFMapView({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.interactive = true,
    this.showZoomControls = true,
    this.onTap,
    this.height,
    this.borderRadius,
    this.cameraFitPadding,
  });

  @override
  State<SFMapView> createState() => _SFMapViewState();
}

class _SFMapViewState extends State<SFMapView> {
  late final MapController _mapController;
  double _currentZoom = 14;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentZoom = widget.zoom;
  }

  @override
  void didUpdateWidget(SFMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Move to new center if it changed
    if (oldWidget.center != widget.center) {
      _mapController.move(widget.center, _currentZoom);
    }
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  @override
  Widget build(BuildContext context) {
    Widget map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        initialCameraFit: widget.cameraFitPadding != null && widget.markers.isNotEmpty
            ? CameraFit.coordinates(
                coordinates: widget.markers.map((m) => m.position).toList(),
                padding: widget.cameraFitPadding!,
                maxZoom: 18,
                minZoom: 3,
                forceIntegerZoomLevel: false,
              )
            : null,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
        onTap: widget.onTap != null
            ? (tapPosition, point) => widget.onTap!(point)
            : null,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && position.zoom != null) {
            setState(() => _currentZoom = position.zoom!);
          }
        },
      ),
      children: [
        // OpenStreetMap tile layer
        // Caching disabled: path_provider_foundation iOS pod is not installed.
        // To re-enable: run `cd ios && pod install` inside mobile/.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pl.szybkafucha.mobile',
          maxZoom: 19,
          tileProvider: NetworkTileProvider(
            cachingProvider: const DisabledMapCachingProvider(),
          ),
        ),
        // Markers layer
        MarkerLayer(
          markers: widget.markers
              .map((m) => Marker(
                    point: m.position,
                    width: m.width,
                    height: m.height,
                    child: m.build(context),
                  ))
              .toList(),
        ),
      ],
    );

    // Wrap with container for styling
    Widget content = Stack(
      children: [
        map,
        // Zoom controls
        if (widget.showZoomControls && widget.interactive)
          Positioned(
            right: AppSpacing.paddingSM,
            bottom: AppSpacing.paddingSM,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildZoomButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),
                SizedBox(height: AppSpacing.gapXS),
                _buildZoomButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),
              ],
            ),
          ),
      ],
    );

    // Apply height and border radius
    if (widget.height != null || widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          height: widget.height,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      borderRadius: AppRadius.radiusSM,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.radiusSM,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.gray700,
          ),
        ),
      ),
    );
  }
}

/// Simple static map preview (non-interactive)
class SFMapPreview extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final double height;
  final BorderRadius? borderRadius;
  final List<SFMarker> markers;

  const SFMapPreview({
    super.key,
    required this.center,
    this.zoom = 15,
    this.height = 150,
    this.borderRadius,
    this.markers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SFMapView(
      center: center,
      zoom: zoom,
      height: height,
      borderRadius: borderRadius ?? AppRadius.radiusMD,
      markers: markers,
      interactive: false,
      showZoomControls: false,
    );
  }
}
