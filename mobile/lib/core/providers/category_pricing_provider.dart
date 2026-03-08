import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_exceptions.dart';
import '../../features/client/models/task_category.dart';
import 'api_provider.dart';

/// API response model for category pricing
class CategoryPricingResponse {
  final String category;
  final int minPrice;
  final int maxPrice;
  final int suggestedPrice;
  final String priceUnit;
  final int estimatedMinutes;

  const CategoryPricingResponse({
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.suggestedPrice,
    required this.priceUnit,
    required this.estimatedMinutes,
  });

  factory CategoryPricingResponse.fromJson(Map<String, dynamic> json) {
    return CategoryPricingResponse(
      category: json['category'] as String,
      minPrice: json['minPrice'] as int,
      maxPrice: json['maxPrice'] as int,
      suggestedPrice: json['suggestedPrice'] as int,
      priceUnit: json['priceUnit'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'suggestedPrice': suggestedPrice,
        'priceUnit': priceUnit,
        'estimatedMinutes': estimatedMinutes,
      };
}

/// State for category pricing
class CategoryPricingState {
  final Map<TaskCategory, CategoryPricingResponse> pricings;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetched;

  const CategoryPricingState({
    this.pricings = const {},
    this.isLoading = false,
    this.error,
    this.lastFetched,
  });

  CategoryPricingState copyWith({
    Map<TaskCategory, CategoryPricingResponse>? pricings,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
    bool clearError = false,
  }) {
    return CategoryPricingState(
      pricings: pricings ?? this.pricings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  /// Get pricing for a specific category
  /// Returns API pricing if available, otherwise uses hardcoded defaults
  CategoryPricingResponse? getPricing(TaskCategory category) {
    return pricings[category];
  }

  /// Check if cache is valid (less than 24 hours old)
  bool get isCacheValid {
    if (lastFetched == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastFetched!);
    return difference.inHours < 24;
  }
}

/// Category pricing provider - fetches from API with local cache fallback
final categoryPricingProvider =
    StateNotifierProvider<CategoryPricingNotifier, CategoryPricingState>((ref) {
  return CategoryPricingNotifier(ref);
});

class CategoryPricingNotifier extends StateNotifier<CategoryPricingState> {
  final Ref _ref;
  static const String _cacheKey = 'category_pricing_cache';
  static const String _cacheTimestampKey = 'category_pricing_timestamp';

  CategoryPricingNotifier(this._ref) : super(const CategoryPricingState()) {
    // Load cached data on init
    _loadCached();
  }

  /// Load cached pricing from SharedPreferences
  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      final timestampStr = prefs.getString(_cacheTimestampKey);

      if (cached != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final List<dynamic> jsonList = json.decode(cached) as List<dynamic>;
        final pricings = _parsePricingList(jsonList);

        state = state.copyWith(
          pricings: pricings,
          lastFetched: timestamp,
        );
      }
    } catch (e) {
      // Ignore cache errors, will fetch from API
    }
  }

  /// Save pricing to cache
  Future<void> _saveToCache(List<CategoryPricingResponse> pricings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = pricings.map((p) => p.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore cache save errors
    }
  }

  /// Parse pricing list from JSON
  Map<TaskCategory, CategoryPricingResponse> _parsePricingList(
      List<dynamic> jsonList) {
    final result = <TaskCategory, CategoryPricingResponse>{};

    for (final json in jsonList) {
      try {
        final pricing =
            CategoryPricingResponse.fromJson(json as Map<String, dynamic>);
        final category = _categoryFromString(pricing.category);
        if (category != null) {
          result[category] = pricing;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    return result;
  }

  /// Convert string to TaskCategory enum
  TaskCategory? _categoryFromString(String name) {
    try {
      return TaskCategory.values.firstWhere(
        (c) => c.name == name,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch pricing from API
  Future<void> fetchPricing({bool forceRefresh = false}) async {
    // Skip if already loading or cache is valid (unless forced)
    if (state.isLoading) return;
    if (!forceRefresh && state.isCacheValid && state.pricings.isNotEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/categories/pricing');
      final data = response as Map<String, dynamic>;

      final pricingList = (data['data'] as List)
          .map((json) =>
              CategoryPricingResponse.fromJson(json as Map<String, dynamic>))
          .toList();

      final pricings = _parsePricingList(
          pricingList.map((p) => p.toJson()).toList());

      state = state.copyWith(
        isLoading: false,
        pricings: pricings,
        lastFetched: DateTime.now(),
      );

      // Save to cache
      await _saveToCache(pricingList);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get effective pricing for a category
  /// Uses API data if available, otherwise falls back to hardcoded defaults
  CategoryPricingData getEffectivePricing(TaskCategory category) {
    final apiPricing = state.pricings[category];
    final defaultData = TaskCategoryData.fromCategory(category);

    if (apiPricing != null) {
      // Return data with API pricing, keeping default icon/color/name
      return CategoryPricingData(
        category: category,
        name: defaultData.name,
        description: defaultData.description,
        icon: defaultData.icon,
        color: defaultData.color,
        minPrice: apiPricing.minPrice,
        maxPrice: apiPricing.maxPrice,
        suggestedPrice: apiPricing.suggestedPrice,
        priceUnit: apiPricing.priceUnit,
        estimatedMinutes: apiPricing.estimatedMinutes,
      );
    }

    // Fallback to hardcoded defaults
    return CategoryPricingData.fromTaskCategoryData(defaultData);
  }
}

/// Combined category data with pricing (API or hardcoded)
class CategoryPricingData {
  final TaskCategory category;
  final String name;
  final String description;
  final dynamic icon;
  final dynamic color;
  final int minPrice;
  final int maxPrice;
  final int suggestedPrice;
  final String priceUnit;
  final int estimatedMinutes;

  const CategoryPricingData({
    required this.category,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.minPrice,
    required this.maxPrice,
    required this.suggestedPrice,
    required this.priceUnit,
    required this.estimatedMinutes,
  });

  /// Create from hardcoded TaskCategoryData
  factory CategoryPricingData.fromTaskCategoryData(TaskCategoryData data) {
    return CategoryPricingData(
      category: data.category,
      name: data.name,
      description: data.description,
      icon: data.icon,
      color: data.color,
      minPrice: data.minPrice,
      maxPrice: data.maxPrice,
      suggestedPrice: data.suggestedPrice,
      priceUnit: data.priceUnit,
      estimatedMinutes: data.estimatedMinutes,
    );
  }

  /// Format price range for display: "80-200 PLN/h"
  String get priceRange => '$minPrice-$maxPrice $priceUnit';

  /// Format estimated time for display
  String get estimatedTime {
    if (estimatedMinutes < 60) {
      return '~$estimatedMinutes min';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final mins = estimatedMinutes % 60;
      if (mins == 0) {
        return '~$hours h';
      }
      return '~$hours h $mins min';
    }
  }

  /// Format full pricing info for display
  /// e.g., "Sugerowana: 140 PLN (zakres 80-200 PLN)"
  String get displayPriceInfo =>
      'Sugerowana: $suggestedPrice PLN (zakres $minPrice-$maxPrice $priceUnit)';
}
