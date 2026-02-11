import 'task_category.dart';
import 'contractor.dart';

/// Task status enum matching backend
enum TaskStatus {
  posted,
  accepted,
  confirmed, // Client confirmed the contractor
  inProgress,
  pendingComplete, // Client confirmed completion, waiting for contractor feedback
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
      case TaskStatus.confirmed:
        return 'Potwierdzone';
      case TaskStatus.inProgress:
        return 'W trakcie';
      case TaskStatus.pendingComplete:
        return 'Oczekuje';
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
      this == TaskStatus.confirmed ||
      this == TaskStatus.inProgress ||
      this == TaskStatus.pendingComplete;
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
  final double? estimatedDurationHours;
  final DateTime? scheduledAt;
  final bool isImmediate;
  final TaskStatus status;
  final String clientId;
  final String? contractorId;
  final Contractor? contractor;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final List<String>? imageUrls;

  const Task({
    required this.id,
    required this.category,
    required this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.budget,
    this.estimatedDurationHours,
    this.scheduledAt,
    this.isImmediate = true,
    this.status = TaskStatus.posted,
    required this.clientId,
    this.contractorId,
    this.contractor,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.imageUrls,
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
      // Backend may return decimal fields as Strings (e.g., "52.2297000")
      latitude: _parseDouble(json['locationLat']) ?? _parseDouble(json['latitude']),
      longitude: _parseDouble(json['locationLng']) ?? _parseDouble(json['longitude']),
      // Backend sends budgetAmount as decimal String (e.g., "50.00")
      budget: _parseInt(json['budgetAmount']) ?? _parseInt(json['budget']) ?? 0,
      // Backend sends estimatedDurationHours as decimal (e.g., 2.5)
      estimatedDurationHours: _parseDouble(json['estimatedDurationHours']),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : (json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null),
      isImmediate: json['scheduledAt'] == null && json['scheduled_at'] == null,
      status: status,
      clientId: json['clientId'] as String? ?? json['client_id'] as String? ?? '',
      contractorId: json['contractorId'] as String? ?? json['contractor_id'] as String?,
      contractor: json['contractor'] != null
          ? Contractor.fromJson(json['contractor'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : (json['accepted_at'] != null ? DateTime.parse(json['accepted_at'] as String) : null),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : (json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : (json['image_urls'] != null ? List<String>.from(json['image_urls'] as List) : null),
    );
  }

  /// Map backend status string to TaskStatus enum
  static TaskStatus _mapBackendStatus(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return TaskStatus.posted;
      case 'accepted':
        return TaskStatus.accepted;
      case 'confirmed':
        return TaskStatus.confirmed;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'pending_complete':
        return TaskStatus.pendingComplete;
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
        if (contractor != null) 'contractor': contractor!.toJson(),
        'created_at': createdAt.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        if (imageUrls != null) 'image_urls': imageUrls,
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
    Contractor? contractor,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    List<String>? imageUrls,
    bool clearContractor = false,
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
      contractorId: clearContractor ? null : (contractorId ?? this.contractorId),
      contractor: clearContractor ? null : (contractor ?? this.contractor),
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  TaskCategoryData get categoryData => TaskCategoryData.fromCategory(category);
}
