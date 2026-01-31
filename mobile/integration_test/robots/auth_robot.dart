import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/test_config.dart';
import 'base_robot.dart';

/// Robot for authentication flows (login, registration)
class AuthRobot extends BaseRobot {
  AuthRobot(super.tester);

  /// Wait for welcome screen to load
  Future<void> waitForWelcomeScreen() async {
    // Look for the user type selection buttons on welcome screen
    await waitForWidget(find.text('Szukam pomocy'));
    await settle();
  }

  /// Select user type (client or contractor)
  Future<void> selectUserType(DeviceRole role) async {
    if (role == DeviceRole.client) {
      // Find and tap the "Szukam pomocy" option (client)
      await tap(find.text('Szukam pomocy'));
    } else {
      // Find and tap the "Chcę pomagać" option (contractor)
      await tap(find.text('Chcę pomagać'));
    }
    await settle();
  }

  /// Tap phone login button
  Future<void> tapPhoneLogin() async {
    // Find the phone login button
    await tap(find.byIcon(Icons.phone_android));
    await settle();
  }

  /// Enter phone number on phone login screen
  Future<void> enterPhoneNumber(String phone) async {
    await waitForWidget(find.byType(TextField));
    // Find the phone text field
    final phoneFinder = find.byType(TextField);
    await enterText(phoneFinder, phone);
    await settle();
  }

  /// Submit phone number
  Future<void> submitPhoneNumber() async {
    // Tap continue/submit button
    await tap(find.text('Dalej'));
    await waitForLoading();
  }

  /// Enter OTP code on verification screen
  Future<void> enterOtpCode(String code) async {
    // The OTP might be in multiple text fields
    // Try to find a single text field first
    final singleField = find.byType(TextField);
    if (singleField.evaluate().length == 1) {
      await enterText(singleField, code);
    } else {
      // OTP fields are separate - enter each digit
      final fields = singleField.evaluate().toList();
      for (var i = 0; i < code.length && i < fields.length; i++) {
        await tester.enterText(
          find.byWidget(fields[i].widget),
          code[i],
        );
      }
    }
    await settle();
  }

  /// Submit OTP code
  Future<void> submitOtpCode() async {
    await tap(find.text('Weryfikuj'));
    await waitForLoading();
  }

  /// Complete phone login flow
  Future<void> loginWithPhone({
    required String phone,
    required String otp,
    required DeviceRole role,
  }) async {
    await waitForWelcomeScreen();
    await selectUserType(role);
    await tapPhoneLogin();
    await enterPhoneNumber(phone);
    await submitPhoneNumber();
    await enterOtpCode(otp);
    await submitOtpCode();
    // Wait for redirect to home screen
    await waitForHomeScreen(role);
  }

  /// Login as client using test credentials
  Future<void> loginAsClient() async {
    await loginWithPhone(
      phone: TestConfig.clientPhone,
      otp: TestConfig.testOtpCode,
      role: DeviceRole.client,
    );
  }

  /// Login as contractor using test credentials
  Future<void> loginAsContractor() async {
    await loginWithPhone(
      phone: TestConfig.contractorPhone,
      otp: TestConfig.testOtpCode,
      role: DeviceRole.contractor,
    );
  }

  /// Wait for home screen after login
  Future<void> waitForHomeScreen(DeviceRole role) async {
    if (role == DeviceRole.client) {
      // Client home screen - look for characteristic elements
      await waitForWidget(
        find.text('Co potrzebujesz zrobić?'),
        timeout: const Duration(seconds: 10),
      );
    } else {
      // Contractor home screen
      await waitForWidget(
        find.text('Dostępne zlecenia'),
        timeout: const Duration(seconds: 10),
      );
    }
    await settle();
  }

  /// Verify user is logged in as expected role
  void verifyLoggedIn(DeviceRole role) {
    if (role == DeviceRole.client) {
      verifyTextExists('Co potrzebujesz zrobić?');
    } else {
      verifyTextExists('Dostępne zlecenia');
    }
  }

  /// Logout from the app
  Future<void> logout() async {
    // Navigate to profile/settings
    await tapIcon(Icons.person_outline);
    await settle();

    // Find and tap logout
    await scrollUntilVisible(find.text('Wyloguj'));
    await tap(find.text('Wyloguj'));
    await settle();

    // Confirm logout if dialog appears
    final confirmButton = find.text('Potwierdź');
    if (confirmButton.evaluate().isNotEmpty) {
      await tap(confirmButton);
    }

    await waitForWelcomeScreen();
  }
}
