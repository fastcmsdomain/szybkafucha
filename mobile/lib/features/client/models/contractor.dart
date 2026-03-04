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
  final int? proposedPrice;
  final List<String> categories;
  final DateTime? memberSince;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? email;
  final String? phone;

  const Contractor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.rating = 0.0,
    this.completedTasks = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.proposedPrice,
    this.categories = const [],
    this.memberSince,
    this.dateOfBirth,
    this.bio,
    this.email,
    this.phone,
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
      dateOfBirth: _parseDate(
        json['dateOfBirth'] ?? json['date_of_birth'] ?? json['birthDate'],
      ),
      bio: (json['bio'] ??
              json['description'] ??
              json['about'] ??
              json['bioText']) as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
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
        'proposed_price': proposedPrice,
        'categories': categories,
        'member_since': memberSince?.toIso8601String(),
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'bio': bio,
        'email': email,
        'phone': phone,
      };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Get formatted rating with one decimal
  String get formattedRating => rating.toStringAsFixed(1);

  String get formattedDateOfBirth {
    if (dateOfBirth == null) return '';
    final date = dateOfBirth!;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
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

        proposedPrice: budget != null ? (budget * 0.8).round() : 40,
        categories: ['paczki'],
        memberSince: DateTime(2024, 6, 1),
      ),
    ];
  }
}
