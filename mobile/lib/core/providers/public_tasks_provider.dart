import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/contractor/models/contractor_task.dart';
import '../api/api_client.dart';
import 'api_provider.dart';

/// State for public task browsing
class PublicTasksState {
  final List<ContractorTask> tasks;
  final bool isLoading;
  final String? error;

  const PublicTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  PublicTasksState copyWith({
    List<ContractorTask>? tasks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      PublicTasksState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Notifier for public task browsing (no authentication required)
class PublicTasksNotifier extends StateNotifier<PublicTasksState> {
  final ApiClient _api;

  PublicTasksNotifier(this._api) : super(const PublicTasksState());

  /// Load public tasks from /public/tasks endpoint
  Future<void> loadTasks({
    List<String>? categories,
    int limit = 50,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (categories != null && categories.isNotEmpty)
          'categories': categories.join(','),
      };

      final response = await _api.get<List<dynamic>>(
        '/public/tasks',
        queryParameters: queryParams,
      );

      final tasks = response
          .map((json) => ContractorTask.fromPublicJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nie udało się załadować zleceń',
      );
    }
  }

  /// Refresh tasks
  Future<void> refresh() async {
    await loadTasks();
  }
}

/// Provider for public task browsing
final publicTasksProvider =
    StateNotifierProvider<PublicTasksNotifier, PublicTasksState>((ref) {
  final api = ref.watch(apiClientProvider);
  final notifier = PublicTasksNotifier(api);
  // Auto-load on creation
  Future.microtask(() => notifier.loadTasks());
  return notifier;
});
