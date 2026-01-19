import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../models/task_category.dart';
import '../widgets/category_card.dart';

/// Task creation screen - collect task details
/// Includes: description, location, budget, schedule
class CreateTaskScreen extends ConsumerStatefulWidget {
  final TaskCategory? initialCategory;

  const CreateTaskScreen({
    super.key,
    this.initialCategory,
  });

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  TaskCategory? _selectedCategory;
  double _budget = 50;
  bool _isNow = true;
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _useCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (_selectedCategory != null) {
      final category = TaskCategoryData.fromCategory(_selectedCategory!);
      _budget = category.suggestedPrice.toDouble();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.createTask,
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category selection (if not pre-selected)
                if (_selectedCategory == null) ...[
                  _buildCategorySection(),
                  SizedBox(height: AppSpacing.space8),
                ] else ...[
                  _buildSelectedCategoryBadge(),
                  SizedBox(height: AppSpacing.space4),
                ],

                // Description
                _buildDescriptionSection(),

                SizedBox(height: AppSpacing.space8),

                // Location
                _buildLocationSection(),

                SizedBox(height: AppSpacing.space8),

                // Budget
                _buildBudgetSection(),

                SizedBox(height: AppSpacing.space8),

                // Schedule
                _buildScheduleSection(),

                SizedBox(height: AppSpacing.space8),

                // Summary
                _buildSummaryCard(),

                SizedBox(height: AppSpacing.space8),

                // Create button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.white),
                          ),
                        )
                      : Text(
                          'Znajdź pomocnika',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryBadge() {
    final category = TaskCategoryData.fromCategory(_selectedCategory!);

    return GestureDetector(
      onTap: () {
        // Allow changing category
        setState(() => _selectedCategory = null);
      },
      child: Container(
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
            Icon(
              category.icon,
              color: category.color,
              size: 24,
            ),
            SizedBox(width: AppSpacing.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: category.color,
                    ),
                  ),
                  Text(
                    category.description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: AppColors.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectCategory,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapMD),
        Wrap(
          spacing: AppSpacing.gapSM,
          runSpacing: AppSpacing.gapSM,
          children: TaskCategoryData.all.map((category) {
            return CategoryChip(
              category: category,
              isSelected: _selectedCategory == category.category,
              onTap: () {
                setState(() {
                  _selectedCategory = category.category;
                  _budget = category.suggestedPrice.toDouble();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.taskDescription,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapSM),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Opisz szczegółowo, czego potrzebujesz...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray400,
            ),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Wprowadź opis zadania';
            }
            if (value.length < 10) {
              return 'Opis musi mieć co najmniej 10 znaków';
            }
            return null;
          },
        ),
        SizedBox(height: AppSpacing.gapXS),
        Text(
          'Min. 10 znaków',
          style: AppTypography.caption.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.location,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapMD),

        // Use current location toggle
        GestureDetector(
          onTap: () => setState(() => _useCurrentLocation = true),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: _useCurrentLocation
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: _useCurrentLocation
                    ? AppColors.primary
                    : AppColors.gray200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: _useCurrentLocation
                      ? AppColors.primary
                      : AppColors.gray600,
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Użyj mojej lokalizacji',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: _useCurrentLocation
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Automatycznie wykryj lokalizację GPS',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRadioIndicator(_useCurrentLocation),
              ],
            ),
          ),
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Manual address
        GestureDetector(
          onTap: () => setState(() => _useCurrentLocation = false),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: !_useCurrentLocation
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: !_useCurrentLocation
                    ? AppColors.primary
                    : AppColors.gray200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: !_useCurrentLocation
                      ? AppColors.primary
                      : AppColors.gray600,
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wpisz adres',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: !_useCurrentLocation
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (!_useCurrentLocation) ...[
                        SizedBox(height: AppSpacing.gapSM),
                        TextFormField(
                          controller: _addressController,
                          style: AppTypography.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'np. ul. Marszałkowska 1, Warszawa',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.paddingSM,
                              vertical: AppSpacing.paddingSM,
                            ),
                          ),
                          validator: !_useCurrentLocation
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Wprowadź adres';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                _buildRadioIndicator(!_useCurrentLocation),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    final category = _selectedCategory != null
        ? TaskCategoryData.fromCategory(_selectedCategory!)
        : null;
    final minPrice = category?.minPrice.toDouble() ?? 20;
    final maxPrice = category?.maxPrice.toDouble() ?? 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.budget,
              style: AppTypography.labelLarge,
            ),
            Text(
              '${_budget.round()} PLN',
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        Slider(
          value: _budget.clamp(minPrice, maxPrice),
          min: minPrice,
          max: maxPrice,
          divisions: ((maxPrice - minPrice) / 5).round(),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.gray200,
          onChanged: (value) {
            setState(() => _budget = value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${minPrice.round()} PLN',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
            if (category != null)
              Text(
                'Sugerowana: ${category.suggestedPrice} PLN',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            Text(
              '${maxPrice.round()} PLN',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.schedule,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapMD),

        // Now option
        GestureDetector(
          onTap: () => setState(() => _isNow = true),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: _isNow
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: _isNow ? AppColors.primary : AppColors.gray200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: _isNow ? AppColors.primary : AppColors.gray600,
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.now,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: _isNow ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Znajdź pomocnika jak najszybciej',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRadioIndicator(_isNow),
              ],
            ),
          ),
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Schedule for later
        GestureDetector(
          onTap: () => setState(() => _isNow = false),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: !_isNow
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: !_isNow ? AppColors.primary : AppColors.gray200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: !_isNow ? AppColors.primary : AppColors.gray600,
                    ),
                    SizedBox(width: AppSpacing.gapMD),
                    Expanded(
                      child: Text(
                        AppStrings.scheduleForLater,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: !_isNow ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    _buildRadioIndicator(!_isNow),
                  ],
                ),
                if (!_isNow) ...[
                  SizedBox(height: AppSpacing.gapMD),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(),
                      ),
                      SizedBox(width: AppSpacing.gapMD),
                      Expanded(
                        child: _buildTimeButton(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _scheduledDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) {
          setState(() => _scheduledDate = picked);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gray700,
        side: BorderSide(color: AppColors.gray300),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingSM,
          vertical: AppSpacing.paddingSM,
        ),
      ),
      icon: Icon(Icons.calendar_today, size: 18),
      label: Text(
        '${_scheduledDate.day}.${_scheduledDate.month}.${_scheduledDate.year}',
        style: AppTypography.bodySmall,
      ),
    );
  }

  Widget _buildTimeButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _scheduledTime,
        );
        if (picked != null) {
          setState(() => _scheduledTime = picked);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gray700,
        side: BorderSide(color: AppColors.gray300),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingSM,
          vertical: AppSpacing.paddingSM,
        ),
      ),
      icon: Icon(Icons.access_time, size: 18),
      label: Text(
        '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
        style: AppTypography.bodySmall,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final category = _selectedCategory != null
        ? TaskCategoryData.fromCategory(_selectedCategory!)
        : null;

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.gapMD),
          _buildSummaryRow(
            'Kategoria',
            category?.name ?? 'Nie wybrano',
          ),
          _buildSummaryRow(
            'Budżet',
            '${_budget.round()} PLN',
          ),
          _buildSummaryRow(
            'Kiedy',
            _isNow
                ? 'Teraz'
                : '${_scheduledDate.day}.${_scheduledDate.month} o ${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
          ),
          _buildSummaryRow(
            'Lokalizacja',
            _useCurrentLocation ? 'Moja lokalizacja' : 'Adres ręczny',
          ),
          if (category != null) ...[
            Divider(color: AppColors.gray200),
            _buildSummaryRow(
              'Szacowany czas',
              category.estimatedTime,
              isHighlighted: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.gapXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.primary : AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }

  /// Custom radio indicator to replace deprecated Radio widget
  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.gray400,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _createTask() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wybierz kategorię'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Create task via API
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Show success and navigate to contractor selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zlecenie utworzone! Szukamy pomocnika...'),
            backgroundColor: AppColors.success,
          ),
        );

        // TODO: Navigate to contractor selection or task tracking
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
