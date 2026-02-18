import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_address_autocomplete.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../models/task_category.dart';

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
  final _budgetController = TextEditingController(text: '50');
  final _estimatedDurationController = TextEditingController();

  TaskCategory? _selectedCategory;
  bool _isNow = true;
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isLoading = false;

  // Location state
  LatLng? _selectedLatLng;
  String? _selectedAddress;
  String? _locationError;

  // Task images (max 5)
  final List<XFile> _selectedImages = [];
  static const int _maxImages = 5;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (_selectedCategory != null) {
      final category = TaskCategoryData.fromCategory(_selectedCategory!);
      _budgetController.text = category.suggestedPrice.toString();
    }

    // Add listeners to update summary when inputs change
    _budgetController.addListener(() {
      setState(() {});
    });
    _estimatedDurationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    _estimatedDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeScreen,
          tooltip: 'Zamknij',
        ),
        title: SFRainbowText(AppStrings.createTask),
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
                // Category selection
                _buildCategorySection(),
                SizedBox(height: AppSpacing.space8),

                // Description
                _buildDescriptionSection(),

                SizedBox(height: AppSpacing.space8),

                // Images (optional)
                _buildImageSection(),

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
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
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

  Widget _buildCategorySection() {
    final selectedCategoryData = _selectedCategory != null
        ? TaskCategoryData.fromCategory(_selectedCategory!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectCategory,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapSM),
        DropdownButtonFormField<TaskCategory>(
          initialValue: _selectedCategory,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Wybierz kategorię',
          ),
          items: TaskCategoryData.all.map((category) {
            return DropdownMenuItem<TaskCategory>(
              value: category.category,
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 18,
                    color: category.color,
                  ),
                  SizedBox(width: AppSpacing.gapSM),
                  Expanded(
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (category) {
            if (category == null) return;
            final selectedData = TaskCategoryData.fromCategory(category);
            setState(() {
              _selectedCategory = category;
              _budgetController.text = selectedData.suggestedPrice.toString();
            });
          },
        ),
        if (selectedCategoryData != null) ...[
          SizedBox(height: AppSpacing.gapSM),
          Text(
            selectedCategoryData.description,
            style: AppTypography.caption.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ],
    );
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(Routes.clientHome);
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zdjęcia (opcjonalnie)',
              style: AppTypography.labelLarge,
            ),
            Text(
              '${_selectedImages.length}/$_maxImages',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapSM),
        Text(
          'Dodaj zdjęcia, aby lepiej opisać zlecenie',
          style: AppTypography.caption.copyWith(
            color: AppColors.gray500,
          ),
        ),
        SizedBox(height: AppSpacing.gapMD),

        // Image grid
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add image button
              if (_selectedImages.length < _maxImages)
                Semantics(
                  label: 'Dodaj zdjęcie do zlecenia',
                  button: true,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(right: AppSpacing.gapSM),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: AppRadius.radiusMD,
                        border: Border.all(
                          color: AppColors.gray300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: AppColors.gray500,
                          ),
                          SizedBox(height: AppSpacing.gapXS),
                          Text(
                            'Dodaj',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Selected images
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(right: AppSpacing.gapSM),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.radiusMD,
                        child: Image.file(
                          File(image.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Semantics(
                          label: 'Usuń zdjęcie',
                          button: true,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: EdgeInsets.all(AppSpacing.paddingXS),
                              decoration: BoxDecoration(
                                color: AppColors.gray900.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) return;

    // Show bottom sheet with options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Wybierz z galerii'),
              onTap: () => context.pop(ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Zrób zdjęcie'),
              onTap: () => context.pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się wybrać zdjęcia'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Remove image at index
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Upload all selected images and return their URLs
  Future<List<String>> _uploadImages() async {
    final api = ref.read(apiClientProvider);
    final urls = <String>[];
    int failedCount = 0;

    for (final image in _selectedImages) {
      try {
        final bytes = await image.readAsBytes();
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: image.name,
          ),
        });

        debugPrint('Uploading image: ${image.name}');
        final response = await api.post<Map<String, dynamic>>(
          '/tasks/upload-image',
          data: formData,
        );

        debugPrint('Upload response: $response');
        final imageUrl = response['imageUrl'] as String?;
        if (imageUrl != null) {
          urls.add(imageUrl);
          debugPrint('Image uploaded successfully: $imageUrl');
        }
      } catch (e, stackTrace) {
        // Continue with other images if one fails
        failedCount++;
        debugPrint('Failed to upload image ${image.name}: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Show warning if some images failed
    if (failedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedCount == _selectedImages.length
                ? 'Nie udało się przesłać żadnego zdjęcia'
                : 'Nie udało się przesłać $failedCount zdjęć',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }

    return urls;
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

        // Address input with GPS option
        SFAddressInput(
          onLocationSelected: (latLng, address) {
            setState(() {
              _selectedLatLng = latLng;
              _selectedAddress = address;
              _locationError = null;
            });
          },
          initialAddress: _selectedAddress,
          initialLatLng: _selectedLatLng,
          errorText: _locationError,
        ),

        // Map preview when location is selected
        if (_selectedLatLng != null) ...[
          SizedBox(height: AppSpacing.gapMD),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusMD,
              border: Border.all(color: AppColors.gray200),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.radiusMD,
              child: SFMapPreview(
                center: _selectedLatLng!,
                zoom: 15,
                height: 180,
                markers: [
                  TaskMarker(
                    position: _selectedLatLng!,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBudgetSection() {
    final category = _selectedCategory != null
        ? TaskCategoryData.fromCategory(_selectedCategory!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row with two inputs side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget field
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.budget,
                    style: AppTypography.labelLarge,
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'PLN',
                      suffixStyle: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                      hintText: '35',
                      hintStyle: AppTypography.h3.copyWith(
                        color: AppColors.gray300,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź kwotę';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Wprowadź poprawną kwotę';
                      }
                      if (amount < 35) {
                        return 'Min. 35 PLN';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.gapMD),
            // Estimated duration field
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Szacowany czas',
                    style: AppTypography.labelLarge,
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  TextFormField(
                    controller: _estimatedDurationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.h3.copyWith(
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'h',
                      suffixStyle: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                      hintText: '2.5',
                      hintStyle: AppTypography.h3.copyWith(
                        color: AppColors.gray300,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional field
                      }
                      final hours = double.tryParse(value);
                      if (hours == null) {
                        return 'Podaj liczbę';
                      }
                      if (hours < 0.5) {
                        return 'Min. 0.5h';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapSM),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.gray500,
            ),
            SizedBox(width: AppSpacing.gapXS),
            Expanded(
              child: Text(
                'Cena za całość zlecenia. Minimalna stawka za godzine: 35 PLN',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
        if (category != null) ...[
          SizedBox(height: AppSpacing.gapXS),
          Text(
            'Sugerowana cena dla "${category.name}": ${category.suggestedPrice} PLN',
            style: AppTypography.caption.copyWith(
              color: AppColors.gray600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
        Semantics(
          label: 'Wybierz realizację teraz',
          button: true,
          child: GestureDetector(
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
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Schedule for later
        Semantics(
          label: 'Wybierz realizację na później',
          button: true,
          child: GestureDetector(
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
            '${_budgetController.text} PLN',
          ),
          _buildSummaryRow(
            'Kiedy',
            _isNow
                ? 'Teraz'
                : '${_scheduledDate.day}.${_scheduledDate.month} o ${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
          ),
          _buildSummaryRow(
            'Lokalizacja',
            _selectedAddress ?? 'Nie wybrano',
            wrapValue: true,
          ),
          if (_estimatedDurationController.text.isNotEmpty) ...[
            Divider(color: AppColors.gray200),
            _buildSummaryRow(
              'Szacowany czas',
              _formatDurationForSummary(_estimatedDurationController.text),
              isHighlighted: true,
            ),
          ] else if (category != null) ...[
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

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false, bool wrapValue = false}) {
    final valueStyle = AppTypography.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      color: isHighlighted ? AppColors.primary : AppColors.gray800,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.gapXS),
      child: wrapValue
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
                SizedBox(height: AppSpacing.gapXS),
                Text(
                  value,
                  style: valueStyle,
                  softWrap: true,
                ),
              ],
            )
          : Row(
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
                  style: valueStyle,
                ),
              ],
            ),
    );
  }

  /// Format duration hours for summary display
  String _formatDurationForSummary(String hoursText) {
    if (hoursText.isEmpty) return '';

    final hours = double.tryParse(hoursText);
    if (hours == null) return hoursText;

    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes min';
    } else if (hours == hours.floor()) {
      return '${hours.toInt()}h';
    } else {
      final wholeHours = hours.floor();
      final remainingMinutes = ((hours - wholeHours) * 60).round();
      return '${wholeHours}h ${remainingMinutes}min';
    }
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

    // Validate location is selected
    if (_selectedLatLng == null || _selectedAddress == null) {
      setState(() {
        _locationError = 'Wybierz lokalizację zlecenia';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wybierz lokalizację zlecenia'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build scheduled datetime if not immediate
      DateTime? scheduledAt;
      if (!_isNow) {
        scheduledAt = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          _scheduledTime.hour,
          _scheduledTime.minute,
        );
      }

      // Create title from first 50 chars of description
      final description = _descriptionController.text;
      final title = description.length > 50
          ? description.substring(0, 50)
          : description;

      // Parse budget from text field
      final budgetAmount = double.tryParse(_budgetController.text) ?? 35;

      // Parse estimated duration (optional)
      final estimatedDurationHours = _estimatedDurationController.text.isNotEmpty
          ? double.tryParse(_estimatedDurationController.text)
          : null;

      // Upload images first if any selected
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      // Create task via API with real coordinates
      final dto = CreateTaskDto(
        category: _selectedCategory!,
        title: title,
        description: description,
        locationLat: _selectedLatLng!.latitude,
        locationLng: _selectedLatLng!.longitude,
        address: _selectedAddress!,
        budgetAmount: budgetAmount,
        estimatedDurationHours: estimatedDurationHours,
        scheduledAt: scheduledAt,
        imageUrls: imageUrls,
      );

      final task = await ref.read(clientTasksProvider.notifier).createTask(dto);

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zlecenie utworzone! Szukamy pomocnika...'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to task tracking
        context.go('/client/task/${task.id}/tracking');
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
