import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/credits_provider.dart';
import '../../../core/providers/kyc_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_cluster_marker.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../client/models/task_application.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';
import '../widgets/nearby_task_card.dart';

/// Contractor home / Główna tab — map+list of available tasks
class ContractorHomeScreen extends ConsumerStatefulWidget {
  const ContractorHomeScreen({super.key});

  @override
  ConsumerState<ContractorHomeScreen> createState() =>
      _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends ConsumerState<ContractorHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  double _currentZoom = 6.0;
  Set<TaskCategory> _selectedCategoryFilters = {};
  LatLng? _userLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(availableTasksProvider.notifier).loadTasks();
      ref.read(kycProvider.notifier).fetchStatus();
      ref.read(creditsProvider.notifier).fetchBalance();
      ref.read(myApplicationsProvider.notifier).loadApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    await Future.wait([
      ref.read(availableTasksProvider.notifier).refresh(),
      ref.read(kycProvider.notifier).fetchStatus(),
      ref.read(creditsProvider.notifier).fetchBalance(),
      ref.read(myApplicationsProvider.notifier).loadApplications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // WebSocket: new task available
    ref.listen<AsyncValue<NewTaskEvent>>(newTaskAvailableProvider, (
      previous,
      next,
    ) {
      next.whenData((newTask) {
        ref.read(availableTasksProvider.notifier).refresh();
        _showNewTaskAlert(newTask);
      });
    });

    // WebSocket: application accepted/rejected
    ref.listen<AsyncValue<Map<String, dynamic>>>(applicationResultProvider, (
      previous,
      next,
    ) {
      next.whenData((event) {
        final status = event['status']?.toString().toLowerCase();
        final taskId = event['taskId']?.toString();
        if (status == 'accepted' && taskId != null) {
          _showAcceptedAlert(taskId, event);
        }
      });
    });

    final tasksState = ref.watch(availableTasksProvider);
    final kycState = ref.watch(kycProvider);
    final myApps = ref.watch(myApplicationsProvider);
    final appliedTaskIds = myApps.applications
        .where(
          (a) =>
              a.status == ApplicationStatus.pending ||
              a.status == ApplicationStatus.accepted,
        )
        .map((a) => a.taskId)
        .toSet();
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
        title: _buildGreeting(),
        centerTitle: false,
        actions: [
          IconButton(
            icon: tasksState.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: tasksState.isLoading ? null : _refreshTasks,
            tooltip: 'Odśwież',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
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
      body: Column(
        children: [
          // KYC completion banner (if not yet verified)
          if (!kycState.isLoading && kycState.needsIdentityVerification)
            _buildCompletionBanner(),

          // Tab content
          Expanded(
            child: TabBarView(
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
                          appliedTaskIds: appliedTaskIds,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final userName = ref.watch(authProvider).user?.name ?? 'Wykonawco';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Dzień dobry'
        : (hour < 18 ? 'Cześć' : 'Dobry wieczór');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: AppTypography.caption.copyWith(color: AppColors.gray500),
        ),
        Text(userName, style: AppTypography.h5),
      ],
    );
  }

  Widget _buildCompletionBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMD,
        vertical: AppSpacing.paddingSM,
      ),
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Text(
              'Dokończ rejestrację, aby zacząć zarabiać',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push(Routes.contractorProfileEdit),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingSM),
            ),
            child: Text(
              'Uzupełnij',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category filter helpers ──────────────────────────────────────────────

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
    if (effectiveSelectedFilters.isEmpty) return tasks;
    return tasks
        .where((task) => effectiveSelectedFilters.contains(task.category))
        .toList();
  }

  String _getSelectedFiltersLabel(Set<TaskCategory> effectiveSelectedFilters) {
    if (effectiveSelectedFilters.isEmpty) return 'Filtry';
    if (effectiveSelectedFilters.length == 1) {
      return TaskCategoryData.fromCategory(effectiveSelectedFilters.first).name;
    }
    return '${effectiveSelectedFilters.length} wybrane';
  }

  // ── Map tab ──────────────────────────────────────────────────────────────

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

    if (availableCategoryData.isEmpty) return const SizedBox.shrink();

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
                            'Wybierz kategorie',
                            style: AppTypography.h4,
                          ),
                        ),
                        TextButton(
                          onPressed: draft.isEmpty
                              ? null
                              : () => setModalState(() => draft.clear()),
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
                      child: availableCategoryData.isEmpty
                          ? Center(
                              child: Text(
                                'Brak kategorii do filtrowania',
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
                            child: const Text('Anuluj'),
                          ),
                        ),
                        SizedBox(width: AppSpacing.gapMD),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _selectedCategoryFilters = draft);
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

  Widget _buildMapTab(
    AvailableTasksState tasksState,
    List<ContractorTask> tasks, {
    required Set<TaskCategory> availableCategories,
    required Set<TaskCategory> effectiveSelectedFilters,
  }) {
    if (tasksState.isLoading && tasks.isEmpty) return _buildLoadingState();
    if (tasksState.error != null) return _buildErrorState(tasksState.error!);

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
              if (hasGesture) setState(() => _currentZoom = position.zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.szybkafucha.mobile',
              maxZoom: 19,
              tileProvider: NetworkTileProvider(
                cachingProvider: const DisabledMapCachingProvider(),
              ),
            ),
            if (_userLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _userLocation!,
                    radius: 10000,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderColor: AppColors.primary.withValues(alpha: 0.3),
                    borderStrokeWidth: 2,
                  ),
                ],
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
                      onTap: () => _showTaskDetails(task),
                      child: TaskMarker(
                        position: cluster.center,
                      ).build(context),
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
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

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
                  '${tasks.length} zleceń',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filters button
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
              _buildZoomButton(icon: Icons.add, onPressed: _zoomIn),
              SizedBox(height: AppSpacing.gapXS),
              _buildZoomButton(icon: Icons.remove, onPressed: _zoomOut),
              SizedBox(height: AppSpacing.gapMD),
              _buildZoomButton(
                icon: Icons.my_location,
                onPressed: _isLocating ? null : _goToMyLocation,
                isActive: _userLocation != null,
                isLoading: _isLocating,
              ),
              SizedBox(height: AppSpacing.gapXS),
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
    required VoidCallback? onPressed,
    bool isActive = false,
    bool isLoading = false,
  }) {
    return Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.white,
      elevation: 2,
      borderRadius: AppRadius.radiusSM,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.radiusSM,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppColors.primary : AppColors.gray700,
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
    setState(() {
      _currentZoom = 6.0;
      _userLocation = null;
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      final service = ref.read(locationServiceProvider);
      final permission = await service.checkPermission();
      if (permission != LocationPermissionStatus.granted) {
        final requested = await service.requestPermission();
        if (requested != LocationPermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Brak dostępu do lokalizacji. Włącz w ustawieniach.',
                ),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Ustawienia',
                  textColor: AppColors.white,
                  onPressed: () => service.openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      final latLng = await service.getCurrentLatLng();
      if (latLng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nie udało się pobrać lokalizacji'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      const zoomFor10km = 12.0;
      _mapController.move(latLng, zoomFor10km);
      setState(() {
        _userLocation = latLng;
        _currentZoom = zoomFor10km;
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _zoomToCluster(TaskCluster cluster) {
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
            'Brak dostępnych zleceń',
            style: AppTypography.h5.copyWith(color: AppColors.gray600),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            hasActiveFilter
                ? 'Brak zleceń dla wybranych kategorii.'
                : 'Na mapie pojawią się zlecenia,\ngdy będą dostępne.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── List tab ─────────────────────────────────────────────────────────────

  Widget _buildListTab(
    AvailableTasksState tasksState,
    List<ContractorTask> tasks, {
    required bool hasActiveFilter,
    required Set<String> appliedTaskIds,
  }) {
    if (tasksState.isLoading && tasks.isEmpty) return _buildLoadingState();
    if (tasksState.error != null) return _buildErrorState(tasksState.error!);
    if (tasks.isEmpty)
      return _buildEmptyState(hasActiveFilter: hasActiveFilter);

    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.gapMD),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final hasApplied = appliedTaskIds.contains(task.id);
        return NearbyTaskCard(
          task: task,
          onTap: () =>
              hasApplied ? _goToTaskRoom(task) : _showTaskDetails(task),
          onDetails: () => _showTaskDetails(task),
          onAccept: () =>
              hasApplied ? _goToTaskRoom(task) : _showApplyDialog(task),
          acceptButtonLabel: hasApplied ? 'Zobacz zlecenie' : 'Zgłoś się',
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
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Wystąpił błąd',
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
              'Brak dostępnych zleceń',
              style: AppTypography.h5.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              hasActiveFilter
                  ? 'Brak zleceń dla wybranych kategorii.'
                  : 'Obecnie nie ma żadnych dostępnych zleceń w Twojej okolicy. '
                        'Sprawdź ponownie później.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
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

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _showTaskDetails(ContractorTask task) {
    context.push(Routes.contractorTaskAlertRoute(task.id), extra: task);
  }

  void _goToTaskRoom(ContractorTask task) {
    context.push(Routes.contractorTaskRoomRoute(task.id), extra: task);
  }

  bool _isActiveOrNew(ContractorTask task) {
    return task.status == ContractorTaskStatus.available ||
        task.status == ContractorTaskStatus.accepted ||
        task.status == ContractorTaskStatus.confirmed ||
        task.status == ContractorTaskStatus.inProgress ||
        task.status == ContractorTaskStatus.pendingComplete;
  }

  Future<bool> _ensureVerifiedPhoneForApplications() async {
    final user = ref.read(authProvider).user;
    if (user?.phone?.trim().isNotEmpty == true) return true;
    await _showPhoneRequiredDialog();

    return false;
  }

  Future<void> _showApplyDialog(ContractorTask task) async {
    if (!await _ensureVerifiedPhoneForApplications()) return;

    final kycState = ref.read(kycProvider);
    if (kycState.needsIdentityVerification) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Wymagana weryfikacja tożsamości'),
          content: const Text(
            'Aby aplikować na zlecenia, musisz najpierw zweryfikować swoją tożsamość (dokument + selfie).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (!mounted) return;
                this.context.push(Routes.contractorKyc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Weryfikuj'),
            ),
          ],
        ),
      );
      return;
    }

    final credits = ref.read(creditsProvider);
    final hasSufficientBalance = credits.balance >= 10;

    final priceController = TextEditingController(text: task.price.toString());
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zgłoś się do zlecenia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budżet klienta: ${task.price} zł',
              style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: AppSpacing.paddingSM),
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingSM),
              decoration: BoxDecoration(
                color: hasSufficientBalance
                    ? AppColors.info.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: hasSufficientBalance
                            ? AppColors.info
                            : AppColors.warning,
                      ),
                      SizedBox(width: AppSpacing.gapSM),
                      Text(
                        'Twoje saldo: ${credits.balance.toStringAsFixed(2)} zł',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasSufficientBalance
                              ? AppColors.info
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.gapXS),
                  Text(
                    'Przy akceptacji pobierzemy 10 zł z Twojego konta.',
                    style: AppTypography.caption.copyWith(
                      color: hasSufficientBalance
                          ? AppColors.info
                          : AppColors.warning,
                    ),
                  ),
                  if (!hasSufficientBalance) ...[
                    SizedBox(height: AppSpacing.gapSM),
                    Text(
                      'Uwaga: Twoje saldo jest niewystarczające. Doładuj portfel przed akceptacją.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: AppSpacing.paddingSM),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Twoja cena (zł)',
                hintText: 'Min. 35 zł',
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
                suffixText: 'zł',
              ),
            ),
            SizedBox(height: AppSpacing.paddingSM),
            TextField(
              controller: messageController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Wiadomość (opcjonalnie)',
                hintText: 'Opisz swoje doświadczenie...',
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Wyślij zgłoszenie'),
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
            content: const Text('Minimalna cena to 35 zł'),
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

      ref.read(myApplicationsProvider.notifier).loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Zgłoszenie wysłane! Czekaj na decyzję klienta.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already applied')) {
          ref.read(myApplicationsProvider.notifier).loadApplications();
          _goToTaskRoom(task);
          return;
        } else if (_isMissingPhoneApplicationError(e)) {
          await _showPhoneRequiredDialog();
        } else if (_isIncompleteProfileApplicationError(e)) {
          await _showProfileRequiredDialog();
        } else if (e is ForbiddenException) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: Icon(Icons.block, color: AppColors.error, size: 48),
              title: const Text('Nie możesz dołączyć'),
              content: const Text(
                'Zostałeś zwolniony z tego zlecenia przez klienta i nie możesz ponownie aplikować.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Rozumiem'),
                ),
              ],
            ),
          );
        } else {
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

  bool _isMissingPhoneApplicationError(Object error) {
    final user = ref.read(authProvider).user;
    if (user?.phone?.trim().isEmpty ?? true) {
      return true;
    }

    if (error is ApiException) {
      final message = error.message.toLowerCase();
      return message.contains('phone') || message.contains('telefon');
    }

    return false;
  }

  bool _isIncompleteProfileApplicationError(Object error) {
    if (error is ApiException) {
      return error.message.toLowerCase().contains(
        'complete your contractor profile before applying for tasks',
      );
    }

    return false;
  }

  Future<void> _showPhoneRequiredDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj numer telefonu'),
        content: const Text(
          'Przed wysłaniem oferty musisz dodać i potwierdzić numer telefonu kodem SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Później'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.phoneLink);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Dodaj numer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileRequiredDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uzupełnij profil wykonawcy'),
        content: const Text(
          'Zanim wyślesz ofertę, uzupełnij wymagane dane profilu wykonawcy i zakończ weryfikację konta.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Rozumiem'),
          ),
        ],
      ),
    );
  }

  // ── WebSocket alert modals ────────────────────────────────────────────────

  void _showAcceptedAlert(String taskId, Map<String, dynamic> event) {
    HapticFeedback.heavyImpact();

    final taskTitle = event['taskTitle']?.toString() ?? '';
    final taskCategory = event['taskCategory']?.toString() ?? '';
    final clientName = event['clientName']?.toString() ?? 'Szef';

    final category = TaskCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == taskCategory.toLowerCase(),
      orElse: () => TaskCategory.paczki,
    );
    final categoryData = TaskCategoryData.fromCategory(category);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusXL,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: AppSpacing.paddingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Text(
                    'Zostałeś wybrany!',
                    style: AppTypography.h4.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.paddingMD),
                        decoration: BoxDecoration(
                          color: categoryData.color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusLG,
                        ),
                        child: Icon(
                          categoryData.icon,
                          color: categoryData.color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: AppSpacing.gapMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(categoryData.name, style: AppTypography.h5),
                            if (taskTitle.isNotEmpty) ...[
                              SizedBox(height: AppSpacing.gapXS),
                              Text(
                                taskTitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.gray600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMD,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.celebration,
                          color: AppColors.success,
                          size: 24,
                        ),
                        SizedBox(width: AppSpacing.gapSM),
                        Expanded(
                          child: Text(
                            '$clientName wybrał Cię do realizacji tego zlecenia!',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(Routes.contractorTask(taskId));
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Więcej'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLG,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final currentUser = ref.read(currentUserProvider);
                        context.push(
                          Routes.contractorTaskChatRoute(taskId),
                          extra: {
                            'otherUserId': event['clientId']?.toString() ?? '',
                            'taskTitle': taskTitle.isNotEmpty
                                ? taskTitle
                                : 'Czat',
                            'otherUserName': clientName,
                            'currentUserId': currentUser?.id ?? '',
                            'currentUserName': currentUser?.name ?? 'Ty',
                          },
                        );
                      },
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('Czat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLG,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showNewTaskAlert(NewTaskEvent task) {
    HapticFeedback.heavyImpact();

    final category = TaskCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == task.category.toLowerCase(),
      orElse: () => TaskCategory.paczki,
    );
    final categoryData = TaskCategoryData.fromCategory(category);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusXL,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: AppSpacing.paddingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Text(
                    'Nowe zlecenie!',
                    style: AppTypography.h4.copyWith(color: AppColors.success),
                  ),
                  const Spacer(),
                  if (task.distance != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingSM,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: AppRadius.radiusSM,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: AppColors.info,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${task.distance!.toStringAsFixed(1)} km',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.paddingMD),
                        decoration: BoxDecoration(
                          color: categoryData.color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusLG,
                        ),
                        child: Icon(
                          categoryData.icon,
                          color: categoryData.color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: AppSpacing.gapMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(categoryData.name, style: AppTypography.h4),
                            SizedBox(height: 4),
                            Text(
                              task.address,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.gray500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.gapLG),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: AppRadius.radiusLG,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Do zarobienia: ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '${task.budgetAmount.toStringAsFixed(0)} zł',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray700,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLG,
                        ),
                        side: BorderSide(color: AppColors.gray300),
                      ),
                      child: const Text('Pomiń'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(Routes.contractorTaskAlertRoute(task.id));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLG,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: AppSpacing.gapSM),
                          const Text('Zobacz szczegóły'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
