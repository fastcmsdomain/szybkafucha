import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/public_tasks_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
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
  int _selectedBottomNavIndex = 1; // Start on "Zlecenia"

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
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Job card
            NearbyTaskCard(
              task: task,
              showActions: false,
              showClientInfo: false,
            ),
            const SizedBox(height: 16),
            // Action buttons
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.publicBrowseTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(publicTasksProvider.notifier).refresh(),
            tooltip: 'Odśwież',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'MAPA'),
            Tab(text: 'LISTA'),
          ],
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, PublicTasksState state) {
    if (state.isLoading && state.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(publicTasksProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMapView(state.tasks),
        _buildListView(context, ref, state.tasks),
      ],
    );
  }

  Widget _buildMapView(List tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate center of Poland as default
    const LatLng center = LatLng(52.0, 19.0); // Center of Poland

    // Create markers for each task
    final markers = tasks.map((task) {
      return Marker(
        point: LatLng(task.latitude, task.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showTaskBottomSheet(task),
          child: Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 6.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.szybkafucha.app',
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, WidgetRef ref, List tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(publicTasksProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NearbyTaskCard(
              task: task,
              showActions: false,
              showClientInfo: false, // Hide client info for public view
              onTap: () => _showTaskBottomSheet(task),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Brak dostępnych zleceń',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sprawdź ponownie wkrótce',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedBottomNavIndex,
      onDestinationSelected: (index) {
        if (index == 0) {
          // Główna - placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Strona główna - wkrótce'),
              duration: Duration(seconds: 1),
            ),
          );
        } else if (index == 1) {
          // Zlecenia - already here
          setState(() => _selectedBottomNavIndex = 1);
        } else if (index == 2) {
          // Profil - go to login
          context.go(Routes.welcome);
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
