import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../client/models/task_category.dart';
import '../../client/widgets/category_card.dart';

/// Contractor registration screen - profile setup with photo, categories, and service radius
class ContractorRegistrationScreen extends ConsumerStatefulWidget {
  const ContractorRegistrationScreen({super.key});

  @override
  ConsumerState<ContractorRegistrationScreen> createState() =>
      _ContractorRegistrationScreenState();
}

class _ContractorRegistrationScreenState
    extends ConsumerState<ContractorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  File? _profilePhoto;
  final Set<TaskCategory> _selectedCategories = {};
  double _serviceRadius = 10.0; // km
  bool _isSubmitting = false;

  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
        title: SFRainbowText('Rejestracja wykonawcy'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Step content
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildCurrentStep(),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : AppColors.gray200,
                      borderRadius: AppRadius.radiusSM,
                    ),
                  ),
                ),
                if (index < 2) SizedBox(width: AppSpacing.gapSM),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildProfileStep();
      case 1:
        return _buildCategoriesStep();
      case 2:
        return _buildRadiusStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Twój profil',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Uzupełnij podstawowe informacje o sobie',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapXL),

          // Profile photo
          Center(
            child: GestureDetector(
              onTap: _selectProfilePhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.gray200,
                    backgroundImage:
                        _profilePhoto != null ? FileImage(_profilePhoto!) : null,
                    child: _profilePhoto == null
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: AppColors.gray400,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.paddingSM),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Center(
            child: Text(
              'Dodaj zdjęcie profilowe',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ),

          SizedBox(height: AppSpacing.gapXL),

          // Name field
          Text(
            'Imię i nazwisko',
            style: AppTypography.labelMedium,
          ),
          SizedBox(height: AppSpacing.gapSM),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'np. Jan Kowalski',
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Wprowadź imię i nazwisko';
              }
              if (value.trim().split(' ').length < 2) {
                return 'Wprowadź pełne imię i nazwisko';
              }
              return null;
            },
          ),

          SizedBox(height: AppSpacing.gapLG),

          // Phone field
          Text(
            'Numer telefonu',
            style: AppTypography.labelMedium,
          ),
          SizedBox(height: AppSpacing.gapSM),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+48 123 456 789',
              prefixIcon: Icon(Icons.phone, color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Wprowadź numer telefonu';
              }
              return null;
            },
          ),

          SizedBox(height: AppSpacing.gapLG),

          // Bio field
          Text(
            'O mnie (opcjonalnie)',
            style: AppTypography.labelMedium,
          ),
          SizedBox(height: AppSpacing.gapSM),
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Krótko opisz swoje doświadczenie i umiejętności...',
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategorie usług',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Wybierz kategorie zleceń, które chcesz wykonywać',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapXL),

          // Category pills (shared design)
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = AppSpacing.gapMD;
              final itemWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: TaskCategory.values.map((category) {
                  final data = TaskCategoryData.fromCategory(category);
                  final isSelected = _selectedCategories.contains(category);

                  return SizedBox(
                    width: itemWidth,
                    child: CategoryCard(
                      category: data,
                      isSelected: isSelected,
                      onTap: () => _toggleCategory(category),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          SizedBox(height: AppSpacing.gapLG),

          // Selected count
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: _selectedCategories.isNotEmpty
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.gray100,
              borderRadius: AppRadius.radiusMD,
            ),
            child: Row(
              children: [
                Icon(
                  _selectedCategories.isNotEmpty
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _selectedCategories.isNotEmpty
                      ? AppColors.success
                      : AppColors.gray500,
                ),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  _selectedCategories.isEmpty
                      ? 'Wybierz co najmniej jedną kategorię'
                      : 'Wybrano: ${_selectedCategories.length} ${_getCategoryWord(_selectedCategories.length)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: _selectedCategories.isNotEmpty
                        ? AppColors.success
                        : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zasięg działania',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Określ maksymalną odległość, w jakiej chcesz przyjmować zlecenia',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapXL),

          // Map placeholder with radius visualization
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: AppRadius.radiusLG,
            ),
            child: Stack(
              children: [
                Center(
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
                        'Mapa zasięgu',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Radius circle visualization
                Center(
                  child: Container(
                    width: _serviceRadius * 15,
                    height: _serviceRadius * 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Center point
                Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.gapXL),

          // Radius value display
          Center(
            child: Text(
              '${_serviceRadius.toInt()} km',
              style: AppTypography.h1.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),

          SizedBox(height: AppSpacing.gapMD),

          // Radius slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.gray200,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _serviceRadius,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (value) {
                setState(() => _serviceRadius = value);
              },
            ),
          ),

          // Range labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 km',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              Text(
                '50 km',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.gapXL),

          // Info box
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.accent,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.gapSM),
                Expanded(
                  child: Text(
                    'Większy zasięg oznacza więcej zleceń, ale też dłuższe dojazdy. Możesz zmienić to później.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                    side: BorderSide(color: AppColors.gray300),
                  ),
                  child: const Text('Wstecz'),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: AppSpacing.gapMD),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : (_currentStep < 2 ? _nextStep : _submitRegistration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMD,
                  ),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(
                        _currentStep < 2 ? 'Dalej' : 'Zakończ rejestrację',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCategory(TaskCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  String _getCategoryWord(int count) {
    if (count == 1) return 'kategorię';
    if (count >= 2 && count <= 4) return 'kategorie';
    return 'kategorii';
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wybierz co najmniej jedną kategorię'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _selectProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Zrób zdjęcie'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Wybierz z galerii'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_profilePhoto != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  'Usuń zdjęcie',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profilePhoto = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _profilePhoto = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nie można uzyskać dostępu do aparatu'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _profilePhoto = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nie można uzyskać dostępu do galerii'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // Navigate to KYC verification
      context.go('/contractor/kyc');
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przerwać rejestrację?'),
        content: const Text(
          'Twoje dane nie zostaną zapisane.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Wyjdź'),
          ),
        ],
      ),
    );
  }
}
