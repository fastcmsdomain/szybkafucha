/// Task Provider
/// Manages task state for both clients and contractors via Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/client/models/task.dart';
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
  final DateTime? scheduledAt;

  const CreateTaskDto({
    required this.category,
    required this.title,
    this.description,
    required this.locationLat,
    required this.locationLng,
    required this.address,
    required this.budgetAmount,
    this.scheduledAt,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'title': title,
        if (description != null) 'description': description,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'address': address,
        'budgetAmount': budgetAmount,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
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
      final response = await _api.get<List<dynamic>>('/tasks');
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

  /// Confirm task completion
  Future<void> confirmTask(String taskId) async {
    try {
      await _api.put<Map<String, dynamic>>('/tasks/$taskId/confirm');

      // Refresh tasks to get updated state
      await loadTasks();
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
  final api = ref.watch(apiClientProvider);
  final notifier = ClientTasksNotifier(api, ref);

  // Auto-load tasks when provider is created and user is authenticated
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user?.isClient == true) {
    // Schedule loading after provider initialization
    Future.microtask(() => notifier.loadTasks());
  }

  return notifier;
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
      : super(const AvailableTasksState());

  /// Load available tasks for contractors
  /// Note: Location filtering disabled for MVP - shows all available tasks
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // For MVP, we don't filter by location
      // Just get all tasks with status 'created'
      final response = await _api.get<List<dynamic>>('/tasks');

      final tasks = response.map((json) {
        final data = json as Map<String, dynamic>;
        return _mapToContractorTask(data);
      }).toList();

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Accept a task
  Future<ContractorTask> acceptTask(String taskId) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/tasks/$taskId/accept',
      );

      final task = _mapToContractorTask(response);

      // Remove from available tasks
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );

      return task;
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
  final api = ref.watch(apiClientProvider);
  final notifier = AvailableTasksNotifier(api, ref);

  // Auto-load tasks when provider is created and user is a contractor
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user?.isContractor == true) {
    Future.microtask(() => notifier.loadTasks());
  }

  return notifier;
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
    // Only handle if this is our active task
    if (state.task == null || state.task!.id != event.taskId) return;

    final status = event.status.toLowerCase();

    // If task was cancelled by client, clear it from contractor's active tasks
    if (status == 'cancelled') {
      clearTask();
    }
    // If task was returned to posted (shouldn't happen to active task, but handle it)
    else if (status == 'posted' || status == 'created') {
      clearTask();
    }
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
  final api = ref.watch(apiClientProvider);
  return ActiveTaskNotifier(api, ref);
});

// Extension for ContractorTask to add copyWith
extension ContractorTaskCopyWith on ContractorTask {
  ContractorTask copyWith({
    String? id,
    TaskCategory? category,
    String? description,
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
    bool? isUrgent,
  }) {
    return ContractorTask(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
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
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}
