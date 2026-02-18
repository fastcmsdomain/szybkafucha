/// Task Application model
/// Represents a contractor's application/bid for a task

import '../../../core/api/api_config.dart';

/// Application status enum matching backend
enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
}

/// Extension for application status display
extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Oczekuje';
      case ApplicationStatus.accepted:
        return 'Zaakceptowane';
      case ApplicationStatus.rejected:
        return 'Odrzucone';
      case ApplicationStatus.withdrawn:
        return 'Wycofane';
    }
  }

  bool get isPending => this == ApplicationStatus.pending;
}

/// Task Application data model
class TaskApplication {
  final String id;
  final String taskId;
  final String contractorId;
  final String contractorName;
  final String? contractorAvatarUrl;
  final double contractorRating;
  final int contractorReviewCount;
  final int contractorCompletedTasks;
  final String? contractorBio;
  final double? distanceKm;
  final double proposedPrice;
  final String? message;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const TaskApplication({
    required this.id,
    required this.taskId,
    required this.contractorId,
    required this.contractorName,
    this.contractorAvatarUrl,
    this.contractorRating = 0.0,
    this.contractorReviewCount = 0,
    this.contractorCompletedTasks = 0,
    this.contractorBio,
    this.distanceKm,
    required this.proposedPrice,
    this.message,
    this.status = ApplicationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory TaskApplication.fromJson(Map<String, dynamic> json) {
    final rawAvatarUrl = json['contractorAvatarUrl'] as String?;

    return TaskApplication(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      contractorId: json['contractorId'] as String,
      contractorName: json['contractorName'] as String? ?? 'Wykonawca',
      contractorAvatarUrl: ApiConfig.getFullMediaUrl(rawAvatarUrl),
      contractorRating: _parseDouble(json['contractorRating']) ?? 0.0,
      contractorReviewCount: _parseInt(json['contractorReviewCount']) ?? 0,
      contractorCompletedTasks:
          _parseInt(json['contractorCompletedTasks']) ?? 0,
      contractorBio: json['contractorBio'] as String?,
      distanceKm: _parseDouble(json['distanceKm']),
      proposedPrice: _parseDouble(json['proposedPrice']) ?? 0.0,
      message: json['message'] as String?,
      status: _mapStatus(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  static ApplicationStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.pending;
    }
  }

  /// Parse dynamic value to double (handles both String and num)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse dynamic value to int (handles both String and num)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt();
    return null;
  }

  /// Get formatted rating with one decimal
  String get formattedRating => contractorRating.toStringAsFixed(1);

  /// Get formatted distance
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Get formatted price
  String get formattedPrice => '${proposedPrice.toStringAsFixed(0)} zł';
}

/// Contractor's own application view (from GET /tasks/contractor/applications)
class MyApplication {
  final String id;
  final String taskId;
  final String taskTitle;
  final String taskCategory;
  final String taskAddress;
  final double taskBudgetAmount;
  final double proposedPrice;
  final String? message;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const MyApplication({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.taskCategory,
    required this.taskAddress,
    required this.taskBudgetAmount,
    required this.proposedPrice,
    this.message,
    this.status = ApplicationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory MyApplication.fromJson(Map<String, dynamic> json) {
    return MyApplication(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String? ?? '',
      taskCategory: json['taskCategory'] as String? ?? '',
      taskAddress: json['taskAddress'] as String? ?? '',
      taskBudgetAmount:
          TaskApplication._parseDouble(json['taskBudgetAmount']) ?? 0,
      proposedPrice: TaskApplication._parseDouble(json['proposedPrice']) ?? 0,
      message: json['message'] as String?,
      status: TaskApplication._mapStatus(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }
}
