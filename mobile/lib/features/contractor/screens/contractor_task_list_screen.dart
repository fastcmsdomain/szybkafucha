import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_cluster_marker.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../models/contractor_task.dart';
import '../widgets/nearby_task_card.dart';

/// Full list of available tasks for contractors with map/list tabs
class ContractorTaskListScreen extends ConsumerStatefulWidget {
  const ContractorTaskListScreen({super.key});

  @override
  ConsumerState<ContractorTaskListScreen> createState() =>
      _ContractorTaskListScreenState();
}

class _ContractorTaskListScreenState
    extends ConsumerState<ContractorTaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  double _currentZoom = 6.0; // Start zoomed out to see all of Poland

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load tasks on screen open
    Future.microtask(() {
      ref.read(availableTasksProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    await ref.read(availableTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(availableTasksProvider);
    final tasks = tasksState.tasks
        .where(_isActiveOrNew)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dostępne zlecenia',
          style: AppTypography.h4,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: 'Odśwież',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.gray500,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.labelLarge,
              tabs: const [
                Tab(text: 'MAPA'),
                Tab(text: 'LISTA'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Map tab
          _buildMapTab(tasksState, tasks),
          // List tab
          RefreshIndicator(
            onRefresh: _refreshTasks,
            child: _buildListTab(tasksState, tasks),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(
    AvailableTasksState tasksState,
    List<ContractorTask> tasks,
  ) {
    // Loading state
    if (tasksState.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    // Error state
    if (tasksState.error != null) {
      return _buildErrorState(tasksState.error!);
    }

    // Convert tasks to clusterable format
    final clusterableTasks = tasks.map((task) => ClusterableTask(
      id: task.id,
      position: LatLng(task.latitude, task.longitude),
      category: task.category.name,
      price: task.price.toDouble(),
    )).toList();

    // Create clusters based on current zoom
    final clusters = TaskClusterManager.clusterTasks(clusterableTasks, _currentZoom);

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: TaskClusterManager.polandCenter,
            initialZoom: _currentZoom,
            minZoom: 5,
            maxZoom: 18,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() => _currentZoom = position.zoom);
              }
            },
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.szybkafucha.mobile',
              maxZoom: 19,
            ),
            // Markers layer
            MarkerLayer(
              markers: clusters.map((cluster) {
                if (cluster.isSingleTask) {
                  // Single task - show regular marker
                  final task = tasks.firstWhere(
                    (t) => t.id == cluster.tasks.first.id,
                    orElse: () => tasks.first,
                  );
                  return Marker(
                    point: cluster.center,
                    width: 44,
                    height: 54,
                    child: GestureDetector(
                      onTap: () => _showTaskDetails(task),
                      child: TaskMarker(position: cluster.center).build(context),
                    ),
                  );
                } else {
                  // Cluster - show cluster marker
                  final clusterMarker = ClusterMarker(
                    position: cluster.center,
                    count: cluster.count,
                    onTap: () => _zoomToCluster(cluster),
                  );
                  return Marker(
                    point: cluster.center,
                    width: clusterMarker.width,
                    height: clusterMarker.height,
                    child: clusterMarker.build(context),
                  );
                }
              }).toList(),
            ),
          ],
        ),

        // Task count badge
        Positioned(
          top: AppSpacing.paddingMD,
          left: AppSpacing.paddingMD,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMD,
              vertical: AppSpacing.paddingSM,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.radiusMD,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  '${tasks.length} zleceń',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Zoom controls
        Positioned(
          right: AppSpacing.paddingMD,
          bottom: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomButton(
                icon: Icons.add,
                onPressed: () => _zoomIn(),
              ),
              SizedBox(height: AppSpacing.gapXS),
              _buildZoomButton(
                icon: Icons.remove,
                onPressed: () => _zoomOut(),
              ),
              SizedBox(height: AppSpacing.gapMD),
              _buildZoomButton(
                icon: Icons.center_focus_strong,
                onPressed: () => _resetView(),
              ),
            ],
          ),
        ),

        // Empty state overlay
        if (tasks.isEmpty)
          Positioned.fill(
            child: Container(
              color: AppColors.white.withValues(alpha: 0.8),
              child: _buildEmptyMapState(),
            ),
          ),
      ],
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      borderRadius: AppRadius.radiusSM,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.radiusSM,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: AppColors.gray700,
          ),
        ),
      ),
    );
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(5.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(5.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _resetView() {
    _mapController.move(TaskClusterManager.polandCenter, 6.0);
    setState(() => _currentZoom = 6.0);
  }

  void _zoomToCluster(TaskCluster cluster) {
    // Zoom in to see individual tasks in cluster
    final newZoom = (_currentZoom + 2).clamp(5.0, 15.0);
    _mapController.move(cluster.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  Widget _buildEmptyMapState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            'Brak dostępnych zleceń',
            style: AppTypography.h5.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Na mapie pojawią się zlecenia,\ngdy będą dostępne.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(
    AvailableTasksState tasksState,
    List<ContractorTask> tasks,
  ) {
    // Loading state
    if (tasksState.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    // Error state
    if (tasksState.error != null) {
      return _buildErrorState(tasksState.error!);
    }

    // Empty state
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // List of tasks
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.gapMD),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return NearbyTaskCard(
          task: task,
          onTap: () => _showTaskDetails(task),
          onDetails: () => _showTaskDetails(task),
          onAccept: () => _acceptTask(task),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Ładowanie zleceń...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Wystąpił błąd',
              style: AppTypography.h5.copyWith(
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.gray400,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Brak dostępnych zleceń',
              style: AppTypography.h5.copyWith(
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Obecnie nie ma żadnych dostępnych zleceń w Twojej okolicy. '
              'Sprawdź ponownie później.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Odśwież'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(ContractorTask task) {
    context.push(
      Routes.contractorTaskAlertRoute(task.id),
      extra: task,
    );
  }

  bool _isActiveOrNew(ContractorTask task) {
    return task.status == ContractorTaskStatus.available ||
        task.status == ContractorTaskStatus.accepted ||
        task.status == ContractorTaskStatus.confirmed ||
        task.status == ContractorTaskStatus.inProgress ||
        task.status == ContractorTaskStatus.pendingComplete;
  }

  Future<void> _acceptTask(ContractorTask task) async {
    try {
      final acceptedTask =
          await ref.read(availableTasksProvider.notifier).acceptTask(task.id);

      // Set as active task in provider
      ref.read(activeTaskProvider.notifier).setTask(acceptedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zaakceptowano zlecenie: ${task.category.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to active task screen
        context.push(Routes.contractorTask(task.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
