import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/routes.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_cluster_marker.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../models/task_category.dart';
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
  Set<TaskCategory> _selectedCategoryFilters = {};

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
    final baseTasks = tasksState.tasks
        .where(_isActiveOrNew)
        .toList();
    final filteredTasks = _getFilteredTasks(baseTasks);

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText('Zlecenia'),
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
          _buildMapTab(tasksState, filteredTasks),
          Column(
            children: [
              _buildListCategoryFilterBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: _buildListTab(tasksState, filteredTasks),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nowe zlecenie'),
      ),
    );
  }

  List<ContractorTask> _getFilteredTasks(List<ContractorTask> tasks) {
    if (_selectedCategoryFilters.isEmpty) {
      return tasks;
    }
    return tasks
        .where((task) => _selectedCategoryFilters.contains(task.category))
        .toList();
  }

  String _getSelectedFiltersLabel() {
    if (_selectedCategoryFilters.isEmpty) {
      return 'Filtry';
    }
    if (_selectedCategoryFilters.length == 1) {
      final category = _selectedCategoryFilters.first;
      return TaskCategoryData.fromCategory(category).name;
    }
    return '${_selectedCategoryFilters.length} wybrane';
  }

  Widget _buildMapFiltersButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCategoryFilterDropdown,
        borderRadius: AppRadius.radiusMD,
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
                Icons.filter_list,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.gapSM),
              Text(
                _getSelectedFiltersLabel(),
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              SizedBox(width: AppSpacing.gapXS),
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.gray600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCategoryFilterBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.gapXS),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
          itemCount: TaskCategoryData.all.length,
          separatorBuilder: (context, index) => SizedBox(width: AppSpacing.gapSM),
          itemBuilder: (context, index) {
            final data = TaskCategoryData.all[index];
            final isSelected = _selectedCategoryFilters.contains(data.category);
            return FilterChip(
              showCheckmark: true,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: Icon(
                data.icon,
                size: 14,
                color: data.color,
              ),
              label: Text(
                data.name,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? data.color : AppColors.gray700,
                ),
              ),
              selected: isSelected,
              selectedColor: data.color.withValues(alpha: 0.12),
              checkmarkColor: data.color,
              side: BorderSide(
                color: isSelected ? data.color : AppColors.gray300,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategoryFilters.add(data.category);
                  } else {
                    _selectedCategoryFilters.remove(data.category);
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCategoryFilterDropdown() async {
    final draft = Set<TaskCategory>.from(_selectedCategoryFilters);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final maxHeight = MediaQuery.of(context).size.height * 0.72;
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Wybierz kategorie',
                            style: AppTypography.h4,
                          ),
                        ),
                        TextButton(
                          onPressed: draft.isEmpty
                              ? null
                              : () {
                                  setModalState(() {
                                    draft.clear();
                                  });
                                },
                          child: const Text('Wyczyść'),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.gapSM),
                    Text(
                      'Możesz zaznaczyć wiele kategorii',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.gapMD),
                    Expanded(
                      child: ListView.builder(
                        itemCount: TaskCategoryData.all.length,
                        itemBuilder: (context, index) {
                          final data = TaskCategoryData.all[index];
                          final isSelected = draft.contains(data.category);
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  draft.remove(data.category);
                                } else {
                                  draft.add(data.category);
                                }
                              });
                            },
                            borderRadius: AppRadius.radiusSM,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.gapXS,
                                horizontal: AppSpacing.paddingXS,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (value) {
                                      setModalState(() {
                                        if (value == true) {
                                          draft.add(data.category);
                                        } else {
                                          draft.remove(data.category);
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(width: AppSpacing.gapSM),
                                  Icon(
                                    data.icon,
                                    color: data.color,
                                    size: 20,
                                  ),
                                  SizedBox(width: AppSpacing.gapSM),
                                  Expanded(
                                    child: Text(
                                      data.name,
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: AppSpacing.gapMD),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Anuluj'),
                          ),
                        ),
                        SizedBox(width: AppSpacing.gapMD),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategoryFilters = draft;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Zatwierdź'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapTab(AvailableTasksState tasksState, List<ContractorTask> tasks) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const fabHeightWithMargin = 72.0; // approx. extended FAB height + default margin
    final overlayBottom = AppSpacing.paddingMD + fabHeightWithMargin + bottomInset;

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

        // Empty state overlay (kept below controls/badges)
        if (tasks.isEmpty)
          Positioned.fill(
            child: Container(
              color: AppColors.white.withValues(alpha: 0.8),
              child: _buildEmptyMapState(),
            ),
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

        // Filters button (floating, below task count badge)
        Positioned(
          top: AppSpacing.paddingMD + 56,
          left: AppSpacing.paddingMD,
          child: _buildMapFiltersButton(),
        ),

        // Zoom controls
        Positioned(
          right: AppSpacing.paddingMD,
          bottom: overlayBottom,
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
          onTap: null,
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

  void _openCreateTask() {
    context.go(Routes.clientCreateTask);
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
    final hasActiveFilter = _selectedCategoryFilters.isNotEmpty;

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
              hasActiveFilter
                  ? 'Brak zleceń dla wybranych kategorii.'
                  : 'Obecnie nie ma żadnych dostępnych zleceń. '
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
    final hasActiveFilter = _selectedCategoryFilters.isNotEmpty;

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
            hasActiveFilter
                ? 'Brak zleceń dla wybranych kategorii.'
                : 'Na mapie pojawią się zlecenia, gdy będą dostępne.',
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
        task.status == ContractorTaskStatus.inProgress ||
        task.status == ContractorTaskStatus.pendingComplete;
  }
}
