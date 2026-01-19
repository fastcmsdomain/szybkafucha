import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/task_category.dart';

/// Client home screen - main dashboard for clients
/// Shows welcome message, quick actions, and active/recent tasks
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header
              _buildWelcomeHeader(user?.name),

              SizedBox(height: AppSpacing.space8),

              // Quick action - Create task
              _buildQuickActionCard(context),

              SizedBox(height: AppSpacing.space8),

              // Popular categories
              _buildPopularCategories(context),

              SizedBox(height: AppSpacing.space8),

              // Active tasks section
              _buildActiveTasksSection(context),

              SizedBox(height: AppSpacing.space4),

              // How it works section
              _buildHowItWorksSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.clientCategories),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nowe zlecenie'),
      ),
    );
  }

  Widget _buildWelcomeHeader(String? userName) {
    final greeting = _getGreeting();
    final name = userName ?? 'Użytkowniku';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.gray600,
          ),
        ),
        SizedBox(height: AppSpacing.gapXS),
        Text(
          name,
          style: AppTypography.h2,
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dzień dobry';
    if (hour < 18) return 'Cześć';
    return 'Dobry wieczór';
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.clientCategories),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.radiusXL,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Potrzebujesz pomocy?',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapSM),
                  Text(
                    'Znajdź kogoś, kto pomoże Ci w codziennych zadaniach',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingMD,
                      vertical: AppSpacing.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      'Utwórz zlecenie',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.gapMD),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(
                Icons.handshake_outlined,
                size: 48,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popularne kategorie',
              style: AppTypography.h5,
            ),
            TextButton(
              onPressed: () => context.push(Routes.clientCategories),
              child: Text(
                'Zobacz wszystkie',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => SizedBox(width: AppSpacing.gapMD),
            itemBuilder: (context, index) {
              final category = TaskCategoryData.all[index];
              return _buildCategoryItem(context, category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, TaskCategoryData category) {
    return GestureDetector(
      onTap: () => context.push(
        Routes.clientCreateTask,
        extra: category.category,
      ),
      child: Container(
        width: 80,
        padding: EdgeInsets.all(AppSpacing.paddingSM),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusMD,
          border: Border.all(
            color: category.color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: category.color,
              size: 28,
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              category.name,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTasksSection(BuildContext context) {
    // Placeholder for active tasks - will be populated from API
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.activeTasks,
              style: AppTypography.h5,
            ),
            TextButton(
              onPressed: () => context.go(Routes.clientHistory),
              child: Text(
                AppStrings.viewHistory,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        // Empty state
        Container(
          padding: EdgeInsets.all(AppSpacing.paddingXL),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: AppRadius.radiusMD,
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.task_alt_outlined,
                size: 48,
                color: AppColors.gray400,
              ),
              SizedBox(height: AppSpacing.gapMD),
              Text(
                AppStrings.noActiveTasks,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.gapSM),
              Text(
                'Utwórz swoje pierwsze zlecenie, aby znaleźć pomocnika',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jak to działa?',
          style: AppTypography.h5,
        ),
        SizedBox(height: AppSpacing.gapMD),
        _buildStepItem(
          number: '1',
          title: 'Opisz zadanie',
          description: 'Wybierz kategorię i opisz, czego potrzebujesz',
          icon: Icons.edit_note_outlined,
        ),
        _buildStepItem(
          number: '2',
          title: 'Znajdź pomocnika',
          description: 'Przeglądaj profile i wybierz najlepszą osobę',
          icon: Icons.person_search_outlined,
        ),
        _buildStepItem(
          number: '3',
          title: 'Gotowe!',
          description: 'Śledź postęp i oceń po zakończeniu',
          icon: Icons.check_circle_outline,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.gray200,
                  ),
                ),
            ],
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    icon,
                    color: AppColors.gray400,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
