import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/public_tasks_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_cluster_marker.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../client/models/task_category.dart';
import '../../contractor/models/contractor_task.dart';
import '../../contractor/widgets/nearby_task_card.dart';

class PublicBrowseScreen extends ConsumerStatefulWidget {
  const PublicBrowseScreen({super.key});

  @override
  ConsumerState<PublicBrowseScreen> createState() => _PublicBrowseScreenState();
}

class _PublicBrowseScreenState extends ConsumerState<PublicBrowseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  double _currentZoom = 6.0;
  int _selectedBottomNavIndex = 1; // Start on "Zlecenia"
  Set<TaskCategory> _selectedCategoryFilters = {};

  static const String _profileLoginRoute = '${Routes.welcome}?tab=profile';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    await ref.read(publicTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicTasksProvider);
    final baseTasks = state.tasks.where(_isVisibleTask).toList();
    final filteredTasks = _getFilteredTasks(baseTasks);

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText(AppStrings.publicBrowseTitle),
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
          _buildMapTab(state, filteredTasks),
          Column(
            children: [
              _buildListCategoryFilterBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: _buildListTab(state, filteredTasks),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  bool _isVisibleTask(ContractorTask task) {
    return task.status == ContractorTaskStatus.available;
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

  Widget _buildMapTab(PublicTasksState state, List<ContractorTask> tasks) {
    if (state.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null && state.tasks.isEmpty) {
      return _buildErrorState(state.error!);
    }

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

    final clusters = TaskClusterManager.clusterTasks(
      clusterableTasks,
      _currentZoom,
    );

    return Stack(
      children: [
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
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.szybkafucha.mobile',
              maxZoom: 19,
            ),
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
                      onTap: () => _showTaskBottomSheet(task),
                      child: TaskMarker(position: cluster.center).build(context),
                    ),
                  );
                }

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

        Positioned(
          top: AppSpacing.paddingMD + 56,
          left: AppSpacing.paddingMD,
          child: _buildMapFiltersButton(),
        ),

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
    final newZoom = (_currentZoom + 2).clamp(5.0, 15.0);
    _mapController.move(cluster.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  Widget _buildListTab(PublicTasksState state, List<ContractorTask> tasks) {
    if (state.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null && state.tasks.isEmpty) {
      return _buildErrorState(state.error!);
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
          showActions: true,
          showClientInfo: false,
          onTap: () => _showTaskBottomSheet(task),
          onDetails: () => _showTaskBottomSheet(task),
          onAccept: () => _showTaskBottomSheet(task),
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
                : 'Na mapie pojawią się zlecenia,\ngdy będą dostępne.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                  : 'Sprawdź ponownie wkrótce.',
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

  void _showTaskBottomSheet(ContractorTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            NearbyTaskCard(
              task: task,
              showActions: false,
              showClientInfo: false,
            ),
            const SizedBox(height: 12),
            Text(
              'Aby przyjąć zlecenie, zaloguj się jako wykonawca.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(AppStrings.publicBrowseLoginPromptCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go(Routes.welcome);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(AppStrings.publicBrowseLoginPromptConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedBottomNavIndex,
      onDestinationSelected: (index) {
        if (index == 0) {
          setState(() => _selectedBottomNavIndex = 0);
          context.go(Routes.publicHome);
        } else if (index == 1) {
          setState(() => _selectedBottomNavIndex = 1);
        } else if (index == 2) {
          context.go(_profileLoginRoute);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: AppStrings.menuHome,
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: AppStrings.menuTasks,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: AppStrings.menuProfile,
        ),
      ],
    );
  }
}
