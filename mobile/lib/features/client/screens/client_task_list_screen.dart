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
import '../../contractor/models/contractor_task.dart';
import '../../contractor/widgets/nearby_task_card.dart';

/// Client-facing view of all available jobs with map/list tabs
/// Mirrors the contractor list but without accept actions
class ClientTaskListScreen extends ConsumerStatefulWidget {
  const ClientTaskListScreen({super.key});

  @override
  ConsumerState<ClientTaskListScreen> createState() => _ClientTaskListScreenState();
}

class _ClientTaskListScreenState extends ConsumerState<ClientTaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  double _currentZoom = 6.0; // Start zoomed out to show the whole country

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load available tasks when screen opens
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
          'Zlecenia',
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
          _buildMapTab(tasksState, tasks),
          RefreshIndicator(
            onRefresh: _refreshTasks,
            child: _buildListTab(tasksState, tasks),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.clientCreateTask),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nowe zlecenie'),
      ),
    );
  }

  Widget _buildMapTab(AvailableTasksState tasksState, List<ContractorTask> tasks) {
    // Loading state
    if (tasksState.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    // Error state
    if (tasksState.error != null) {
      return _buildErrorState(tasksState.error!);
    }

    // Convert tasks to clusterable format
    final clusterableTasks = tasks
        .map((task) => ClusterableTask(
              id: task.id,
              position: LatLng(task.latitude, task.longitude),
              category: task.category.name,
              price: task.price.toDouble(),
            ))
        .toList();

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
                onPressed: _zoomIn,
              ),
              SizedBox(height: AppSpacing.gapXS),
              _buildZoomButton(
                icon: Icons.remove,
                onPressed: _zoomOut,
              ),
              SizedBox(height: AppSpacing.gapMD),
              _buildZoomButton(
                icon: Icons.center_focus_strong,
                onPressed: _resetView,
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

  Widget _buildListTab(AvailableTasksState tasksState, List<ContractorTask> tasks) {
    if (tasksState.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    if (tasksState.error != null) {
      return _buildErrorState(tasksState.error!);
    }

    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.gapMD),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return NearbyTaskCard(
          task: task,
          showActions: false,
          onTap: () => _showTaskDetails(task),
        );
      },
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
        child: SizedBox(
          width: 40,
          height: 40,
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
    final newZoom = (_currentZoom + 2).clamp(5.0, 15.0);
    _mapController.move(cluster.center, newZoom);
    setState(() => _currentZoom = newZoom);
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
              'Obecnie nie ma żadnych dostępnych zleceń. '
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
            'Na mapie pojawią się zlecenia, gdy będą dostępne.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(ContractorTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: NearbyTaskCard(
                task: task,
                showActions: false,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isActiveOrNew(ContractorTask task) {
    return task.status == ContractorTaskStatus.available ||
        task.status == ContractorTaskStatus.accepted ||
        task.status == ContractorTaskStatus.confirmed ||
        task.status == ContractorTaskStatus.inProgress;
  }
}
