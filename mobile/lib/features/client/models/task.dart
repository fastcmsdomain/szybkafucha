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
    return Task(
      id: json['id'] as String,
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.paczki,
      ),
      description: json['description'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      budget: json['budget'] as int,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      isImmediate: json['is_immediate'] as bool? ?? true,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.posted,
      ),
      clientId: json['client_id'] as String,
      contractorId: json['contractor_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
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
