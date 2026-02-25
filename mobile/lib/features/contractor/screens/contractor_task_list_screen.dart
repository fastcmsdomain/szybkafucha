import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/kyc_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_cluster_marker.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../client/models/task_category.dart';
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
  Set<TaskCategory> _selectedCategoryFilters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load tasks and KYC status on screen open
    Future.microtask(() {
      ref.read(availableTasksProvider.notifier).loadTasks();
      ref.read(kycProvider.notifier).fetchStatus();
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
    final baseTasks = tasksState.tasks.where(_isActiveOrNew).toList();
    final availableCategories = _getAvailableCategories(baseTasks);
    final effectiveSelectedFilters = _getEffectiveSelectedFilters(
      availableCategories,
    );
    final filteredTasks = _getFilteredTasks(
      baseTasks,
      effectiveSelectedFilters,
    );

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText(context.l10n.availableTasks),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: context.l10n.retry,
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
              tabs: [
                Tab(text: context.l10n.taskListMapTab),
                Tab(text: context.l10n.taskListListTab),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Map tab
          _buildMapTab(
            tasksState,
            filteredTasks,
            availableCategories: availableCategories,
            effectiveSelectedFilters: effectiveSelectedFilters,
          ),
          // List tab
          Column(
            children: [
              _buildListCategoryFilterBar(
                availableCategories: availableCategories,
                effectiveSelectedFilters: effectiveSelectedFilters,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: _buildListTab(
                    tasksState,
                    filteredTasks,
                    hasActiveFilter: effectiveSelectedFilters.isNotEmpty,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Set<TaskCategory> _getAvailableCategories(List<ContractorTask> tasks) {
    return tasks.map((task) => task.category).toSet();
  }

  Set<TaskCategory> _getEffectiveSelectedFilters(
    Set<TaskCategory> availableCategories,
  ) {
    return _selectedCategoryFilters.where(availableCategories.contains).toSet();
  }

  List<ContractorTask> _getFilteredTasks(
    List<ContractorTask> tasks,
    Set<TaskCategory> effectiveSelectedFilters,
  ) {
    if (effectiveSelectedFilters.isEmpty) {
      return tasks;
    }
    return tasks
        .where((task) => effectiveSelectedFilters.contains(task.category))
        .toList();
  }

  String _getSelectedFiltersLabel(Set<TaskCategory> effectiveSelectedFilters) {
    if (effectiveSelectedFilters.isEmpty) {
      return context.l10n.taskListFilters;
    }
    if (effectiveSelectedFilters.length == 1) {
      final category = effectiveSelectedFilters.first;
      return TaskCategoryData.fromCategory(category).name;
    }
    return context.l10n.taskListSelectedFiltersCount(
      effectiveSelectedFilters.length,
    );
  }

  Widget _buildMapFiltersButton({
    required Set<TaskCategory> availableCategories,
    required Set<TaskCategory> effectiveSelectedFilters,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategoryFilterDropdown(
          availableCategories: availableCategories,
        ),
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
              Icon(Icons.filter_list, size: 18, color: AppColors.primary),
              SizedBox(width: AppSpacing.gapSM),
              Text(
                _getSelectedFiltersLabel(effectiveSelectedFilters),
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              SizedBox(width: AppSpacing.gapXS),
              Icon(Icons.arrow_drop_down, color: AppColors.gray600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCategoryFilterBar({
    required Set<TaskCategory> availableCategories,
    required Set<TaskCategory> effectiveSelectedFilters,
  }) {
    final availableCategoryData = TaskCategoryData.all
        .where((data) => availableCategories.contains(data.category))
        .toList();

    if (availableCategoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.gapXS),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
          itemCount: availableCategoryData.length,
          separatorBuilder: (context, index) =>
              SizedBox(width: AppSpacing.gapSM),
          itemBuilder: (context, index) {
            final data = availableCategoryData[index];
            final isSelected = effectiveSelectedFilters.contains(data.category);
            return FilterChip(
              showCheckmark: true,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: Icon(data.icon, size: 14, color: data.color),
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

  Future<void> _openCategoryFilterDropdown({
    required Set<TaskCategory> availableCategories,
  }) async {
    final availableCategoryData = TaskCategoryData.all
        .where((data) => availableCategories.contains(data.category))
        .toList();
    final draft = Set<TaskCategory>.from(_selectedCategoryFilters);
    draft.removeWhere((category) => !availableCategories.contains(category));

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
                            context.l10n.selectCategory,
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
                          child: Text(context.l10n.taskListClearFilters),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.gapSM),
                    Text(
                      context.l10n.taskListMultiSelectHint,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.gapMD),
                    Expanded(
                      child: availableCategoryData.isEmpty
                          ? Center(
                              child: Text(
                                context.l10n.taskListNoCategoriesToFilter,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: availableCategoryData.length,
                              itemBuilder: (context, index) {
                                final data = availableCategoryData[index];
                                final isSelected = draft.contains(
                                  data.category,
                                );
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
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
                            child: Text(context.l10n.cancel),
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
                            child: Text(context.l10n.confirm),
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

  Widget _buildMapTab(
    AvailableTasksState tasksState,
    List<ContractorTask> tasks, {
    required Set<TaskCategory> availableCategories,
    required Set<TaskCategory> effectiveSelectedFilters,
  }) {
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
        .map(
          (task) => ClusterableTask(
            id: task.id,
            position: LatLng(task.latitude, task.longitude),
            category: task.category.name,
            price: task.price.toDouble(),
          ),
        )
        .toList();

    // Create clusters based on current zoom
    final clusters = TaskClusterManager.clusterTasks(
      clusterableTasks,
      _currentZoom,
    );

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
            // OpenStreetMap tile layer (caching disabled - see sf_map_view.dart)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.szybkafucha.mobile',
              maxZoom: 19,
              tileProvider: NetworkTileProvider(
                cachingProvider: const DisabledMapCachingProvider(),
              ),
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
                      child: TaskMarker(
                        position: cluster.center,
                      ).build(context),
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

        // Empty state overlay (kept below controls/badges)
        if (tasks.isEmpty)
          Positioned.fill(
            child: Container(
              color: AppColors.white.withValues(alpha: 0.8),
              child: _buildEmptyMapState(
                hasActiveFilter: effectiveSelectedFilters.isNotEmpty,
              ),
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
                Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  context.l10n.taskListTasksCount(tasks.length),
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filters button (floating, similar to task count badge)
        Positioned(
          top: AppSpacing.paddingMD + 56,
          left: AppSpacing.paddingMD,
          child: _buildMapFiltersButton(
            availableCategories: availableCategories,
            effectiveSelectedFilters: effectiveSelectedFilters,
          ),
        ),

        // Zoom controls
        Positioned(
          right: AppSpacing.paddingMD,
          bottom: AppSpacing.paddingMD,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomButton(icon: Icons.add, onPressed: () => _zoomIn()),
              SizedBox(height: AppSpacing.gapXS),
              _buildZoomButton(icon: Icons.remove, onPressed: () => _zoomOut()),
              SizedBox(height: AppSpacing.gapMD),
              _buildZoomButton(
                icon: Icons.center_focus_strong,
                onPressed: () => _resetView(),
              ),
            ],
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
          child: Icon(icon, size: 22, color: AppColors.gray700),
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

  Widget _buildEmptyMapState({required bool hasActiveFilter}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: AppColors.gray400),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            context.l10n.noAvailableTasks,
            style: AppTypography.h5.copyWith(color: AppColors.gray600),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            hasActiveFilter
                ? context.l10n.taskListNoTasksForSelectedCategories
                : context.l10n.taskListMapEmptyHint,
            style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(
    AvailableTasksState tasksState,
    List<ContractorTask> tasks, {
    required bool hasActiveFilter,
  }) {
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
      return _buildEmptyState(hasActiveFilter: hasActiveFilter);
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
          onAccept: () => _showApplyDialog(task),
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
              context.l10n.taskListLoadingTasks,
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
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              context.l10n.error,
              style: AppTypography.h5.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              error,
              style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
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

  Widget _buildEmptyState({required bool hasActiveFilter}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.gray400),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              context.l10n.noAvailableTasks,
              style: AppTypography.h5.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              hasActiveFilter
                  ? context.l10n.taskListNoTasksForSelectedCategories
                  : context.l10n.noAvailableTasks,
              style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
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
    context.push(Routes.contractorTaskAlertRoute(task.id), extra: task);
  }

  bool _isActiveOrNew(ContractorTask task) {
    return task.status == ContractorTaskStatus.available ||
        task.status == ContractorTaskStatus.accepted ||
        task.status == ContractorTaskStatus.confirmed ||
        task.status == ContractorTaskStatus.inProgress ||
        task.status == ContractorTaskStatus.pendingComplete;
  }

  /// Show apply dialog with price and optional message
  Future<void> _showApplyDialog(ContractorTask task) async {
    // Check KYC verification before allowing application
    final kycState = ref.read(kycProvider);
    if (!kycState.canAcceptTasks) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.kycRequired),
          content: Text(context.l10n.taskListKycRequiredToApply),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.contractorKyc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text(context.l10n.startVerification),
            ),
          ],
        ),
      );
      return;
    }

    final priceController = TextEditingController(text: task.price.toString());
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.taskListApplyDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.taskListClientBudget(task.price.toString()),
              style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: AppSpacing.paddingSM),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.taskListYourPriceLabel,
                hintText: context.l10n.taskListMinPriceHint,
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
                suffixText: context.l10n.currencySymbol,
              ),
            ),
            SizedBox(height: AppSpacing.paddingSM),
            TextField(
              controller: messageController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: context.l10n.taskListMessageOptional,
                hintText: context.l10n.taskListExperienceHint,
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text(context.l10n.taskListSendApplication),
          ),
        ],
      ),
    );

    if (result != true) return;

    final price = double.tryParse(priceController.text);
    if (price == null || price < 35) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.taskListMinimumPriceError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await ref
          .read(availableTasksProvider.notifier)
          .applyForTask(
            task.id,
            proposedPrice: price,
            message: messageController.text.isNotEmpty
                ? messageController.text
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.taskListApplicationSent),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.genericErrorWithPrefix(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
