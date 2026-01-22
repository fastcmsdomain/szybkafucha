import 'task_category.dart';

/// Task status enum matching backend
enum TaskStatus {
  posted,
  accepted,
  inProgress,
  completed,
  cancelled,
  disputed,
}

/// Extension for task status display
extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.posted:
        return 'Opublikowane';
      case TaskStatus.accepted:
        return 'Zaakceptowane';
      case TaskStatus.inProgress:
        return 'W trakcie';
      case TaskStatus.completed:
        return 'Zakończone';
      case TaskStatus.cancelled:
        return 'Anulowane';
      case TaskStatus.disputed:
        return 'Sporne';
    }
  }

  bool get isActive =>
      this == TaskStatus.posted ||
      this == TaskStatus.accepted ||
      this == TaskStatus.inProgress;
}

/// Task data model
class Task {
  final String id;
  final TaskCategory category;
  final String description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int budget;
  final DateTime? scheduledAt;
  final bool isImmediate;
  final TaskStatus status;
  final String clientId;
  final String? contractorId;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.category,
    required this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.budget,
    this.scheduledAt,
    this.isImmediate = true,
    this.status = TaskStatus.posted,
    required this.clientId,
    this.contractorId,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Map backend status string to TaskStatus enum
    final statusStr = json['status'] as String? ?? 'created';
    final status = _mapBackendStatus(statusStr);

    return Task(
      id: json['id'] as String,
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.paczki,
      ),
      // Backend may send title or description
      description: json['description'] as String? ?? json['title'] as String? ?? '',
      // Backend uses camelCase
      address: json['address'] as String?,
      latitude: (json['locationLat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      longitude: (json['locationLng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
      // Backend sends budgetAmount as decimal
      budget: (json['budgetAmount'] as num?)?.toInt() ?? (json['budget'] as num?)?.toInt() ?? 0,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : (json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null),
      isImmediate: json['scheduledAt'] == null && json['scheduled_at'] == null,
      status: status,
      clientId: json['clientId'] as String? ?? json['client_id'] as String? ?? '',
      contractorId: json['contractorId'] as String? ?? json['contractor_id'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : (json['accepted_at'] != null ? DateTime.parse(json['accepted_at'] as String) : null),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : (json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null),
    );
  }

  /// Map backend status string to TaskStatus enum
  static TaskStatus _mapBackendStatus(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return TaskStatus.posted;
      case 'accepted':
        return TaskStatus.accepted;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'disputed':
        return TaskStatus.disputed;
      default:
        return TaskStatus.posted;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'budget': budget,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'is_immediate': isImmediate,
        'status': status.name,
        'client_id': clientId,
        'contractor_id': contractorId,
        'created_at': createdAt.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  Task copyWith({
    String? id,
    TaskCategory? category,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    int? budget,
    DateTime? scheduledAt,
    bool? isImmediate,
    TaskStatus? status,
    String? clientId,
    String? contractorId,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      budget: budget ?? this.budget,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isImmediate: isImmediate ?? this.isImmediate,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      contractorId: contractorId ?? this.contractorId,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  TaskCategoryData get categoryData => TaskCategoryData.fromCategory(category);
}
