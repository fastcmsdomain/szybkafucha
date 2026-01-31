import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/test_config.dart';
import '../base_robot.dart';

/// Robot for contractor's active task screen
class ActiveTaskRobot extends BaseRobot {
  ActiveTaskRobot(super.tester);

  /// Wait for active task screen to load
  Future<void> waitForActiveTaskScreen() async {
    await waitForWidget(
      find.text('Aktywne zlecenie'),
      timeout: const Duration(seconds: 10),
    );
    await settle();
  }

  /// Wait for task details screen (after accepting)
  Future<void> waitForTaskDetails() async {
    // Wait for any task detail indicator
    await Future.delayed(TestConfig.uiDelay);
    await settle();
  }

  /// Accept task from details screen
  Future<void> acceptTask() async {
    await tap(find.text('Akceptuj zlecenie'));
    await waitForLoading();
  }

  /// Wait for client confirmation
  Future<void> waitForClientConfirmation({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < effectiveTimeout) {
      await settle();
      // Check for confirmation status
      if (find.text('Potwierdzone').evaluate().isNotEmpty ||
          find.text('Klient potwierdził').evaluate().isNotEmpty) {
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
      await pullToRefresh();
    }

    throw Exception(
      'Client did not confirm within ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Start working on the task
  Future<void> startTask() async {
    await tap(find.text('Rozpocznij'));
    await waitForLoading();
  }

  /// Mark task as completed
  Future<void> completeTask() async {
    await tap(find.text('Zakończ'));
    await waitForLoading();
  }

  /// Complete task with photos
  Future<void> completeTaskWithPhotos(List<String> photoPaths) async {
    // Tap add photos if available
    final addPhotosButton = find.text('Dodaj zdjęcia');
    if (addPhotosButton.evaluate().isNotEmpty) {
      await tap(addPhotosButton);
      // In test mode, photos might be mocked
      await settle();
    }

    await completeTask();
  }

  /// Cancel/release the task (contractor gives up)
  Future<void> cancelTask({String? reason}) async {
    // Find cancel button
    final cancelButton = find.text('Zrezygnuj');
    if (cancelButton.evaluate().isNotEmpty) {
      await tap(cancelButton);
    } else {
      // Try menu
      await tapIcon(Icons.more_vert);
      await settle();
      await tap(find.text('Zrezygnuj'));
    }
    await settle();

    // Enter reason if provided
    if (reason != null) {
      final reasonField = find.byType(TextField);
      if (reasonField.evaluate().isNotEmpty) {
        await enterText(reasonField, reason);
      }
    }

    // Confirm
    await tap(find.text('Potwierdź'));
    await waitForLoading();
  }

  /// Get current task status
  Future<String> getCurrentStatus() async {
    if (find.text('Oczekuje na potwierdzenie').evaluate().isNotEmpty) {
      return 'accepted';
    }
    if (find.text('Potwierdzone').evaluate().isNotEmpty ||
        find.text('Klient potwierdził').evaluate().isNotEmpty) {
      return 'confirmed';
    }
    if (find.text('W trakcie').evaluate().isNotEmpty) {
      return 'in_progress';
    }
    if (find.text('Zakończone').evaluate().isNotEmpty) {
      return 'completed';
    }
    return 'unknown';
  }

  /// Wait for specific task status
  Future<void> waitForStatus(String expectedStatus, {Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < effectiveTimeout) {
      await settle();
      final currentStatus = await getCurrentStatus();
      if (currentStatus == expectedStatus) {
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
    }

    throw Exception(
      'Task did not reach status $expectedStatus within ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Navigate to task completion/rating screen
  Future<void> navigateToCompletion() async {
    await tap(find.text('Oceń klienta'));
    await settle();
  }

  /// Rate the client after task completion
  Future<void> rateClient({
    required int rating,
    String? comment,
  }) async {
    // Wait for rating screen
    await waitForWidget(find.text('Oceń klienta'));

    // Select stars
    final stars = find.byIcon(Icons.star_border);
    for (var i = 0; i < rating && i < stars.evaluate().length; i++) {
      await tester.tap(stars.at(i));
      await settle();
    }

    // Add comment if provided
    if (comment != null) {
      final commentField = find.byType(TextField);
      if (commentField.evaluate().isNotEmpty) {
        await enterText(commentField, comment);
      }
    }

    // Submit rating
    await tap(find.text('Wyślij ocenę'));
    await waitForLoading();
  }

  /// Complete the full task flow (start -> complete -> rate)
  Future<void> completeFullTaskFlow({
    required int rating,
    String? comment,
  }) async {
    // Wait for client confirmation first
    await waitForClientConfirmation();

    // Start task
    await startTask();

    // Complete task
    await completeTask();

    // Rate client
    await rateClient(rating: rating, comment: comment);
  }

  /// Verify task is in progress
  void verifyTaskInProgress() {
    expect(find.text('W trakcie'), findsOneWidget);
  }

  /// Verify task is completed
  void verifyTaskCompleted() {
    verifyTextExists('Zakończone');
  }

  /// Verify no active task
  void verifyNoActiveTask() {
    expect(
      find.text('Brak aktywnego zlecenia'),
      findsOneWidget,
    );
  }

  /// Navigate back to home
  Future<void> navigateToHome() async {
    await tapIcon(Icons.home);
    await settle();
  }

  /// Check if task was released (client rejected or cancelled)
  Future<bool> wasTaskReleased() async {
    await settle();
    // Check for indicators that task was taken away
    return find.text('Zlecenie anulowane').evaluate().isNotEmpty ||
        find.text('Klient wybrał innego').evaluate().isNotEmpty ||
        find.text('Brak aktywnego zlecenia').evaluate().isNotEmpty;
  }
}
