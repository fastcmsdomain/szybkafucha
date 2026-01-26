import '../../../features/client/models/task_category.dart';

/// Contractor profile model
class ContractorProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final List<TaskCategory> categories;
  final double serviceRadius; // in km
  final KycStatus kycStatus;
  final double rating;
  final int completedTasks;
  final int reviewCount;
  final bool isOnline;
  final bool isVerified;
  final DateTime? createdAt;

  const ContractorProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.categories = const [],
    this.serviceRadius = 5.0,
    this.kycStatus = KycStatus.notStarted,
    this.rating = 0.0,
    this.completedTasks = 0,
    this.reviewCount = 0,
    this.isOnline = false,
    this.isVerified = false,
    this.createdAt,
  });

  factory ContractorProfile.fromJson(Map<String, dynamic> json) {
    return ContractorProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => TaskCategory.values.firstWhere(
                    (c) => c.name == e,
                    orElse: () => TaskCategory.sprzatanie,
                  ))
              .toList() ??
          [],
      serviceRadius: (json['service_radius'] as num?)?.toDouble() ?? 5.0,
      kycStatus: KycStatus.values.firstWhere(
        (s) => s.name == json['kyc_status'],
        orElse: () => KycStatus.notStarted,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'bio': bio,
        'categories': categories.map((c) => c.name).toList(),
        'service_radius': serviceRadius,
        'kyc_status': kycStatus.name,
        'rating': rating,
        'completed_tasks': completedTasks,
        'review_count': reviewCount,
        'is_online': isOnline,
        'is_verified': isVerified,
        'created_at': createdAt?.toIso8601String(),
      };

  ContractorProfile copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? bio,
    List<TaskCategory>? categories,
    double? serviceRadius,
    KycStatus? kycStatus,
    double? rating,
    int? completedTasks,
    int? reviewCount,
    bool? isOnline,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return ContractorProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      categories: categories ?? this.categories,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      kycStatus: kycStatus ?? this.kycStatus,
      rating: rating ?? this.rating,
      completedTasks: completedTasks ?? this.completedTasks,
      reviewCount: reviewCount ?? this.reviewCount,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);

  bool get canAcceptTasks => kycStatus == KycStatus.approved && isVerified;
}

/// KYC verification status
enum KycStatus {
  notStarted,
  documentUploaded,
  selfieUploaded,
  bankAccountAdded,
  pending,
  approved,
  rejected,
}

extension KycStatusExtension on KycStatus {
  String get displayName {
    switch (this) {
      case KycStatus.notStarted:
        return 'Nie rozpoczęto';
      case KycStatus.documentUploaded:
        return 'Dokument przesłany';
      case KycStatus.selfieUploaded:
        return 'Selfie przesłane';
      case KycStatus.bankAccountAdded:
        return 'Konto bankowe dodane';
      case KycStatus.pending:
        return 'W trakcie weryfikacji';
      case KycStatus.approved:
        return 'Zweryfikowano';
      case KycStatus.rejected:
        return 'Odrzucono';
    }
  }

  int get stepNumber {
    switch (this) {
      case KycStatus.notStarted:
        return 0;
      case KycStatus.documentUploaded:
        return 1;
      case KycStatus.selfieUploaded:
        return 2;
      case KycStatus.bankAccountAdded:
        return 3;
      case KycStatus.pending:
        return 4;
      case KycStatus.approved:
        return 5;
      case KycStatus.rejected:
        return -1;
    }
  }
}
