import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:szybka_fucha/features/client/models/task_category.dart';

import '../../config/test_config.dart';
import '../base_robot.dart';

/// Robot for task creation flow (client side)
class CreateTaskRobot extends BaseRobot {
  CreateTaskRobot(super.tester);

  /// Navigate to task creation (from client home)
  Future<void> navigateToCreateTask() async {
    // Tap the main CTA button or "Nowe zlecenie"
    final newTaskButton = find.text('Nowe zlecenie');
    if (newTaskButton.evaluate().isNotEmpty) {
      await tap(newTaskButton);
    } else {
      // Try the FAB or main button
      await tap(find.byIcon(Icons.add));
    }
    await settle();
  }

  /// Wait for category selection screen
  Future<void> waitForCategoryScreen() async {
    await waitForWidget(find.text('Czego potrzebujesz?'));
  }

  /// Select a task category
  Future<void> selectCategory(TaskCategory category) async {
    await waitForCategoryScreen();

    // Find category by name
    final categoryName = TaskCategoryData.fromCategory(category).name;
    await tap(find.text(categoryName));
    await settle();

    // Tap continue button
    await tap(find.text('Dalej'));
    await settle();
  }

  /// Wait for task details screen
  Future<void> waitForDetailsScreen() async {
    await waitForWidget(find.text('Szczegóły zlecenia'));
  }

  /// Enter task description
  Future<void> enterDescription(String description) async {
    // Find description text field
    final descField = find.byType(TextField).first;
    await enterText(descField, description);
  }

  /// Set task location (using default test location)
  Future<void> setLocation({
    double lat = TestConfig.testLocationLat,
    double lng = TestConfig.testLocationLng,
    String address = TestConfig.testTaskAddress,
  }) async {
    // Tap on location field or map
    final locationField = find.text('Wybierz lokalizację');
    if (locationField.evaluate().isNotEmpty) {
      await tap(locationField);
      await settle();

      // Enter address
      final addressField = find.byType(TextField);
      await enterText(addressField.first, address);

      // Select first suggestion
      await Future.delayed(const Duration(seconds: 1));
      await settle();

      // Confirm location
      await tap(find.text('Potwierdź'));
    } else {
      // Address might already be editable
      final addressField = find.ancestor(
        of: find.text('Adres'),
        matching: find.byType(TextField),
      );
      if (addressField.evaluate().isNotEmpty) {
        await enterText(addressField, address);
      }
    }
    await settle();
  }

  /// Set task budget
  Future<void> setBudget(double amount) async {
    // Find budget field
    final budgetField = find.ancestor(
      of: find.text('Budżet'),
      matching: find.byType(TextField),
    );

    if (budgetField.evaluate().isNotEmpty) {
      await enterText(budgetField, amount.toStringAsFixed(0));
    } else {
      // Try to find by hint text
      final hintField = find.widgetWithText(TextField, 'PLN');
      if (hintField.evaluate().isNotEmpty) {
        await enterText(hintField, amount.toStringAsFixed(0));
      }
    }
    await settle();
  }

  /// Submit task creation form
  Future<void> submitTask() async {
    // Find and tap submit/create button
    final submitButton = find.text('Utwórz zlecenie');
    if (submitButton.evaluate().isNotEmpty) {
      await tap(submitButton);
    } else {
      await tap(find.text('Dalej'));
    }
    await waitForLoading();
  }

  /// Complete full task creation flow
  /// Returns the task ID if possible (from navigation or response)
  Future<void> createTask({
    TaskCategory category = TaskCategory.paczki,
    String description = TestConfig.testTaskDescription,
    String address = TestConfig.testTaskAddress,
    double budget = TestConfig.testTaskBudget,
  }) async {
    // Navigate to create task
    await navigateToCreateTask();

    // Select category
    await selectCategory(category);

    // Wait for details screen
    await waitForDetailsScreen();

    // Fill in details
    await enterDescription(description);
    await setLocation(address: address);
    await setBudget(budget);

    // Submit
    await submitTask();

    // Should navigate to payment or tracking screen
    await settle();
  }

  /// Wait for payment screen
  Future<void> waitForPaymentScreen() async {
    await waitForWidget(find.text('Płatność'));
  }

  /// Confirm payment (mock)
  Future<void> confirmPayment() async {
    await waitForPaymentScreen();
    await tap(find.text('Zapłać'));
    await waitForLoading();
  }

  /// Skip payment in test mode
  Future<void> skipPayment() async {
    // In test mode, payment might be mocked
    final skipButton = find.text('Pomiń');
    if (skipButton.evaluate().isNotEmpty) {
      await tap(skipButton);
    }
    await settle();
  }
}
