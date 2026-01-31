/// Full Task Lifecycle Test
///
/// Tests the complete task flow from creation to completion with reviews:
/// 1. Client creates task (POSTED)
/// 2. Contractor accepts task (ACCEPTED)
/// 3. Client confirms contractor (CONFIRMED)
/// 4. Contractor starts task (IN_PROGRESS)
/// 5. Contractor completes task (COMPLETED)
/// 6. Client confirms and rates contractor
/// 7. Contractor rates client
///
/// This test runs on TWO devices simultaneously:
/// - Device 1: Client flow (DEVICE_ROLE=client)
/// - Device 2: Contractor flow (DEVICE_ROLE=contractor)

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:szybka_fucha/features/client/models/task_category.dart';

import '../config/test_config.dart';
import '../utils/test_app.dart';
import '../utils/test_sync.dart';
import '../robots/auth_robot.dart';
import '../robots/client/create_task_robot.dart';
import '../robots/client/task_tracking_robot.dart';
import '../robots/contractor/task_list_robot.dart';
import '../robots/contractor/active_task_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Determine device role from environment
  final deviceRole = DeviceRole.fromEnvironment();

  group('Full Task Lifecycle', () {
    setUpAll(() async {
      // Initialize sync directory
      await TestSync.initialize();
      TestSync.log(deviceRole, 'Starting full lifecycle test');
    });

    tearDownAll(() async {
      TestSync.log(deviceRole, 'Test completed');
    });

    if (deviceRole == DeviceRole.client) {
      _runClientTest();
    } else {
      _runContractorTest();
    }
  });
}

/// Client-side test flow
void _runClientTest() {
  testWidgets('Client: Full task lifecycle', (tester) async {
    final deviceRole = DeviceRole.client;
    TestSync.log(deviceRole, '=== CLIENT TEST STARTED ===');

    // Launch app
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    // Initialize robots
    final authRobot = AuthRobot(tester);
    final createTaskRobot = CreateTaskRobot(tester);
    final trackingRobot = TaskTrackingRobot(tester);

    // ========================================
    // STEP 1: Login as client
    // ========================================
    TestSync.log(deviceRole, 'Step 1: Logging in as client');
    await authRobot.loginAsClient();
    TestSync.log(deviceRole, 'Login successful');

    // ========================================
    // STEP 2: Create a task
    // ========================================
    TestSync.log(deviceRole, 'Step 2: Creating task');
    await createTaskRobot.createTask(
      category: TaskCategory.paczki,
      description: TestConfig.testTaskDescription,
      address: TestConfig.testTaskAddress,
      budget: TestConfig.testTaskBudget,
    );
    TestSync.log(deviceRole, 'Task created');

    // Signal task creation to contractor
    await TestSync.setMarker(SyncMarkers.taskCreated, 'true');
    await TestSync.setMarker(SyncMarkers.taskId, TestConfig.testTaskDescription);
    TestSync.log(deviceRole, 'Signaled task creation');

    // ========================================
    // STEP 3: Wait for contractor to accept
    // ========================================
    TestSync.log(deviceRole, 'Step 3: Waiting for contractor acceptance');
    await TestSync.waitForMarkerValue(
      SyncMarkers.contractorAccepted,
      'true',
      timeout: const Duration(seconds: 60),
    );
    TestSync.log(deviceRole, 'Contractor accepted');

    // Refresh to see the update
    await trackingRobot.pullToRefresh();
    await tester.pumpAndSettle();

    // ========================================
    // STEP 4: Confirm the contractor
    // ========================================
    TestSync.log(deviceRole, 'Step 4: Confirming contractor');
    await trackingRobot.waitForContractorAssigned();
    await trackingRobot.confirmContractor();
    TestSync.log(deviceRole, 'Contractor confirmed');

    // Signal confirmation to contractor
    await TestSync.setMarker(SyncMarkers.clientConfirmed, 'true');

    // ========================================
    // STEP 5: Wait for task to be in progress
    // ========================================
    TestSync.log(deviceRole, 'Step 5: Waiting for task to start');
    await TestSync.waitForMarkerValue(
      SyncMarkers.taskInProgress,
      'true',
      timeout: const Duration(seconds: 60),
    );
    TestSync.log(deviceRole, 'Task is in progress');

    // ========================================
    // STEP 6: Wait for task completion
    // ========================================
    TestSync.log(deviceRole, 'Step 6: Waiting for task completion');
    await TestSync.waitForMarkerValue(
      SyncMarkers.taskCompleted,
      'true',
      timeout: const Duration(seconds: 60),
    );
    TestSync.log(deviceRole, 'Task completed by contractor');

    // Refresh to see completion
    await trackingRobot.pullToRefresh();
    await tester.pumpAndSettle();

    // ========================================
    // STEP 7: Confirm completion and rate contractor
    // ========================================
    TestSync.log(deviceRole, 'Step 7: Rating contractor');
    await trackingRobot.completeRatingFlow(
      rating: 5,
      comment: 'Świetna robota! Polecam!',
    );
    TestSync.log(deviceRole, 'Contractor rated');

    // Signal that client has reviewed
    await TestSync.setMarker(SyncMarkers.clientReviewed, 'true');

    // ========================================
    // STEP 8: Wait for contractor to review
    // ========================================
    TestSync.log(deviceRole, 'Step 8: Waiting for contractor review');
    await TestSync.waitForMarkerValue(
      SyncMarkers.contractorReviewed,
      'true',
      timeout: const Duration(seconds: 60),
    );
    TestSync.log(deviceRole, 'Contractor reviewed client');

    // ========================================
    // TEST COMPLETE
    // ========================================
    await TestSync.setMarker('${SyncMarkers.testComplete}_client', 'true');
    TestSync.log(deviceRole, '=== CLIENT TEST COMPLETED SUCCESSFULLY ===');

    // Verify final state
    trackingRobot.verifyTaskCompleted();
  });
}

/// Contractor-side test flow
void _runContractorTest() {
  testWidgets('Contractor: Full task lifecycle', (tester) async {
    final deviceRole = DeviceRole.contractor;
    TestSync.log(deviceRole, '=== CONTRACTOR TEST STARTED ===');

    // Launch app
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    // Initialize robots
    final authRobot = AuthRobot(tester);
    final taskListRobot = TaskListRobot(tester);
    final activeTaskRobot = ActiveTaskRobot(tester);

    // ========================================
    // STEP 1: Login as contractor
    // ========================================
    TestSync.log(deviceRole, 'Step 1: Logging in as contractor');
    await authRobot.loginAsContractor();
    TestSync.log(deviceRole, 'Login successful');

    // ========================================
    // STEP 2: Wait for client to create task
    // ========================================
    TestSync.log(deviceRole, 'Step 2: Waiting for client to create task');
    await TestSync.waitForMarkerValue(
      SyncMarkers.taskCreated,
      'true',
      timeout: const Duration(seconds: 60),
    );
    final taskDescription = await TestSync.getMarker(SyncMarkers.taskId);
    TestSync.log(deviceRole, 'Task created by client: $taskDescription');

    // ========================================
    // STEP 3: Find and accept the task
    // ========================================
    TestSync.log(deviceRole, 'Step 3: Finding and accepting task');
    await taskListRobot.waitForTaskListScreen();
    await taskListRobot.switchToListTab();
    await taskListRobot.waitForTask(taskDescription!);
    await taskListRobot.acceptTaskFromList(taskDescription);
    TestSync.log(deviceRole, 'Task accepted');

    // Signal acceptance to client
    await TestSync.setMarker(SyncMarkers.contractorAccepted, 'true');

    // ========================================
    // STEP 4: Wait for client confirmation
    // ========================================
    TestSync.log(deviceRole, 'Step 4: Waiting for client confirmation');
    await TestSync.waitForMarkerValue(
      SyncMarkers.clientConfirmed,
      'true',
      timeout: const Duration(seconds: 60),
    );
    TestSync.log(deviceRole, 'Client confirmed contractor');

    // Refresh to see confirmation
    await activeTaskRobot.waitForClientConfirmation();

    // ========================================
    // STEP 5: Start working on the task
    // ========================================
    TestSync.log(deviceRole, 'Step 5: Starting task');
    await activeTaskRobot.startTask();
    TestSync.log(deviceRole, 'Task started');

    // Signal that task is in progress
    await TestSync.setMarker(SyncMarkers.taskInProgress, 'true');

    // ========================================
    // STEP 6: Complete the task
    // ========================================
    TestSync.log(deviceRole, 'Step 6: Completing task');
    // Simulate some work time
    await Future.delayed(const Duration(seconds: 2));
    await activeTaskRobot.completeTask();
    TestSync.log(deviceRole, 'Task completed');

    // Signal completion to client
    await TestSync.setMarker(SyncMarkers.taskCompleted, 'true');

    // ========================================
    // STEP 7: Wait for client to review
    // ========================================
    TestSync.log(deviceRole, 'Step 7: Waiting for client review');
    await TestSync.waitForMarkerValue(
      SyncMarkers.clientReviewed,
      'true',
      timeout: const Duration(seconds: 60),
    );
    TestSync.log(deviceRole, 'Client reviewed contractor');

    // ========================================
    // STEP 8: Rate the client
    // ========================================
    TestSync.log(deviceRole, 'Step 8: Rating client');
    await activeTaskRobot.rateClient(
      rating: 5,
      comment: 'Miły klient, polecam!',
    );
    TestSync.log(deviceRole, 'Client rated');

    // Signal that contractor has reviewed
    await TestSync.setMarker(SyncMarkers.contractorReviewed, 'true');

    // ========================================
    // TEST COMPLETE
    // ========================================
    await TestSync.setMarker('${SyncMarkers.testComplete}_contractor', 'true');
    TestSync.log(deviceRole, '=== CONTRACTOR TEST COMPLETED SUCCESSFULLY ===');

    // Verify final state
    activeTaskRobot.verifyTaskCompleted();
  });
}
