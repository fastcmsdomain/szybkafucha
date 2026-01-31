import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/test_config.dart';
import '../base_robot.dart';

/// Robot for contractor task list screen
class TaskListRobot extends BaseRobot {
  TaskListRobot(super.tester);

  /// Wait for task list screen to load
  Future<void> waitForTaskListScreen() async {
    await waitForWidget(find.text('Dostępne zlecenia'));
    await settle();
  }

  /// Refresh the task list
  Future<void> refreshTasks() async {
    await pullToRefresh();
    await waitForLoading();
  }

  /// Tap refresh button
  Future<void> tapRefreshButton() async {
    await tap(find.byIcon(Icons.refresh));
    await waitForLoading();
  }

  /// Switch to list tab
  Future<void> switchToListTab() async {
    await tap(find.text('LISTA'));
    await settle();
  }

  /// Switch to map tab
  Future<void> switchToMapTab() async {
    await tap(find.text('MAPA'));
    await settle();
  }

  /// Find task by description text
  Future<bool> findTaskByDescription(String description) async {
    await settle();
    return find.text(description).evaluate().isNotEmpty;
  }

  /// Wait for task to appear in list
  Future<void> waitForTask(String description, {Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < effectiveTimeout) {
      await refreshTasks();
      if (await findTaskByDescription(description)) {
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
    }

    throw Exception(
      'Task "$description" not found within ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Wait for any new task to appear
  Future<void> waitForAnyTask({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < effectiveTimeout) {
      await refreshTasks();
      // Check if there are any task cards
      final taskCards = find.text('PLN');
      if (taskCards.evaluate().isNotEmpty) {
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
    }

    throw Exception(
      'No tasks found within ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Tap on a task card to view details
  Future<void> tapTask(String description) async {
    await scrollUntilVisible(find.text(description));
    await tap(find.text(description));
    await settle();
  }

  /// Accept a task directly from the list
  Future<void> acceptTaskFromList(String description) async {
    // Find the task card
    await scrollUntilVisible(find.text(description));

    // Find the accept button in the same card
    // This might be an "Akceptuj" button
    final acceptButton = find.text('Akceptuj');
    if (acceptButton.evaluate().isNotEmpty) {
      await tap(acceptButton);
    } else {
      // Tap on task to go to details
      await tap(find.text(description));
      await settle();
      // Then accept from details
      await tap(find.text('Akceptuj zlecenie'));
    }
    await waitForLoading();
  }

  /// Accept the first available task
  Future<void> acceptFirstTask() async {
    await switchToListTab();
    await settle();

    // Find first accept button
    final acceptButtons = find.text('Akceptuj');
    if (acceptButtons.evaluate().isNotEmpty) {
      await tester.tap(acceptButtons.first);
      await waitForLoading();
    } else {
      throw Exception('No tasks available to accept');
    }
  }

  /// Get count of available tasks
  Future<int> getTaskCount() async {
    // Look for task count badge or count tasks
    final countText = find.textContaining('zleceń');
    if (countText.evaluate().isNotEmpty) {
      final text = (countText.evaluate().first.widget as Text).data ?? '0';
      final match = RegExp(r'(\d+)').firstMatch(text);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return 0;
  }

  /// Verify no tasks are available
  void verifyNoTasks() {
    expect(
      find.text('Brak dostępnych zleceń'),
      findsOneWidget,
    );
  }

  /// Verify task count
  Future<void> verifyTaskCount(int expected) async {
    final count = await getTaskCount();
    expect(count, equals(expected));
  }

  /// Navigate back to contractor home
  Future<void> navigateBack() async {
    await tapIcon(Icons.arrow_back);
    await settle();
  }
}
