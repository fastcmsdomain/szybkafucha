import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/test_config.dart';

/// Base robot class with common helpers for all page objects
abstract class BaseRobot {
  final WidgetTester tester;

  BaseRobot(this.tester);

  /// Wait for widget to appear
  Future<void> waitForWidget(
    Finder finder, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < effectiveTimeout) {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
    }

    throw Exception(
      'Widget not found: ${finder.description} after ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Wait for widget to disappear
  Future<void> waitForWidgetToDisappear(
    Finder finder, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? TestConfig.defaultTimeout;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < effectiveTimeout) {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      if (finder.evaluate().isEmpty) {
        return;
      }
      await Future.delayed(TestConfig.pollInterval);
    }

    throw Exception(
      'Widget still visible: ${finder.description} after ${effectiveTimeout.inSeconds}s',
    );
  }

  /// Tap a widget
  Future<void> tap(Finder finder) async {
    await waitForWidget(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Tap widget by text
  Future<void> tapText(String text) async {
    await tap(find.text(text));
  }

  /// Tap widget by key
  Future<void> tapKey(Key key) async {
    await tap(find.byKey(key));
  }

  /// Tap widget by icon
  Future<void> tapIcon(IconData icon) async {
    await tap(find.byIcon(icon));
  }

  /// Tap the first widget matching the finder
  Future<void> tapFirst(Finder finder) async {
    await waitForWidget(finder);
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  /// Enter text in a text field
  Future<void> enterText(Finder finder, String text) async {
    await waitForWidget(finder);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Enter text by text field key
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
  }

  /// Enter text in a text field found by label
  Future<void> enterTextByLabel(String label, String text) async {
    // Find TextField by its decoration label
    final finder = find.ancestor(
      of: find.text(label),
      matching: find.byType(TextField),
    );
    await enterText(finder, text);
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder, {
    Finder? scrollable,
    double delta = -100,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable).first;

    while (finder.evaluate().isEmpty) {
      await tester.drag(scrollableFinder, Offset(0, delta));
      await tester.pumpAndSettle();
    }
  }

  /// Scroll down
  Future<void> scrollDown({double delta = 300}) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, Offset(0, -delta));
    await tester.pumpAndSettle();
  }

  /// Scroll up
  Future<void> scrollUp({double delta = 300}) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, Offset(0, delta));
    await tester.pumpAndSettle();
  }

  /// Pull to refresh
  Future<void> pullToRefresh() async {
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, 300));
    await tester.pumpAndSettle();
  }

  /// Verify widget exists
  void verifyExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify text exists
  void verifyTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verify widget does not exist
  void verifyNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify text does not exist
  void verifyTextNotExists(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Wait for loading indicator to disappear
  Future<void> waitForLoading() async {
    // Wait for any CircularProgressIndicator to disappear
    await Future.delayed(TestConfig.uiDelay);
    try {
      await waitForWidgetToDisappear(
        find.byType(CircularProgressIndicator),
        timeout: TestConfig.networkDelay,
      );
    } catch (_) {
      // Loading indicator may not exist, which is fine
    }
    await tester.pumpAndSettle();
  }

  /// Pump and settle with custom duration
  Future<void> settle([Duration? duration]) async {
    await tester.pumpAndSettle(duration ?? TestConfig.uiDelay);
  }

  /// Wait for snackbar with message
  Future<void> waitForSnackbar(String message) async {
    await waitForWidget(find.text(message));
    // Wait for snackbar to auto-dismiss or dismiss manually
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  /// Dismiss snackbar if visible
  Future<void> dismissSnackbar() async {
    final snackbar = find.byType(SnackBar);
    if (snackbar.evaluate().isNotEmpty) {
      // Swipe to dismiss
      await tester.drag(snackbar, const Offset(0, 100));
      await tester.pumpAndSettle();
    }
  }

  /// Take screenshot for debugging (prints widget tree)
  void debugPrint() {
    debugDumpApp();
  }
}
