import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/theme.dart';

/// Base class for map markers
abstract class SFMarker {
  final LatLng position;
  final double width;
  final double height;

  const SFMarker({
    required this.position,
    this.width = 50,
    this.height = 50,
  });

  Widget build(BuildContext context);
}

/// Task/Job location marker (primary color pin)
class TaskMarker extends SFMarker {
  final String? label;

  const TaskMarker({
    required super.position,
    this.label,
  }) : super(width: 80, height: 80);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingXS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.radiusSM,
              boxShadow: AppShadows.sm,
            ),
            child: Text(
              label!,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ),
        if (label != null) SizedBox(height: 2),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
              ...AppShadows.md,
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: AppColors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}

/// Contractor marker (success color with person icon)
class ContractorMarker extends SFMarker {
  final String? name;
  final bool isOnline;

  const ContractorMarker({
    required super.position,
    this.name,
    this.isOnline = true,
  }) : super(width: 80, height: 70);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingXS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.radiusSM,
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name!.split(' ').first,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.gray400,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        if (name != null) SizedBox(height: 2),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
              ...AppShadows.md,
            ],
          ),
          child: const Icon(
            Icons.directions_walk,
            color: AppColors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

/// Client/User marker (blue with home icon)
class ClientMarker extends SFMarker {
  final String? label;

  const ClientMarker({
    required super.position,
    this.label,
  }) : super(width: 80, height: 70);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingXS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.radiusSM,
              boxShadow: AppShadows.sm,
            ),
            child: Text(
              label!,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ),
        if (label != null) SizedBox(height: 2),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.info.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
              ...AppShadows.md,
            ],
          ),
          child: const Icon(
            Icons.home,
            color: AppColors.white,
            size: 22,
          ),
        ),
      ],
    );
  }
}

/// Current location marker (pulsating blue dot)
class CurrentLocationMarker extends SFMarker {
  const CurrentLocationMarker({
    required super.position,
  }) : super(width: 24, height: 24);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// Selectable pin marker (for tap-to-select on map)
class SelectableMarker extends SFMarker {
  const SelectableMarker({
    required super.position,
  }) : super(width: 50, height: 60);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: AppColors.white,
            size: 26,
          ),
        ),
        // Pin tail/shadow
        CustomPaint(
          size: const Size(12, 10),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray600.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
