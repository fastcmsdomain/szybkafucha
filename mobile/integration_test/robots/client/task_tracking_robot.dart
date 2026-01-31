import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../config/test_config.dart';
import '../base_robot.dart';

/// Robot for task tracking screen (client side)
class TaskTrackingRobot extends BaseRobot {
  TaskTrackingRobot(super.tester);

  /// Wait for tracking screen to load
  Future<void> waitForTrackingScreen() async {
    // Wait for any tracking screen indicator
    await waitForWidget(
      find.byIcon(Icons.location_on),
      timeout: const Duration(seconds: 10),
    );
    await settle();
  }

  /// Navigate to task tracking from task list
  Future<void> navigateToTask(String taskId) async {
    // Find task in list and tap
    await scrollUntilVisible(find.text(taskId));
    await tap(find.text(taskId));
    await waitForTrackingScreen();
  }

  /// Get current task status from UI
  Future<String> getCurrentStatus() async {
    // Check for status indicators
    if (find.text('Szukamy wykonawcy').evaluate().isNotEmpty) {
      return 'posted';
    }
    if (find.text('Wykonawca zaakceptował').evaluate().isNotEmpty) {
      return 'accepted';
    }
    if (find.text('Potwierdzone').evaluate().isNotEmpty) {
      return 'confirmed';
    }
    if (find.text('W trakcie').evaluate().isNotEmpty) {
      return 'in_progress';
    }
    if (find.text('Zakończone').evaluate().isNotEmpty) {
      return 'completed';
    }
    if (find.text('Anulowane').evaluate().isNotEmpty) {
      return 'cancelled';
    }
    return 'unknown';
  }

  /// Wait for task status to change
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
      await pullToRefresh();
    }

    throw Exception(
      'Task did not reach status $expectedStatus within ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Wait for contractor to be assigned
  Future<void> waitForContractorAssigned() async {
    await waitForWidget(
      find.text('Wykonawca zaakceptował'),
      timeout: TestConfig.defaultTimeout,
    );
    await settle();
  }

  /// Confirm contractor (accept the assigned contractor)
  Future<void> confirmContractor() async {
    await tap(find.text('Potwierdź wykonawcę'));
    await waitForLoading();
    await settle();
  }

  /// Reject contractor (look for another)
  Future<void> rejectContractor({String? reason}) async {
    await tap(find.text('Szukaj innego'));
    await settle();

    // If reason dialog appears
    if (reason != null) {
      final reasonField = find.byType(TextField);
      if (reasonField.evaluate().isNotEmpty) {
        await enterText(reasonField, reason);
      }
    }

    // Confirm rejection
    final confirmButton = find.text('Potwierdź');
    if (confirmButton.evaluate().isNotEmpty) {
      await tap(confirmButton);
    }
    await waitForLoading();
  }

  /// Cancel the task
  Future<void> cancelTask({String? reason}) async {
    // Find cancel button (might be in menu)
    final cancelButton = find.text('Anuluj zlecenie');
    if (cancelButton.evaluate().isNotEmpty) {
      await tap(cancelButton);
    } else {
      // Try menu
      await tapIcon(Icons.more_vert);
      await settle();
      await tap(find.text('Anuluj'));
    }
    await settle();

    // Enter reason if requested
    if (reason != null) {
      final reasonField = find.byType(TextField);
      if (reasonField.evaluate().isNotEmpty) {
        await enterText(reasonField, reason);
      }
    }

    // Confirm cancellation
    await tap(find.text('Potwierdź anulowanie'));
    await waitForLoading();
  }

  /// Wait for task completion
  Future<void> waitForCompletion() async {
    await waitForWidget(
      find.text('Zakończone'),
      timeout: TestConfig.defaultTimeout,
    );
    await settle();
  }

  /// Navigate to task completion/rating screen
  Future<void> navigateToCompletion() async {
    await tap(find.text('Potwierdź wykonanie'));
    await settle();
  }

  /// Confirm task completion
  Future<void> confirmCompletion() async {
    await tap(find.text('Potwierdź wykonanie'));
    await waitForLoading();
  }

  /// Rate the contractor (after task completion)
  Future<void> rateContractor({
    required int rating,
    String? comment,
  }) async {
    // Wait for rating screen
    await waitForWidget(find.text('Oceń wykonawcę'));

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

  /// Complete the full rating flow
  Future<void> completeRatingFlow({
    required int rating,
    String? comment,
  }) async {
    await confirmCompletion();
    await rateContractor(rating: rating, comment: comment);
  }

  /// Verify task is cancelled
  void verifyTaskCancelled() {
    verifyTextExists('Anulowane');
  }

  /// Verify task is completed
  void verifyTaskCompleted() {
    verifyTextExists('Zakończone');
  }

  /// Verify contractor is assigned
  void verifyContractorAssigned() {
    expect(
      find.text('Wykonawca zaakceptował'),
      findsOneWidget,
    );
  }
}
