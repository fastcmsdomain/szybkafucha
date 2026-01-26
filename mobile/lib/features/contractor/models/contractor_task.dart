import '../../../features/client/models/task_category.dart';

/// Task model from contractor's perspective
class ContractorTask {
  final String id;
  final TaskCategory category;
  final String description;
  final String clientName;
  final String? clientAvatarUrl;
  final double clientRating;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int estimatedMinutes;
  final int price;
  final ContractorTaskStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isUrgent;

  const ContractorTask({
    required this.id,
    required this.category,
    required this.description,
    required this.clientName,
    this.clientAvatarUrl,
    this.clientRating = 0.0,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.price,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.isUrgent = false,
  });

  factory ContractorTask.fromJson(Map<String, dynamic> json) {
    // Map backend status to contractor task status
    final statusStr = json['status'] as String? ?? 'created';
    final status = _mapBackendStatus(statusStr);

    // Handle client data - may be nested object or flat fields
    final client = json['client'] as Map<String, dynamic>?;
    final clientName = client?['name'] as String? ??
                       client?['fullName'] as String? ??
                       client?['full_name'] as String? ??
                       json['clientName'] as String? ??
                       json['client_name'] as String? ??
                       'Klient';
    final clientRating = _parseDouble(client?['rating']) ??
                         _parseDouble(json['clientRating']) ??
                         _parseDouble(json['client_rating']) ??
                         0.0;
    final clientAvatarUrl = client?['avatarUrl'] as String? ??
                            client?['avatar_url'] as String? ??
                            json['clientAvatarUrl'] as String? ??
                            json['client_avatar_url'] as String?;

    return ContractorTask(
      id: json['id'] as String,
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.sprzatanie,
      ),
      // Backend may send title or description
      description: json['description'] as String? ?? json['title'] as String? ?? '',
      clientName: clientName,
      clientAvatarUrl: clientAvatarUrl,
      clientRating: clientRating,
      // Backend uses camelCase - may return String or num
      address: json['address'] as String? ?? '',
      latitude: _parseDouble(json['locationLat']) ??
                _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['locationLng']) ??
                 _parseDouble(json['longitude']) ?? 0.0,
      // Distance may not be provided by backend - default to 0
      distanceKm: _parseDouble(json['distanceKm']) ??
                  _parseDouble(json['distance_km']) ?? 0.0,
      // Estimated minutes - default to 15
      estimatedMinutes: _parseInt(json['estimatedMinutes']) ??
                        _parseInt(json['estimated_minutes']) ?? 15,
      // Budget from backend - may be String like "50.00"
      price: _parseInt(json['budgetAmount']) ??
             _parseInt(json['price']) ??
             _parseInt(json['budget']) ?? 0,
      status: status,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
        json['created_at'] as String? ??
        DateTime.now().toIso8601String()
      ),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : (json['accepted_at'] != null
              ? DateTime.parse(json['accepted_at'] as String)
              : null),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : (json['started_at'] != null
              ? DateTime.parse(json['started_at'] as String)
              : null),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : (json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null),
      isUrgent: json['isUrgent'] as bool? ??
                json['is_urgent'] as bool? ??
                json['scheduledAt'] == null, // Immediate = urgent
    );
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

  /// Map backend status string to ContractorTaskStatus enum
  static ContractorTaskStatus _mapBackendStatus(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return ContractorTaskStatus.available;
      case 'accepted':
        return ContractorTaskStatus.accepted;
      case 'in_progress':
        return ContractorTaskStatus.inProgress;
      case 'completed':
        return ContractorTaskStatus.completed;
      case 'cancelled':
        return ContractorTaskStatus.cancelled;
      default:
        return ContractorTaskStatus.available;
    }
  }

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedEta {
    if (estimatedMinutes < 60) {
      return '$estimatedMinutes min';
    }
    final hours = estimatedMinutes ~/ 60;
    final mins = estimatedMinutes % 60;
    return '${hours}h ${mins}m';
  }

  String get formattedPrice => '$price PLN';

  double get earnings => price * 0.83; // 83% after 17% commission

  String get formattedEarnings => '${earnings.toStringAsFixed(0)} PLN';

  /// Mock tasks for development
  static List<ContractorTask> mockNearbyTasks() {
    final now = DateTime.now();
    return [
      ContractorTask(
        id: 'ct1',
        category: TaskCategory.sprzatanie,
        description:
            'Potrzebuję pomocy ze sprzątaniem 2-pokojowego mieszkania po remoncie. Około 50m2.',
        clientName: 'Anna K.',
        clientRating: 4.8,
        address: 'ul. Marszałkowska 100, Warszawa',
        latitude: 52.2297,
        longitude: 21.0122,
        distanceKm: 1.2,
        estimatedMinutes: 8,
        price: 180,
        status: ContractorTaskStatus.available,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isUrgent: true,
      ),
      ContractorTask(
        id: 'ct2',
        category: TaskCategory.zakupy,
        description:
            'Zakupy spożywcze w Biedronce - lista około 15 produktów. Preferuję dostawę do 14:00.',
        clientName: 'Piotr M.',
        clientRating: 4.5,
        address: 'ul. Puławska 45, Warszawa',
        latitude: 52.2050,
        longitude: 21.0230,
        distanceKm: 2.5,
        estimatedMinutes: 15,
        price: 50,
        status: ContractorTaskStatus.available,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      ContractorTask(
        id: 'ct3',
        category: TaskCategory.montaz,
        description:
            'Montaż szafy PAX z IKEA. Szafa 3-drzwiowa, wszystkie elementy są na miejscu.',
        clientName: 'Karolina W.',
        clientRating: 5.0,
        address: 'ul. Żelazna 28, Warszawa',
        latitude: 52.2320,
        longitude: 20.9850,
        distanceKm: 0.8,
        estimatedMinutes: 5,
        price: 250,
        status: ContractorTaskStatus.available,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
      ContractorTask(
        id: 'ct4',
        category: TaskCategory.przeprowadzki,
        description:
            'Pomoc przy przeprowadzce - przeniesienie mebli z 3 piętra do samochodu. Około 10 kartonów i kilka mebli.',
        clientName: 'Tomasz B.',
        clientRating: 4.2,
        address: 'ul. Hoża 15, Warszawa',
        latitude: 52.2230,
        longitude: 21.0180,
        distanceKm: 3.1,
        estimatedMinutes: 20,
        price: 200,
        status: ContractorTaskStatus.available,
        createdAt: now.subtract(const Duration(minutes: 35)),
      ),
    ];
  }

  static ContractorTask mockActiveTask() {
    return ContractorTask(
      id: 'active1',
      category: TaskCategory.sprzatanie,
      description:
          'Sprzątanie mieszkania 3-pokojowego. Proszę o dokładne sprzątanie łazienki.',
      clientName: 'Magdalena S.',
      clientAvatarUrl: null,
      clientRating: 4.9,
      address: 'ul. Nowy Świat 22/5, Warszawa',
      latitude: 52.2320,
      longitude: 21.0180,
      distanceKm: 1.5,
      estimatedMinutes: 10,
      price: 200,
      status: ContractorTaskStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      acceptedAt: DateTime.now().subtract(const Duration(minutes: 50)),
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );
  }
}

enum ContractorTaskStatus {
  available,
  offered, // Contractor received notification
  accepted,
  inProgress,
  completed,
  cancelled,
}

extension ContractorTaskStatusExtension on ContractorTaskStatus {
  String get displayName {
    switch (this) {
      case ContractorTaskStatus.available:
        return 'Dostępne';
      case ContractorTaskStatus.offered:
        return 'Nowe zlecenie';
      case ContractorTaskStatus.accepted:
        return 'Zaakceptowane';
      case ContractorTaskStatus.inProgress:
        return 'W trakcie';
      case ContractorTaskStatus.completed:
        return 'Zakończone';
      case ContractorTaskStatus.cancelled:
        return 'Anulowane';
    }
  }

  bool get isActive =>
      this == ContractorTaskStatus.accepted ||
      this == ContractorTaskStatus.inProgress;
}
