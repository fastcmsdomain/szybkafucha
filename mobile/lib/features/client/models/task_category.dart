import 'package:flutter/material.dart';

/// Task categories available in Szybka Fucha
enum TaskCategory {
  paczki,
  zakupy,
  kolejki,
  montaz,
  przeprowadzki,
  sprzatanie,
}

/// Category data with display info and pricing
class TaskCategoryData {
  final TaskCategory category;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int minPrice;
  final int maxPrice;
  final String priceUnit; // 'PLN' or 'PLN/h'
  final int estimatedMinutes;

  const TaskCategoryData({
    required this.category,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.minPrice,
    required this.maxPrice,
    this.priceUnit = 'PLN',
    required this.estimatedMinutes,
  });

  /// Get suggested price (middle of range)
  int get suggestedPrice => (minPrice + maxPrice) ~/ 2;

  /// Format price range for display
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

  /// All available categories with their data
  static const List<TaskCategoryData> all = [
    TaskCategoryData(
      category: TaskCategory.paczki,
      name: 'Paczki',
      description: 'Odbiór i dostawa paczek',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF6366F1), // Indigo
      minPrice: 30,
      maxPrice: 60,
      estimatedMinutes: 30,
    ),
    TaskCategoryData(
      category: TaskCategory.zakupy,
      name: 'Zakupy',
      description: 'Zakupy i dostawy',
      icon: Icons.shopping_cart_outlined,
      color: Color(0xFF10B981), // Emerald
      minPrice: 40,
      maxPrice: 80,
      estimatedMinutes: 45,
    ),
    TaskCategoryData(
      category: TaskCategory.kolejki,
      name: 'Kolejki',
      description: 'Czekanie w kolejkach',
      icon: Icons.schedule_outlined,
      color: Color(0xFFF59E0B), // Amber
      minPrice: 50,
      maxPrice: 100,
      priceUnit: 'PLN/h',
      estimatedMinutes: 60,
    ),
    TaskCategoryData(
      category: TaskCategory.montaz,
      name: 'Montaż',
      description: 'Składanie mebli i drobne naprawy',
      icon: Icons.build_outlined,
      color: Color(0xFF3B82F6), // Blue
      minPrice: 60,
      maxPrice: 120,
      estimatedMinutes: 90,
    ),
    TaskCategoryData(
      category: TaskCategory.przeprowadzki,
      name: 'Przeprowadzki',
      description: 'Pomoc przy przeprowadzce',
      icon: Icons.local_shipping_outlined,
      color: Color(0xFF8B5CF6), // Violet
      minPrice: 80,
      maxPrice: 150,
      priceUnit: 'PLN/h',
      estimatedMinutes: 120,
    ),
    TaskCategoryData(
      category: TaskCategory.sprzatanie,
      name: 'Sprzątanie',
      description: 'Szybkie sprzątanie',
      icon: Icons.cleaning_services_outlined,
      color: Color(0xFFEC4899), // Pink
      minPrice: 100,
      maxPrice: 180,
      estimatedMinutes: 120,
    ),
  ];

  /// Get category data by enum
  static TaskCategoryData fromCategory(TaskCategory category) {
    return all.firstWhere((c) => c.category == category);
  }

  /// Get category data by name (case-insensitive)
  static TaskCategoryData? fromName(String name) {
    try {
      return all.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
