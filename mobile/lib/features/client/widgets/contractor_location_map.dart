/// Contractor Location Map Widget
/// Shows real-time contractor location on map with ETA and distance

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/contractor_location_provider.dart';

class ContractorLocationMap extends ConsumerStatefulWidget {
  final String taskId;
  final String contractorId;
  final double clientLatitude;
  final double clientLongitude;
  final String clientAddress;
  final String contractorName;

  const ContractorLocationMap({
    Key? key,
    required this.taskId,
    required this.contractorId,
    required this.clientLatitude,
    required this.clientLongitude,
    required this.clientAddress,
    required this.contractorName,
  }) : super(key: key);

  @override
  ConsumerState<ContractorLocationMap> createState() =>
      _ContractorLocationMapState();
}

class _ContractorLocationMapState extends ConsumerState<ContractorLocationMap> {
  @override
  void initState() {
    super.initState();
    // Join task to receive location updates
    Future.microtask(() {
      ref
          .read(contractorLocationsProvider.notifier)
          .joinTask(widget.taskId);
    });
  }

  @override
  void dispose() {
    // Leave task when done
    ref
        .read(contractorLocationsProvider.notifier)
        .leaveTask(widget.taskId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractorLocation =
        ref.watch(contractorLocationProvider(widget.contractorId));

    final distance = ref.watch(
      contractorDistanceProvider(
        (
          widget.contractorId,
          widget.clientLatitude,
          widget.clientLongitude,
        ),
      ),
    );

    final eta = ref.watch(
      contractorETAProvider(
        (
          widget.contractorId,
          widget.clientLatitude,
          widget.clientLongitude,
        ),
      ),
    );

    return Column(
      children: [
        // Map area (placeholder with grid pattern)
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: Stack(
              children: [
                // Map grid pattern (placeholder)
                _buildMapPlaceholder(),
                // Current location marker (client)
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 12,
                  top: MediaQuery.of(context).size.height / 3 - 12,
                  child: _buildClientMarker(),
                ),
                // Contractor location (if available)
                if (contractorLocation != null)
                  Positioned(
                    left: _calculateMarkerPositionX(
                      contractorLocation.longitude,
                      widget.clientLongitude,
                      context,
                    ),
                    top: _calculateMarkerPositionY(
                      contractorLocation.latitude,
                      widget.clientLatitude,
                      context,
                    ),
                    child: _buildContractorMarker(),
                  ),
              ],
            ),
          ),
        ),
        // Info panel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contractorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aktualizacja lokalizacji',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (contractorLocation != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Śledzona',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Distance and ETA
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      label: 'Dystans',
                      value: distance != null
                          ? '${distance.toStringAsFixed(1)} km'
                          : '—',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.schedule,
                      label: 'ETA',
                      value: eta != null
                          ? '${eta.inMinutes} min'
                          : '—',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Destination address
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Docelowa lokalizacja',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.clientAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(),
    );
  }

  Widget _buildClientMarker() {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.home,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Ty',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractorMarker() {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE94560),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94560).withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE94560),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Wykonawca',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMarkerPositionX(
    double contractorLng,
    double clientLng,
    BuildContext context,
  ) {
    final width = MediaQuery.of(context).size.width;
    const scale = 5000; // Pixels per degree of longitude
    final offset = (contractorLng - clientLng) * scale;
    return width / 2 - 12 + offset;
  }

  double _calculateMarkerPositionY(
    double contractorLat,
    double clientLat,
    BuildContext context,
  ) {
    final height = MediaQuery.of(context).size.height / 2;
    const scale = 5000; // Pixels per degree of latitude
    final offset = (clientLat - contractorLat) * scale;
    return height / 3 - 12 + offset;
  }
}

/// Grid painter for map background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 40.0;
    const color = Color(0xFFE0E0E0);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
