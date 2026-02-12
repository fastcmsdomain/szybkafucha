import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../models/contractor.dart';
import '../models/task_category.dart';

/// Data passed to contractor selection screen
class ContractorSelectionData {
  final TaskCategory category;
  final String description;
  final int budget;
  final bool isImmediate;
  final DateTime? scheduledAt;
  final String? address;
  final bool useCurrentLocation;

  const ContractorSelectionData({
    required this.category,
    required this.description,
    required this.budget,
    this.isImmediate = true,
    this.scheduledAt,
    this.address,
    this.useCurrentLocation = true,
  });
}

/// Screen for selecting a contractor for a task
class ContractorSelectionScreen extends ConsumerStatefulWidget {
  final ContractorSelectionData? taskData;

  const ContractorSelectionScreen({
    super.key,
    this.taskData,
  });

  @override
  ConsumerState<ContractorSelectionScreen> createState() =>
      _ContractorSelectionScreenState();
}

class _ContractorSelectionScreenState
    extends ConsumerState<ContractorSelectionScreen> {
  List<Contractor> _contractors = [];
  bool _isLoading = true;
  Contractor? _selectedContractor;
  String _sortBy = 'recommended';

  @override
  void initState() {
    super.initState();
    _loadContractors();
  }

  Future<void> _loadContractors() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _contractors = MockContractors.getForTask(
          budget: widget.taskData?.budget,
        );
        _isLoading = false;
      });
    }
  }

  void _sortContractors(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'rating':
          _contractors.sort((a, b) => b.rating.compareTo(a.rating));
        case 'price':
          _contractors.sort((a, b) =>
              (a.proposedPrice ?? 0).compareTo(b.proposedPrice ?? 0));
        case 'eta':
          _contractors.sort(
              (a, b) => (a.etaMinutes ?? 0).compareTo(b.etaMinutes ?? 0));
        default: // recommended
          _contractors.sort((a, b) {
            // Score based on rating, distance, and completion
            final scoreA = a.rating * 20 - (a.distanceKm ?? 10) * 2;
            final scoreB = b.rating * 20 - (b.distanceKm ?? 10) * 2;
            return scoreB.compareTo(scoreA);
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = widget.taskData != null
        ? TaskCategoryData.fromCategory(widget.taskData!.category)
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: SFRainbowText('Wybierz pomocnika'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Task summary header
          if (widget.taskData != null) _buildTaskSummary(categoryData!),

          // Sort options
          _buildSortOptions(),

          // Contractor list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contractors.isEmpty
                    ? _buildEmptyState()
                    : _buildContractorList(),
          ),
        ],
      ),
      bottomNavigationBar: _selectedContractor != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildTaskSummary(TaskCategoryData category) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.paddingMD),
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: category.color, size: 32),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.taskData!.budget} PLN',
                  style: AppTypography.h4.copyWith(
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                widget.taskData!.isImmediate
                    ? Icons.flash_on
                    : Icons.schedule,
                color: AppColors.gray500,
                size: 20,
              ),
              Text(
                widget.taskData!.isImmediate ? 'Teraz' : 'Zaplanowane',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMD,
        vertical: AppSpacing.paddingSM,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSortChip('recommended', 'Polecane', Icons.thumb_up_outlined),
            SizedBox(width: AppSpacing.gapSM),
            _buildSortChip('rating', 'Ocena', Icons.star_outline),
            SizedBox(width: AppSpacing.gapSM),
            _buildSortChip('price', 'Cena', Icons.attach_money),
            SizedBox(width: AppSpacing.gapSM),
            _buildSortChip('eta', 'Czas', Icons.access_time),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => _sortContractors(value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMD,
          vertical: AppSpacing.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.gray100,
          borderRadius: AppRadius.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.gray600,
            ),
            SizedBox(width: AppSpacing.gapXS),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.white : AppColors.gray700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              Icons.person_search,
              size: 64,
              color: AppColors.gray300,
            ),
            SizedBox(height: AppSpacing.space4),
            Text(
              'Szukamy pomocników w Twojej okolicy...',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space2),
            Text(
              'Spróbuj ponownie za chwilę lub zwiększ budżet',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            OutlinedButton(
              onPressed: _loadContractors,
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractorList() {
    return RefreshIndicator(
      onRefresh: _loadContractors,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        itemCount: _contractors.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: AppSpacing.gapMD),
        itemBuilder: (context, index) {
          final contractor = _contractors[index];
          return _buildContractorCard(contractor);
        },
      ),
    );
  }

  Widget _buildContractorCard(Contractor contractor) {
    final isSelected = _selectedContractor?.id == contractor.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContractor = isSelected ? null : contractor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.md : AppShadows.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.gray200,
                      backgroundImage: contractor.avatarUrl != null
                          ? NetworkImage(contractor.avatarUrl!)
                          : null,
                      child: contractor.avatarUrl == null
                          ? Text(
                              contractor.name[0].toUpperCase(),
                              style: AppTypography.h3.copyWith(
                                color: AppColors.gray600,
                              ),
                            )
                          : null,
                    ),
                    if (contractor.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: AppSpacing.gapMD),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            contractor.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (contractor.isVerified) ...[
                            SizedBox(width: AppSpacing.gapXS),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.gapXS),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 2),
                          Text(
                            contractor.formattedRating,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (${contractor.reviewCount})',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                          SizedBox(width: AppSpacing.gapMD),
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AppColors.gray500,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${contractor.completedTasks} zleceń',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${contractor.proposedPrice} PLN',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    if (contractor.etaMinutes != null)
                      Text(
                        contractor.formattedEta,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Distance and ETA bar
            SizedBox(height: AppSpacing.gapMD),
            Row(
              children: [
                if (contractor.distanceKm != null) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                  SizedBox(width: 2),
                  Text(
                    contractor.formattedDistance,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                ],
                if (contractor.etaMinutes != null) ...[
                  Icon(
                    Icons.directions_walk,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Dotrze za ${contractor.formattedEta}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => _showContractorProfile(contractor),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Zobacz profil',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContractorProfile(Contractor contractor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContractorProfileSheet(contractor: contractor),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedContractor!.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_selectedContractor!.proposedPrice} PLN • ${_selectedContractor!.formattedEta}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.gapMD),
            ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingLG,
                  vertical: AppSpacing.paddingMD,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: Text(
                'Wybierz',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment() {
    if (_selectedContractor == null || widget.taskData == null) return;

    context.push(
      Routes.clientPayment,
      extra: PaymentData(
        taskData: widget.taskData!,
        contractor: _selectedContractor!,
      ),
    );
  }
}

/// Data passed to payment screen
class PaymentData {
  final ContractorSelectionData taskData;
  final Contractor contractor;

  const PaymentData({
    required this.taskData,
    required this.contractor,
  });
}

/// Bottom sheet showing contractor profile details
class _ContractorProfileSheet extends StatelessWidget {
  final Contractor contractor;

  const _ContractorProfileSheet({required this.contractor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXL.topLeft.x),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: AppSpacing.paddingSM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: AppRadius.radiusFull,
            ),
          ),

          Padding(
            padding: EdgeInsets.all(AppSpacing.paddingLG),
            child: Column(
              children: [
                // Avatar and name
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.gray200,
                  child: Text(
                    contractor.name[0].toUpperCase(),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.gapMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      contractor.name,
                      style: AppTypography.h3,
                    ),
                    if (contractor.isVerified) ...[
                      SizedBox(width: AppSpacing.gapSM),
                      Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
                if (contractor.memberSince != null)
                  Text(
                    'Członek od ${_formatMemberSince(contractor.memberSince!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),

                SizedBox(height: AppSpacing.space6),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(
                      Icons.star,
                      contractor.formattedRating,
                      '${contractor.reviewCount} opinii',
                      AppColors.warning,
                    ),
                    _buildStat(
                      Icons.check_circle,
                      '${contractor.completedTasks}',
                      'zleceń',
                      AppColors.success,
                    ),
                    _buildStat(
                      Icons.access_time,
                      contractor.formattedEta,
                      'przybycie',
                      AppColors.primary,
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.space6),

                // Categories
                Wrap(
                  spacing: AppSpacing.gapSM,
                  runSpacing: AppSpacing.gapSM,
                  children: contractor.categories.map((cat) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingSM,
                        vertical: AppSpacing.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: AppRadius.radiusSM,
                      ),
                      child: Text(
                        cat,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray700,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: AppSpacing.space8),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.close),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: AppSpacing.gapXS),
        Text(
          value,
          style: AppTypography.h4,
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }

  String _formatMemberSince(DateTime date) {
    final months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
