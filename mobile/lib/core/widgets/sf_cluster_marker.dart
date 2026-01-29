import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/theme.dart';
import 'sf_location_marker.dart';

/// A cluster of tasks shown on the map when zoomed out
class TaskCluster {
  final LatLng center;
  final List<ClusterableTask> tasks;

  TaskCluster({
    required this.center,
    required this.tasks,
  });

  int get count => tasks.length;

  /// Check if this is a single task (not a cluster)
  bool get isSingleTask => tasks.length == 1;
}

/// Minimal task data needed for clustering
class ClusterableTask {
  final String id;
  final LatLng position;
  final String? category;
  final double? price;

  ClusterableTask({
    required this.id,
    required this.position,
    this.category,
    this.price,
  });
}

/// Cluster marker widget - shows count of tasks in cluster
class ClusterMarker extends SFMarker {
  final int count;
  final VoidCallback? onTap;

  ClusterMarker({
    required super.position,
    required this.count,
    this.onTap,
  }) : super(
    width: _getSize(count),
    height: _getSize(count),
  );

  static double _getSize(int count) {
    if (count < 10) return 44;
    if (count < 50) return 52;
    if (count < 100) return 60;
    return 68;
  }

  @override
  Widget build(BuildContext context) {
    final size = _getSize(count);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: count > 99 ? 12 : (count > 9 ? 14 : 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple clustering algorithm for map markers
class TaskClusterManager {
  /// Poland center coordinates
  static const LatLng polandCenter = LatLng(52.0693, 19.4803);

  /// Poland bounds (approximate)
  static const double polandNorth = 54.9;
  static const double polandSouth = 49.0;
  static const double polandEast = 24.2;
  static const double polandWest = 14.1;

  /// Create clusters from tasks based on current zoom level
  static List<TaskCluster> clusterTasks(
    List<ClusterableTask> tasks,
    double zoom,
  ) {
    if (tasks.isEmpty) return [];

    // At high zoom levels, don't cluster
    if (zoom >= 13) {
      return tasks.map((task) => TaskCluster(
        center: task.position,
        tasks: [task],
      )).toList();
    }

    // Calculate cluster radius based on zoom
    // Lower zoom = larger radius (more clustering)
    final clusterRadiusKm = _getClusterRadiusKm(zoom);

    final clusters = <TaskCluster>[];
    final processed = <int>{};

    for (var i = 0; i < tasks.length; i++) {
      if (processed.contains(i)) continue;

      final task = tasks[i];
      final nearbyTasks = <ClusterableTask>[task];
      processed.add(i);

      // Find all tasks within cluster radius
      for (var j = i + 1; j < tasks.length; j++) {
        if (processed.contains(j)) continue;

        final otherTask = tasks[j];
        final distance = _calculateDistance(task.position, otherTask.position);

        if (distance <= clusterRadiusKm) {
          nearbyTasks.add(otherTask);
          processed.add(j);
        }
      }

      // Calculate cluster center as average of all positions
      final centerLat = nearbyTasks.map((t) => t.position.latitude).reduce((a, b) => a + b) / nearbyTasks.length;
      final centerLng = nearbyTasks.map((t) => t.position.longitude).reduce((a, b) => a + b) / nearbyTasks.length;

      clusters.add(TaskCluster(
        center: LatLng(centerLat, centerLng),
        tasks: nearbyTasks,
      ));
    }

    return clusters;
  }

  /// Get cluster radius in kilometers based on zoom level
  static double _getClusterRadiusKm(double zoom) {
    // Exponential scaling: lower zoom = much larger radius
    // zoom 5: ~100km, zoom 8: ~25km, zoom 10: ~10km, zoom 12: ~3km
    return 200 / math.pow(2, zoom - 4);
  }

  /// Calculate distance between two points in kilometers using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371.0; // km

    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLng / 2) * math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}
