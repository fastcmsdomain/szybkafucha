import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/category_pricing_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_address_autocomplete.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../models/task.dart';
import '../models/task_category.dart';

/// Task creation screen - collect task details
/// Includes: title, description, location, budget, schedule
class CreateTaskScreen extends ConsumerStatefulWidget {
  final TaskCategory? initialCategory;
  final String? editTaskId;

  const CreateTaskScreen({
    super.key,
    this.initialCategory,
    this.editTaskId,
  });

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

enum _TaskScheduleMode { now, flexible, scheduled }

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  static const String _defaultBudgetPln = '100';
  static const String _defaultEstimatedDurationHours = '1';
  static const String _remoteWorkAddress = 'Praca zdalna';
  static const LatLng _remoteWorkLatLng = LatLng(0, 0);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController(text: _defaultBudgetPln);
  final _estimatedDurationController = TextEditingController(
    text: _defaultEstimatedDurationHours,
  );

  TaskCategory? _selectedCategory;
  _TaskScheduleMode _scheduleMode = _TaskScheduleMode.now;
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _isInitializingEdit = false;

  // Location state
  LatLng? _selectedLatLng;
  String? _selectedAddress;
  String? _locationError;
  bool _isRemoteWork = false;

  // Task images (max 5)
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  static const int _maxImages = 5;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isEditMode => widget.editTaskId != null;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;

    // Fetch category pricing from API
    Future.microtask(() {
      ref.read(categoryPricingProvider.notifier).fetchPricing();
    });

    if (_selectedCategory != null) {
      // Use hardcoded default initially, will update when API data arrives
      _budgetController.text =
          TaskCategoryData.fromCategory(_selectedCategory!).suggestedPrice.toString();
    }

    // Add listeners to update summary when inputs change
    _budgetController.addListener(() {
      setState(() {});
    });
    _estimatedDurationController.addListener(() {
      setState(() {});
    });
    _titleController.addListener(() {
      setState(() {});
    });

    if (_isEditMode) {
      Future.microtask(_loadTaskForEdit);
    }
  }

  Future<void> _loadTaskForEdit() async {
    final taskId = widget.editTaskId;
    if (taskId == null) return;

    setState(() => _isInitializingEdit = true);

    try {
      Task? task = ref
          .read(clientTasksProvider)
          .tasks
          .where((t) => t.id == taskId)
          .firstOrNull;

      task ??= await _fetchTaskById(taskId);

      if (task == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nie znaleziono zlecenia do edycji'),
              backgroundColor: AppColors.error,
            ),
          );
          _closeScreen();
        }
        return;
      }
      if (!mounted) return;

      _selectedCategory = task.category;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _budgetController.text = task.budget.toString();
      _estimatedDurationController.text = _formatDurationForInput(
        task.estimatedDurationHours,
      );

      final isRemoteTask = task.address == _remoteWorkAddress;
      _isRemoteWork = isRemoteTask;
      if (isRemoteTask) {
        _selectedLatLng = _remoteWorkLatLng;
        _selectedAddress = _remoteWorkAddress;
      } else {
        if (task.latitude != null && task.longitude != null) {
          _selectedLatLng = LatLng(task.latitude!, task.longitude!);
        }
        _selectedAddress = task.address;
      }
      _existingImageUrls
        ..clear()
        ..addAll(task.imageUrls ?? const <String>[]);

      if (task.scheduledAt == null) {
        _scheduleMode = _TaskScheduleMode.now;
      } else {
        final scheduled = task.scheduledAt!;
        _scheduleMode = _TaskScheduleMode.scheduled;
        _scheduledDate = DateTime(
          scheduled.year,
          scheduled.month,
          scheduled.day,
        );
        _scheduledTime = TimeOfDay(
          hour: scheduled.hour,
          minute: scheduled.minute,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się załadować zlecenia do edycji: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializingEdit = false);
      }
    }
  }

  Future<Task?> _fetchTaskById(String taskId) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>('/tasks/$taskId');
      return Task.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  String _formatDurationForInput(double? value) {
    if (value == null) return '';
    if (value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
        title: SFRainbowText(
          _isEditMode ? 'Edytuj zlecenie' : AppStrings.createTask,
        ),
        centerTitle: true,
      ),
      body: _isInitializingEdit
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category selection
                _buildCategorySection(),
                SizedBox(height: AppSpacing.space6),

                // Title
                _buildTitleSection(),

                SizedBox(height: AppSpacing.space6),

                // Description
                _buildDescriptionSection(),

                SizedBox(height: AppSpacing.space6),

                // Images (optional)
                _buildImageSection(),

                SizedBox(height: AppSpacing.space6),

                // Location
                _buildLocationSection(),

                SizedBox(height: AppSpacing.space6),

                // Budget
                _buildBudgetSection(),

                SizedBox(height: AppSpacing.space6),

                // Schedule
                _buildScheduleSection(),

                SizedBox(height: AppSpacing.space6),

                // Summary
                _buildSummaryCard(),

                SizedBox(height: AppSpacing.space6),

                // Create button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isEditMode ? _saveTask : _createTask),
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
                          _isEditMode
                              ? 'Zapisz zlecenie'
                              : 'Znajdź pomocnika',
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
        SizedBox(height: AppSpacing.gapXS),
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
            // Use API pricing if available, otherwise hardcoded defaults
            final pricingData = ref
                .read(categoryPricingProvider.notifier)
                .getEffectivePricing(category);
            setState(() {
              _selectedCategory = category;
              _budgetController.text = pricingData.suggestedPrice.toString();
            });
          },
        ),
        if (selectedCategoryData != null) ...[
          SizedBox(height: AppSpacing.gapXS),
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

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.taskTitle,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapXS),
        TextFormField(
          controller: _titleController,
          maxLines: 1,
          maxLength: 200,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Np. Montaż lampy w salonie',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray400,
            ),
            counterText: '',
          ),
          validator: _validateTitle,
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
        SizedBox(height: AppSpacing.gapXS),
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
          validator: _validateDescription,
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
    final totalImages = _existingImageUrls.length + _selectedImages.length;

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
              '$totalImages/$_maxImages',
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
        SizedBox(height: AppSpacing.gapSM),

        // Image grid
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add image button
              if (totalImages < _maxImages)
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

              // Existing uploaded images (edit mode)
              ..._existingImageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;

                return Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(right: AppSpacing.gapSM),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.radiusMD,
                        child: Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            color: AppColors.gray100,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Semantics(
                          label: 'Usuń zdjęcie',
                          button: true,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(index),
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
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    if (totalImages >= _maxImages) return;

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

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
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
        SizedBox(height: AppSpacing.gapSM),

        // Address input with GPS option
        SFAddressInput(
          onLocationSelected: (latLng, address) {
            setState(() {
              _isRemoteWork = false;
              _selectedLatLng = latLng;
              _selectedAddress = address;
              _locationError = null;
            });
          },
          onRemoteSelected: () {
            setState(() {
              _isRemoteWork = true;
              _selectedLatLng = _remoteWorkLatLng;
              _selectedAddress = _remoteWorkAddress;
              _locationError = null;
            });
          },
          initialAddress: _isRemoteWork ? null : _selectedAddress,
          initialLatLng: _isRemoteWork ? null : _selectedLatLng,
          errorText: _locationError,
          isRemoteSelected: _isRemoteWork,
        ),

        // Map preview when location is selected
        if (!_isRemoteWork && _selectedLatLng != null) ...[
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
    // Get pricing from API provider (with hardcoded fallback)
    final category = _selectedCategory != null
        ? ref.read(categoryPricingProvider.notifier).getEffectivePricing(_selectedCategory!)
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
                  SizedBox(height: AppSpacing.gapSM),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: AppTypography.h4.copyWith(
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'PLN',
                      suffixStyle: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                      hintText: _defaultBudgetPln,
                      hintStyle: AppTypography.h4.copyWith(
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
                  SizedBox(height: AppSpacing.gapSM),
                  TextFormField(
                    controller: _estimatedDurationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: AppTypography.h4.copyWith(
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'h',
                      suffixStyle: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                      hintText: _defaultEstimatedDurationHours,
                      hintStyle: AppTypography.h4.copyWith(
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
            category.displayPriceInfo,
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
    final isNow = _scheduleMode == _TaskScheduleMode.now;
    final isFlexible = _scheduleMode == _TaskScheduleMode.flexible;
    final isScheduled = _scheduleMode == _TaskScheduleMode.scheduled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.schedule,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: AppSpacing.gapSM),

        Row(
          children: [
            Expanded(
              child: _buildScheduleChoice(
                label: AppStrings.now,
                icon: Icons.flash_on,
                isSelected: isNow,
                semanticsLabel: 'Wybierz realizację teraz',
                onTap: () => setState(() => _scheduleMode = _TaskScheduleMode.now),
              ),
            ),
            SizedBox(width: AppSpacing.gapMD),
            Expanded(
              child: _buildScheduleChoice(
                label: 'Elastyczny',
                icon: Icons.autorenew,
                isSelected: isFlexible,
                semanticsLabel: 'Wybierz realizację elastycznie',
                onTap: () =>
                    setState(() => _scheduleMode = _TaskScheduleMode.flexible),
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.gapSM),

        // Schedule for later
        Semantics(
          label: 'Wybierz realizację na później',
          button: true,
          child: GestureDetector(
            onTap: () => setState(() => _scheduleMode = _TaskScheduleMode.scheduled),
            child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingXS,
              vertical: AppSpacing.paddingMD,
            ),
            decoration: BoxDecoration(
              color: isScheduled
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray50,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: isScheduled ? AppColors.primary : AppColors.gray200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: isScheduled ? AppColors.primary : AppColors.gray600,
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                    Expanded(
                      child: Text(
                        AppStrings.scheduleForLater,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isScheduled ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    _buildRadioIndicator(isScheduled),
                  ],
                ),
                if (isScheduled) ...[
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

  Widget _buildScheduleChoice({
    required String label,
    required IconData icon,
    required bool isSelected,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingXS,
            vertical: AppSpacing.paddingMD,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.gray50,
            borderRadius: AppRadius.radiusMD,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.gray200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.gray600,
              ),
              SizedBox(width: AppSpacing.gapSM),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              _buildRadioIndicator(isSelected),
            ],
          ),
        ),
      ),
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
      onPressed: _showTimePickerSheet,
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

  Future<void> _showTimePickerSheet() async {
    DateTime tempDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.paddingLG,
              AppSpacing.paddingMD,
              AppSpacing.paddingLG,
              AppSpacing.paddingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: AppRadius.radiusSM,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.gapMD),
                Text(
                  'Wybierz godzinę',
                  style: AppTypography.labelLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.gapXS),
                Text(
                  'Przewin godziny i minuty lub wpisz czas recznie.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.gapMD),
                SizedBox(
                  height: 180,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: tempDateTime,
                    onDateTimeChanged: (value) {
                      tempDateTime = value;
                    },
                  ),
                ),
                SizedBox(height: AppSpacing.gapMD),
                OutlinedButton.icon(
                  onPressed: () async {
                    final manualTime = await _showManualTimeDialog();
                    if (!context.mounted || manualTime == null) return;
                    tempDateTime = DateTime(
                      _scheduledDate.year,
                      _scheduledDate.month,
                      _scheduledDate.day,
                      manualTime.hour,
                      manualTime.minute,
                    );
                    setState(() => _scheduledTime = manualTime);
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray700,
                    side: BorderSide(color: AppColors.gray300),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingSM),
                  ),
                  icon: const Icon(Icons.keyboard_alt_outlined),
                  label: const Text('Wpisz godzinę ręcznie'),
                ),
                SizedBox(height: AppSpacing.gapSM),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _scheduledTime = TimeOfDay(
                        hour: tempDateTime.hour,
                        minute: tempDateTime.minute,
                      );
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingSM),
                  ),
                  child: const Text('Gotowe'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> _showManualTimeDialog() async {
    final hourController = TextEditingController(
      text: _scheduledTime.hour.toString().padLeft(2, '0'),
    );
    final minuteController = TextEditingController(
      text: _scheduledTime.minute.toString().padLeft(2, '0'),
    );
    String? validationMessage;

    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Wpisz godzinę'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hourController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Godzina',
                            hintText: '08',
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.gapMD),
                      Expanded(
                        child: TextField(
                          controller: minuteController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Minuty',
                            hintText: '30',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (validationMessage != null) ...[
                    SizedBox(height: AppSpacing.gapSM),
                    Text(
                      validationMessage!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final hour = int.tryParse(hourController.text);
                    final minute = int.tryParse(minuteController.text);

                    if (hour == null ||
                        minute == null ||
                        hour < 0 ||
                        hour > 23 ||
                        minute < 0 ||
                        minute > 59) {
                      setDialogState(() {
                        validationMessage = 'Wpisz poprawny czas w formacie 00:00-23:59.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      TimeOfDay(hour: hour, minute: minute),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    hourController.dispose();
    minuteController.dispose();
    return result;
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
            'Tytuł',
            _titleController.text.trim().isEmpty
                ? 'Nie podano'
                : _titleController.text.trim(),
            wrapValue: true,
          ),
          _buildSummaryRow(
            'Budżet',
            '${_budgetController.text} PLN',
          ),
          _buildSummaryRow(
            'Kiedy',
            _scheduleMode == _TaskScheduleMode.now
                ? 'Teraz'
                : _scheduleMode == _TaskScheduleMode.flexible
                    ? 'Elastyczny'
                    : '${_scheduledDate.day}.${_scheduledDate.month} o ${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
          ),
          _buildSummaryRow(
            'Lokalizacja',
            _isRemoteWork
                ? _remoteWorkAddress
                : (_selectedAddress ?? 'Nie wybrano'),
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

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Wprowadź tytuł zlecenia';
    }
    if (title.length < 3) {
      return 'Tytuł musi mieć co najmniej 3 znaki';
    }
    if (title.length > 200) {
      return 'Tytuł może mieć maksymalnie 200 znaków';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return 'Wprowadź opis zadania';
    }
    if (description.length < 10) {
      return 'Opis musi mieć co najmniej 10 znaków';
    }

    // Block phone numbers with optional country code and separators.
    final phoneRegex = RegExp(
      r'(?:(?:\+|00)\d{1,3}[\s.-]?)?(?:\d[\s.-]?){8,14}\d',
    );
    if (phoneRegex.hasMatch(description)) {
      return 'Nie podawaj numeru telefonu w opisie';
    }

    // Block long numeric patterns separated by comma, dot or space.
    final separatedDigitsRegex = RegExp(r'\d{2,}(?:[.,\s]\d{2,}){2,}');
    if (separatedDigitsRegex.hasMatch(description)) {
      return 'Usuń długie ciągi cyfr z opisu';
    }

    // Block continuous long numeric strings.
    final continuousDigitsRegex = RegExp(r'\d{5,}');
    if (continuousDigitsRegex.hasMatch(description)) {
      return 'Usuń ciągłe zapisy numeryczne z opisu';
    }

    return null;
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

    final title = _titleController.text.trim();
    final titleValidationError = _validateTitle(title);
    if (titleValidationError != null) {
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(titleValidationError),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final descriptionValidationError = _validateDescription(description);
    if (descriptionValidationError != null) {
      // Force form errors to show and provide immediate warning on submit.
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(descriptionValidationError),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validate location is selected unless this is remote work.
    if (!_isRemoteWork &&
        (_selectedLatLng == null || _selectedAddress == null)) {
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
      if (_scheduleMode == _TaskScheduleMode.scheduled) {
        scheduledAt = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          _scheduledTime.hour,
          _scheduledTime.minute,
        );
      }

      // Parse budget from text field
      final budgetAmount =
          double.tryParse(_budgetController.text) ??
          double.parse(_defaultBudgetPln);

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
        locationLat: (_isRemoteWork ? _remoteWorkLatLng : _selectedLatLng!).latitude,
        locationLng: (_isRemoteWork ? _remoteWorkLatLng : _selectedLatLng!).longitude,
        address: _isRemoteWork ? _remoteWorkAddress : _selectedAddress!,
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

  Future<void> _saveTask() async {
    final taskId = widget.editTaskId;
    if (taskId == null) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wybierz kategorię'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final titleValidationError = _validateTitle(title);
    if (titleValidationError != null) {
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(titleValidationError),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final descriptionValidationError = _validateDescription(description);
    if (descriptionValidationError != null) {
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(descriptionValidationError),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_isRemoteWork &&
        (_selectedLatLng == null || _selectedAddress == null)) {
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
      DateTime? scheduledAt;
      if (_scheduleMode == _TaskScheduleMode.scheduled) {
        scheduledAt = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          _scheduledTime.hour,
          _scheduledTime.minute,
        );
      }

      final budgetAmount =
          double.tryParse(_budgetController.text) ??
          double.parse(_defaultBudgetPln);

      final estimatedDurationHours = _estimatedDurationController.text.isNotEmpty
          ? double.tryParse(_estimatedDurationController.text)
          : null;

      final imageUrls = <String>[..._existingImageUrls];
      if (_selectedImages.isNotEmpty) {
        imageUrls.addAll(await _uploadImages());
      }

      final dto = CreateTaskDto(
        category: _selectedCategory!,
        title: title,
        description: description,
        locationLat: (_isRemoteWork ? _remoteWorkLatLng : _selectedLatLng!).latitude,
        locationLng: (_isRemoteWork ? _remoteWorkLatLng : _selectedLatLng!).longitude,
        address: _isRemoteWork ? _remoteWorkAddress : _selectedAddress!,
        budgetAmount: budgetAmount,
        estimatedDurationHours: estimatedDurationHours,
        scheduledAt: scheduledAt,
        imageUrls: imageUrls,
      );

      final updatedTask =
          await ref.read(clientTasksProvider.notifier).updateTask(taskId, dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zlecenie zapisane'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(Routes.clientTaskTrack(updatedTask.id));
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
