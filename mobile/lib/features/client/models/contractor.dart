import '../../../core/api/api_config.dart';

/// Contractor profile model for client-facing views
class Contractor {
  final String id;
  final String name;
  final String? avatarUrl;
  final double rating;
  final int completedTasks;
  final int reviewCount;
  final bool isVerified;
  final bool isOnline;
  final double? distanceKm;
  final int? etaMinutes;
  final int? proposedPrice;
  final List<String> categories;
  final DateTime? memberSince;
  final String? bio;

  const Contractor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.rating = 0.0,
    this.completedTasks = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.distanceKm,
    this.etaMinutes,
    this.proposedPrice,
    this.categories = const [],
    this.memberSince,
    this.bio,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    // Get raw avatar URL and convert to full URL if relative
    final rawAvatarUrl = json['avatar_url'] as String? ?? json['avatarUrl'] as String?;

    return Contractor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: ApiConfig.getFullMediaUrl(rawAvatarUrl),
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['ratingAvg'] as num?)?.toDouble() ??
          0.0,
      completedTasks: json['completed_tasks'] as int? ??
          json['completedTasksCount'] as int? ??
          0,
      reviewCount: json['review_count'] as int? ??
          json['ratingCount'] as int? ??
          0,
      isVerified: json['is_verified'] as bool? ??
          json['isVerified'] as bool? ??
          false,
      isOnline: json['is_online'] as bool? ?? json['isOnline'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      etaMinutes: json['eta_minutes'] as int?,
      proposedPrice: json['proposed_price'] as int?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : json['memberSince'] != null
              ? DateTime.parse(json['memberSince'] as String)
              : null,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'rating': rating,
        'completed_tasks': completedTasks,
        'review_count': reviewCount,
        'is_verified': isVerified,
        'is_online': isOnline,
        'distance_km': distanceKm,
        'eta_minutes': etaMinutes,
        'proposed_price': proposedPrice,
        'categories': categories,
        'member_since': memberSince?.toIso8601String(),
        'bio': bio,
      };

  /// Get formatted rating with one decimal
  String get formattedRating => rating.toStringAsFixed(1);

  /// Get formatted distance
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Get formatted ETA
  String get formattedEta {
    if (etaMinutes == null) return '';
    if (etaMinutes! < 60) {
      return '$etaMinutes min';
    }
    final hours = etaMinutes! ~/ 60;
    final mins = etaMinutes! % 60;
    return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
  }
}

/// Mock contractors for development
class MockContractors {
  static List<Contractor> getForTask({int? budget}) {
    return [
      Contractor(
        id: '1',
        name: 'Adam Kowalski',
        avatarUrl: null,
        rating: 4.9,
        completedTasks: 127,
        reviewCount: 98,
        isVerified: true,
        isOnline: true,
        distanceKm: 0.8,
        etaMinutes: 12,
        proposedPrice: budget ?? 50,
        categories: ['paczki', 'zakupy'],
        memberSince: DateTime(2023, 3, 15),
      ),
      Contractor(
        id: '2',
        name: 'Piotr Nowak',
        avatarUrl: null,
        rating: 4.7,
        completedTasks: 89,
        reviewCount: 67,
        isVerified: true,
        isOnline: true,
        distanceKm: 1.2,
        etaMinutes: 18,
        proposedPrice: budget != null ? (budget * 0.9).round() : 45,
        categories: ['paczki', 'przeprowadzki'],
        memberSince: DateTime(2023, 6, 22),
      ),
      Contractor(
        id: '3',
        name: 'Michał Wiśniewski',
        avatarUrl: null,
        rating: 4.5,
        completedTasks: 45,
        reviewCount: 32,
        isVerified: true,
        isOnline: true,
        distanceKm: 2.1,
        etaMinutes: 25,
        proposedPrice: budget != null ? (budget * 0.85).round() : 42,
        categories: ['paczki', 'montaz', 'zakupy'],
        memberSince: DateTime(2024, 1, 10),
      ),
      Contractor(
        id: '4',
        name: 'Tomasz Kamiński',
        avatarUrl: null,
        rating: 4.3,
        completedTasks: 23,
        reviewCount: 18,
        isVerified: false,
        isOnline: true,
        distanceKm: 3.5,
        etaMinutes: 35,
        proposedPrice: budget != null ? (budget * 0.8).round() : 40,
        categories: ['paczki'],
        memberSince: DateTime(2024, 6, 1),
      ),
    ];
  }
}
