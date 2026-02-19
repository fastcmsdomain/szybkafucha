/// Task Provider
/// Manages task state for both clients and contractors via Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/client/models/task.dart';
import '../../features/client/models/task_application.dart';
import '../../features/client/models/task_category.dart';
import '../../features/client/models/contractor.dart';
import '../../features/contractor/models/contractor_task.dart';
import '../api/api_client.dart';
import '../services/websocket_service.dart';
import 'api_provider.dart';
import 'auth_provider.dart';
import 'websocket_provider.dart';

/// DTO for creating a new task
class CreateTaskDto {
  final TaskCategory category;
  final String title;
  final String? description;
  final double locationLat;
  final double locationLng;
  final String address;
  final double budgetAmount;
  final double? estimatedDurationHours;
  final DateTime? scheduledAt;
  final List<String>? imageUrls;

  const CreateTaskDto({
    required this.category,
    required this.title,
    this.description,
    required this.locationLat,
    required this.locationLng,
    required this.address,
    required this.budgetAmount,
    this.estimatedDurationHours,
    this.scheduledAt,
    this.imageUrls,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'title': title,
        if (description != null) 'description': description,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'address': address,
        'budgetAmount': budgetAmount,
        if (estimatedDurationHours != null) 'estimatedDurationHours': estimatedDurationHours,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
        if (imageUrls != null && imageUrls!.isNotEmpty) 'imageUrls': imageUrls,
      };
}

/// State for client tasks
class ClientTasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const ClientTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  ClientTasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return ClientTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Task> get activeTasks =>
      tasks.where((t) => t.status.isActive).toList();

  List<Task> get completedTasks =>
      tasks.where((t) => !t.status.isActive).toList();
}

/// Notifier for client tasks
class ClientTasksNotifier extends StateNotifier<ClientTasksState> {
  final ApiClient _api;
  final Ref _ref;

  ClientTasksNotifier(this._api, this._ref) : super(const ClientTasksState()) {
    _setupWebSocketListener();
    _setupAuthListener();
  }

  /// Load tasks when auth state becomes authenticated
  void _setupAuthListener() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated &&
          next.user?.isClient == true &&
          previous?.isAuthenticated != true) {
        loadTasks();
      }
    });
    // Load immediately if already authenticated
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user?.isClient == true) {
      Future.microtask(() => loadTasks());
    }
  }

  /// Set up WebSocket listener for real-time task status updates
  void _setupWebSocketListener() {
    _ref.listen<AsyncValue<TaskStatusEvent>>(
      taskStatusUpdatesProvider,
      (previous, next) {
        next.whenData((event) => _handleTaskStatusUpdate(event));
      },
    );
  }

  /// Handle incoming task status update from WebSocket
  void _handleTaskStatusUpdate(TaskStatusEvent event) {
    final taskIndex = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (taskIndex == -1) return; // Task not in our list

    final currentTask = state.tasks[taskIndex];

    // Map status string to TaskStatus enum
    final newStatus = _mapStatus(event.status);

    // Check if contractor released the task (status back to posted)
    final contractorReleased = newStatus == TaskStatus.posted;

    // Handle contractor assignment based on new status
    Contractor? contractor = currentTask.contractor;
    String? contractorId = currentTask.contractorId;

    if (!contractorReleased && event.contractor != null) {
      // Create contractor from event if provided
      contractor = Contractor(
        id: event.contractor!.id,
        name: event.contractor!.name,
        avatarUrl: event.contractor!.avatarUrl,
        rating: event.contractor!.rating,
        completedTasks: event.contractor!.completedTasks,
        isVerified: true,
        isOnline: true,
      );
      contractorId = event.contractor!.id;
    }

    // Update the task
    final updatedTask = currentTask.copyWith(
      status: newStatus,
      contractor: contractorReleased ? null : contractor,
      contractorId: contractorReleased ? null : contractorId,
      clearContractor: contractorReleased,
    );

    // Update state
    final updatedTasks = List<Task>.from(state.tasks);
    updatedTasks[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedTasks);
  }

  /// Map backend status string to TaskStatus enum
  TaskStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
      case 'created':
        return TaskStatus.posted;
      case 'accepted':
        return TaskStatus.accepted;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'pending_complete':
      case 'pendingcomplete':
        return TaskStatus.pendingComplete;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.posted;
    }
  }

  /// Load all tasks for the current client
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.get<List<dynamic>>(
        '/tasks',
        queryParameters: {'role': 'client'},
      );
      final tasks = response
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new task
  Future<Task> createTask(CreateTaskDto dto) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/tasks',
        data: dto.toJson(),
      );

      final task = Task.fromJson(response);

      // Add to local state
      state = state.copyWith(
        tasks: [task, ...state.tasks],
        isLoading: false,
      );

      return task;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Cancel a task
  Future<void> cancelTask(String taskId, {String? reason}) async {
    try {
      await _api.put<Map<String, dynamic>>(
        '/tasks/$taskId/cancel',
        data: reason != null ? {'reason': reason} : null,
      );

      // Update local state
      state = state.copyWith(
        tasks: state.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(status: TaskStatus.cancelled);
          }
          return t;
        }).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Client confirms task completion (awaiting contractor's closure)
  Future<void> confirmTask(String taskId) async {
    try {
      try {
        await _api.put<Map<String, dynamic>>(
          '/tasks/$taskId/confirm-completion',
        );
      } catch (_) {
        // Fallback for backends that still use /confirm
        await _api.put<Map<String, dynamic>>('/tasks/$taskId/confirm');
      }

      // Update local state to pending_complete without full reload
      state = state.copyWith(
        tasks: state.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(status: TaskStatus.pendingComplete);
          }
          return t;
        }).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Rate a completed task
  Future<void> rateTask(
    String taskId, {
    required int rating,
    String? comment,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/tasks/$taskId/rate',
        data: {
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Add tip to a completed task
  Future<void> addTip(String taskId, double amount) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/tasks/$taskId/tip',
        data: {'amount': amount},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh tasks
  Future<void> refresh() async {
    await loadTasks();
  }
}

/// Provider for client tasks
final clientTasksProvider =
    StateNotifierProvider<ClientTasksNotifier, ClientTasksState>((ref) {
  return ClientTasksNotifier(ref.read(apiClientProvider), ref);
});

/// State for available tasks (contractor view)
class AvailableTasksState {
  final List<ContractorTask> tasks;
  final bool isLoading;
  final String? error;

  const AvailableTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  AvailableTasksState copyWith({
    List<ContractorTask>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return AvailableTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for available tasks (contractor)
class AvailableTasksNotifier extends StateNotifier<AvailableTasksState> {
  final ApiClient _api;
  final Ref _ref;

  AvailableTasksNotifier(this._api, this._ref)
      : super(const AvailableTasksState()) {
    _setupWebSocketListener();
    _setupAuthListener();
  }

  /// Load tasks when auth state becomes authenticated
  void _setupAuthListener() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated &&
          next.user?.isContractor == true &&
          previous?.isAuthenticated != true) {
        loadTasks();
      }
    });
    // Load immediately if already authenticated
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user?.isContractor == true) {
      Future.microtask(() => loadTasks());
    }
  }

  /// Set up WebSocket listener for task status updates (e.g., client cancels)
  void _setupWebSocketListener() {
    _ref.listen<AsyncValue<TaskStatusEvent>>(
      taskStatusUpdatesProvider,
      (previous, next) {
        next.whenData((event) => _handleTaskStatusUpdate(event));
      },
    );
  }

  /// Handle incoming task status update from WebSocket
  void _handleTaskStatusUpdate(TaskStatusEvent event) {
    final status = event.status.toLowerCase();

    // If task was cancelled by client, remove it from available tasks
    if (status == 'cancelled') {
      _removeTask(event.taskId);
    }
    // Also remove if task was accepted/confirmed/in progress by another contractor
    else if (status == 'accepted' || status == 'confirmed' || status == 'in_progress') {
      _removeTask(event.taskId);
    }
  }

  /// Remove a task from available tasks list
  void _removeTask(String taskId) {
    final taskExists = state.tasks.any((t) => t.id == taskId);
    if (taskExists) {
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
    }
  }

  /// Load available tasks for contractors
  /// Note: Location filtering disabled for MVP - shows all available tasks
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // For MVP, we don't filter by location
      // Just get all tasks with status 'created'
      final response = await _api.get<List<dynamic>>(
        '/tasks',
        queryParameters: {'role': 'contractor'},
      );

      final tasks = response
          .map((json) => _mapToContractorTask(json as Map<String, dynamic>))
          // Keep only tasks that are still available to contractors
          .where((task) => task.status == ContractorTaskStatus.available)
          .toList();

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Apply for a task with proposed price and optional message (bidding system)
  Future<void> applyForTask(
    String taskId, {
    required double proposedPrice,
    String? message,
  }) async {
    try {
      // Check if contractor profile is complete
      final profileCheckResponse = await _api.get<Map<String, dynamic>>(
        '/contractor/profile/complete',
      );

      final isComplete = profileCheckResponse['complete'] as bool? ?? false;

      if (!isComplete) {
        throw Exception(
          'Dokończ swój profil wykonawcy, aby zgłosić się do zlecenia',
        );
      }

      // Submit application
      await _api.post<Map<String, dynamic>>(
        '/tasks/$taskId/apply',
        data: {
          'proposedPrice': proposedPrice,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );

      // Mark task as applied (don't remove - contractor can still see it)
      // The task stays in the list but UI can show "applied" badge
    } catch (e) {
      rethrow;
    }
  }

  /// Withdraw application for a task
  Future<void> withdrawApplication(String taskId) async {
    try {
      await _api.delete<Map<String, dynamic>>(
        '/tasks/$taskId/apply',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Map backend response to ContractorTask
  /// Uses ContractorTask.fromJson which handles String/num type coercion
  ContractorTask _mapToContractorTask(Map<String, dynamic> json) {
    return ContractorTask.fromJson(json);
  }

  /// Refresh tasks
  Future<void> refresh() async {
    await loadTasks();
  }
}

/// Provider for available tasks (contractor)
final availableTasksProvider =
    StateNotifierProvider<AvailableTasksNotifier, AvailableTasksState>((ref) {
  return AvailableTasksNotifier(ref.read(apiClientProvider), ref);
});

/// State for contractor's active task
class ActiveTaskState {
  final ContractorTask? task;
  final bool isLoading;
  final String? error;

  const ActiveTaskState({
    this.task,
    this.isLoading = false,
    this.error,
  });

  ActiveTaskState copyWith({
    ContractorTask? task,
    bool? isLoading,
    String? error,
    bool clearTask = false,
  }) {
    return ActiveTaskState(
      task: clearTask ? null : (task ?? this.task),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for contractor's active task
class ActiveTaskNotifier extends StateNotifier<ActiveTaskState> {
  final ApiClient _api;
  final Ref _ref;

  ActiveTaskNotifier(this._api, this._ref) : super(const ActiveTaskState()) {
    _setupWebSocketListener();
    Future.microtask(() => _loadInitialActiveTask());
  }

  /// Set up WebSocket listener for task status updates (e.g., client cancels)
  void _setupWebSocketListener() {
    _ref.listen<AsyncValue<TaskStatusEvent>>(
      taskStatusUpdatesProvider,
      (previous, next) {
        next.whenData((event) => _handleTaskStatusUpdate(event));
      },
    );

    _ref.listen<AsyncValue<Map<String, dynamic>>>(
      applicationResultProvider,
      (previous, next) {
        next.whenData((event) => _handleApplicationResult(event));
      },
    );
  }

  /// Handle contractor application result events (accepted/rejected)
  void _handleApplicationResult(Map<String, dynamic> event) {
    final status = event['status']?.toString().toLowerCase();
    final taskId = event['taskId']?.toString();

    if (taskId == null || taskId.isEmpty) return;

    // When client accepts contractor's application, load full task as active
    if (status == 'accepted') {
      Future.microtask(() => fetchTask(taskId));
    }
  }

  /// Handle incoming task status update from WebSocket
  void _handleTaskStatusUpdate(TaskStatusEvent event) {
    // Only handle if this is our active task
    if (state.task == null || state.task!.id != event.taskId) return;

    final status = event.status.toLowerCase();

    // Clear active task when:
    // - Task was cancelled by client
    // - Contractor was released/rejected by client (looking for another)
    // - Task was returned to posted/created status (available again)
    // - Any status that means contractor is no longer assigned
    final shouldClearTask = status == 'cancelled' ||
        status == 'posted' ||
        status == 'created' ||
        status == 'released' ||
        status == 'rejected' ||
        status == 'available';

    if (shouldClearTask) {
      clearTask();
      return;
    }

    // Otherwise update local status to keep UI in sync
    final newStatus = _mapContractorStatus(status);
    state = state.copyWith(
      task: state.task?.copyWith(status: newStatus),
    );
  }

  /// Set the active task (after accepting)
  void setTask(ContractorTask task) {
    state = state.copyWith(task: task);
  }

  /// Fetch task by ID from backend
  Future<void> fetchTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/tasks/$taskId',
      );
      final task = ContractorTask.fromJson(response);
      state = state.copyWith(task: task, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Restore active task after app restart by checking accepted applications
  Future<void> _loadInitialActiveTask() async {
    try {
      final response = await _api.get<List<dynamic>>('/tasks/contractor/applications');

      final acceptedApps = response
          .whereType<Map<String, dynamic>>()
          .where((app) =>
              app['status']?.toString().toLowerCase() == 'accepted')
          .toList()
        ..sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

      for (final app in acceptedApps) {
        final taskId = app['taskId']?.toString();
        if (taskId == null || taskId.isEmpty) continue;

        try {
          final taskResponse = await _api.get<Map<String, dynamic>>('/tasks/$taskId');
          final task = ContractorTask.fromJson(taskResponse);

          if (task.status.isActive) {
            state = state.copyWith(task: task, isLoading: false, error: null);
            return;
          }
        } catch (_) {
          // Ignore single-task fetch failures and continue
        }
      }
    } catch (_) {
      // Ignore restore failures; active task can still arrive via WebSocket
    }
  }

  /// Refresh active task state manually
  Future<void> refreshActiveTask() async {
    if (state.task != null) {
      await fetchTask(state.task!.id);
      return;
    }
    await _loadInitialActiveTask();
  }

  /// Update task status
  Future<void> updateStatus(String taskId, String action) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _api.put<Map<String, dynamic>>(
        '/tasks/$taskId/$action',
      );

      // Update local task status
      if (state.task != null) {
        final newStatus = _getStatusFromAction(action);
        state = state.copyWith(
          task: ContractorTask(
            id: state.task!.id,
            category: state.task!.category,
            description: state.task!.description,
            clientId: state.task!.clientId,
            clientName: state.task!.clientName,
            clientAvatarUrl: state.task!.clientAvatarUrl,
            clientRating: state.task!.clientRating,
            address: state.task!.address,
            latitude: state.task!.latitude,
            longitude: state.task!.longitude,
            distanceKm: state.task!.distanceKm,
            estimatedMinutes: state.task!.estimatedMinutes,
            price: state.task!.price,
            status: newStatus,
            createdAt: state.task!.createdAt,
            acceptedAt: state.task!.acceptedAt,
            startedAt: action == 'start' ? DateTime.now() : state.task!.startedAt,
            completedAt:
                action == 'complete' ? DateTime.now() : state.task!.completedAt,
            isUrgent: state.task!.isUrgent,
          ),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  ContractorTaskStatus _getStatusFromAction(String action) {
    switch (action) {
      case 'start':
        return ContractorTaskStatus.inProgress;
      case 'complete':
        return ContractorTaskStatus.completed;
      case 'cancel':
        return ContractorTaskStatus.cancelled;
      default:
        return state.task?.status ?? ContractorTaskStatus.accepted;
    }
  }

  ContractorTaskStatus _mapContractorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return ContractorTaskStatus.accepted;
      case 'confirmed':
        return ContractorTaskStatus.confirmed;
      case 'in_progress':
        return ContractorTaskStatus.inProgress;
      case 'pending_complete':
      case 'pendingcomplete':
        return ContractorTaskStatus.pendingComplete;
      case 'completed':
        return ContractorTaskStatus.completed;
      case 'cancelled':
        return ContractorTaskStatus.cancelled;
      default:
        return state.task?.status ?? ContractorTaskStatus.accepted;
    }
  }

  /// Complete task with photos
  Future<void> completeTask(String taskId, {List<String>? photos}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _api.put<Map<String, dynamic>>(
        '/tasks/$taskId/complete',
        data: photos != null ? {'completionPhotos': photos} : null,
      );

      state = state.copyWith(
        task: state.task?.copyWith(status: ContractorTaskStatus.completed),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Clear active task
  void clearTask() {
    state = state.copyWith(clearTask: true);
  }
}

/// Provider for contractor's active task
final activeTaskProvider =
    StateNotifierProvider<ActiveTaskNotifier, ActiveTaskState>((ref) {
  final api = ref.read(apiClientProvider);
  return ActiveTaskNotifier(api, ref);
});

/// State for all contractor's active tasks (for home screen listing)
class ContractorActiveTasksState {
  final List<ContractorTask> tasks;
  final bool isLoading;
  final String? error;

  const ContractorActiveTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  ContractorActiveTasksState copyWith({
    List<ContractorTask>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return ContractorActiveTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for all contractor's active tasks
class ContractorActiveTasksNotifier
    extends StateNotifier<ContractorActiveTasksState> {
  final ApiClient _api;
  final Ref _ref;

  ContractorActiveTasksNotifier(this._api, this._ref)
      : super(const ContractorActiveTasksState()) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated &&
          next.user?.isContractor == true &&
          previous?.isAuthenticated != true) {
        loadTasks();
      }
    });
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user?.isContractor == true) {
      Future.microtask(() => loadTasks());
    }
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response =
          await _api.get<List<dynamic>>('/tasks/contractor/applications');

      final acceptedApps = response
          .whereType<Map<String, dynamic>>()
          .where(
              (app) => app['status']?.toString().toLowerCase() == 'accepted')
          .toList();

      final tasks = <ContractorTask>[];
      for (final app in acceptedApps) {
        final taskId = app['taskId']?.toString();
        if (taskId == null || taskId.isEmpty) continue;
        try {
          final taskResponse =
              await _api.get<Map<String, dynamic>>('/tasks/$taskId');
          final task = ContractorTask.fromJson(taskResponse);
          if (task.status.isActive) {
            tasks.add(task);
          }
        } catch (_) {}
      }

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadTasks();
}

/// Provider listing all contractor's active tasks (for home screen)
final contractorActiveTasksProvider = StateNotifierProvider<
    ContractorActiveTasksNotifier, ContractorActiveTasksState>(
  (ref) => ContractorActiveTasksNotifier(ref.read(apiClientProvider), ref),
);

// Extension for ContractorTask to add copyWith
extension ContractorTaskCopyWith on ContractorTask {
  ContractorTask copyWith({
    String? id,
    TaskCategory? category,
    String? description,
    String? clientId,
    String? clientName,
    String? clientAvatarUrl,
    double? clientRating,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? estimatedMinutes,
    int? price,
    ContractorTaskStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? scheduledAt,
    List<String>? imageUrls,
    bool? isUrgent,
  }) {
    return ContractorTask(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAvatarUrl: clientAvatarUrl ?? this.clientAvatarUrl,
      clientRating: clientRating ?? this.clientRating,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      imageUrls: imageUrls ?? this.imageUrls,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

// ─── Task Applications Providers (Bidding System) ─────────────────────

/// State for task applications (client view)
class TaskApplicationsState {
  final List<TaskApplication> applications;
  final bool isLoading;
  final String? error;

  const TaskApplicationsState({
    this.applications = const [],
    this.isLoading = false,
    this.error,
  });

  TaskApplicationsState copyWith({
    List<TaskApplication>? applications,
    bool? isLoading,
    String? error,
  }) {
    return TaskApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<TaskApplication> get pendingApplications =>
      applications.where((a) => a.status.isPending).toList();
}

/// Notifier for task applications (client view - per task)
class TaskApplicationsNotifier extends StateNotifier<TaskApplicationsState> {
  final ApiClient _api;
  final String _taskId;

  TaskApplicationsNotifier(this._api, this._taskId)
      : super(const TaskApplicationsState());

  /// Load applications for the task
  Future<void> loadApplications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.get<List<dynamic>>(
        '/tasks/$_taskId/applications',
      );
      final applications = response
          .map((json) =>
              TaskApplication.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(applications: applications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Accept an application
  Future<void> acceptApplication(String applicationId) async {
    try {
      await _api.put<Map<String, dynamic>>(
        '/tasks/$_taskId/applications/$applicationId/accept',
      );
      // Reload to get updated statuses
      await loadApplications();
    } catch (e) {
      rethrow;
    }
  }

  /// Reject an application
  Future<void> rejectApplication(String applicationId) async {
    try {
      await _api.put<Map<String, dynamic>>(
        '/tasks/$_taskId/applications/$applicationId/reject',
      );
      // Reload to get updated statuses
      await loadApplications();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for task applications (client view - per task)
final taskApplicationsProvider = StateNotifierProvider.family<
    TaskApplicationsNotifier, TaskApplicationsState, String>(
  (ref, taskId) {
    final api = ref.read(apiClientProvider);
    final notifier = TaskApplicationsNotifier(api, taskId);
    Future.microtask(() => notifier.loadApplications());
    return notifier;
  },
);

/// State for contractor's own applications
class MyApplicationsState {
  final List<MyApplication> applications;
  final bool isLoading;
  final String? error;

  const MyApplicationsState({
    this.applications = const [],
    this.isLoading = false,
    this.error,
  });

  MyApplicationsState copyWith({
    List<MyApplication>? applications,
    bool? isLoading,
    String? error,
  }) {
    return MyApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<MyApplication> get pendingApplications =>
      applications.where((a) => a.status.isPending).toList();

  int get pendingCount => pendingApplications.length;
}

/// Notifier for contractor's own applications
class MyApplicationsNotifier extends StateNotifier<MyApplicationsState> {
  final ApiClient _api;
  final Ref _ref;

  MyApplicationsNotifier(this._api, this._ref)
      : super(const MyApplicationsState()) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated &&
          next.user?.isContractor == true &&
          previous?.isAuthenticated != true) {
        loadApplications();
      }
    });
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user?.isContractor == true) {
      Future.microtask(() => loadApplications());
    }
  }

  /// Load contractor's applications
  Future<void> loadApplications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.get<List<dynamic>>(
        '/tasks/contractor/applications',
      );
      final applications = response
          .map((json) =>
              MyApplication.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(applications: applications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Withdraw an application
  Future<void> withdrawApplication(String taskId) async {
    try {
      await _api.delete<Map<String, dynamic>>(
        '/tasks/$taskId/apply',
      );
      await loadApplications();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for contractor's own applications
final myApplicationsProvider =
    StateNotifierProvider<MyApplicationsNotifier, MyApplicationsState>((ref) {
  return MyApplicationsNotifier(ref.read(apiClientProvider), ref);
});
