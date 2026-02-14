import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../client/models/task_category.dart';

/// Contractor-only editable profile screen
class ContractorProfileScreen extends ConsumerStatefulWidget {
  const ContractorProfileScreen({super.key});

  @override
  ConsumerState<ContractorProfileScreen> createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState
    extends ConsumerState<ContractorProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  // Categories and service radius
  Set<String> _selectedCategories = {};
  double _serviceRadius = 10.0;

  // KYC verification status
  bool _isKycVerified = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: ''); // Bio loaded from contractor profile
    _addressController = TextEditingController(text: user?.address ?? '');
    _loadContractorProfile();
  }

  Future<void> _loadContractorProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/contractor/profile');
      final data = response as Map<String, dynamic>;

      // DEBUG: Print the entire response
      debugPrint('=== CONTRACTOR PROFILE API RESPONSE ===');
      debugPrint('Full response: $data');
      debugPrint('Bio: ${data['bio']}');
      debugPrint('Categories: ${data['categories']}');
      debugPrint('ServiceRadiusKm: ${data['serviceRadiusKm']}');
      debugPrint('KYC Status: ${data['kycStatus']}');
      debugPrint('======================================');

      if (mounted) {
        setState(() {
          // Load bio from contractor profile (role-specific)
          final bio = data['bio'] as String?;
          debugPrint('DEBUG: Loading bio = $bio');
          // Always set controller text to match backend state (even if null/empty)
          _bioController.text = bio ?? '';
          debugPrint('DEBUG: Set bioController.text to: ${_bioController.text}');

          // Load categories and service radius
          final categories = data['categories'] as List?;
          debugPrint('DEBUG: Loading categories = $categories');
          if (categories != null) {
            _selectedCategories = Set<String>.from(categories);
            debugPrint('DEBUG: Set selectedCategories to: $_selectedCategories');
          }

          // Handle serviceRadiusKm which might come as string or number
          final serviceRadiusKm = data['serviceRadiusKm'];
          debugPrint('DEBUG: Loading serviceRadiusKm = $serviceRadiusKm');
          if (serviceRadiusKm != null) {
            _serviceRadius = double.tryParse(serviceRadiusKm.toString()) ?? 10.0;
            debugPrint('DEBUG: Set serviceRadius to: $_serviceRadius');
          }

          // Load KYC verification status
          final kycStatus = data['kycStatus'] as String?;
          _isKycVerified = (kycStatus == 'verified');
          debugPrint('DEBUG: Set isKycVerified to: $_isKycVerified');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading contractor profile: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Show bottom sheet with photo source options
  void _showPhotoSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wybierz zdjęcie',
                style: AppTypography.h4,
              ),
              SizedBox(height: AppSpacing.gapMD),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Zrób zdjęcie'),
                subtitle: const Text('Użyj aparatu'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Wybierz z galerii'),
                subtitle: const Text('Wybierz istniejące zdjęcie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(source == ImageSource.camera
                ? 'Nie można uzyskać dostępu do aparatu'
                : 'Nie można uzyskać dostępu do galerii'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Upload avatar to backend
  Future<void> _uploadAvatar(File imageFile) async {
    setState(() => _isUploadingAvatar = true);

    try {
      final api = ref.read(apiClientProvider);

      // Create multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
        ),
      });

      await api.post('/users/me/avatar', data: formData);

      // Refresh user data to get new avatar URL
      await ref.read(authProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zdjęcie profilowe zostało zaktualizowane'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się przesłać zdjęcia: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('Imię i nazwisko jest wymagane');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError('Adres jest wymagany');
      return;
    }
    if (_bioController.text.trim().isEmpty) {
      _showError('Opis jest wymagany');
      return;
    }
    if (_selectedCategories.isEmpty) {
      _showError('Wybierz co najmniej jedną kategorię');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);

      // Update user data (name, phone, address - shared data)
      final userPayload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      };

      debugPrint('=== SAVING CONTRACTOR PROFILE ===');
      debugPrint('User payload: $userPayload');

      await api.put('/users/me', data: userPayload);

      // Update contractor profile (bio, categories, serviceRadiusKm - role-specific data)
      final contractorPayload = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'categories': _selectedCategories.toList(),
        'serviceRadiusKm': _serviceRadius.toInt(),
      };

      debugPrint('Contractor payload: $contractorPayload');

      await api.put('/contractor/profile', data: contractorPayload);

      debugPrint('Profile saved successfully');
      debugPrint('=================================');

      // Refresh user data in authProvider to update local state
      await ref.read(authProvider.notifier).refreshUser();

      // Reload contractor profile to refresh bio, categories, and service radius in UI
      await _loadContractorProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil zapisany'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zapisać: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText('Mój profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + change photo
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.gray200,
                    backgroundImage:
                        user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          )
                        : user?.avatarUrl == null
                            ? Text(
                                (user?.name ?? 'W').isNotEmpty
                                    ? user!.name![0].toUpperCase()
                                    : 'W',
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: _isUploadingAvatar ? AppColors.gray400 : AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isUploadingAvatar ? null : _showPhotoSourceOptions,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.camera_alt, color: AppColors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.space6),

            _buildProfileProgress(),

            SizedBox(height: AppSpacing.space6),

            _buildTextField(
              controller: _nameController,
              label: 'Imię i nazwisko',
              icon: Icons.person_outline,
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Numer telefonu',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Adres email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            _buildTextField(
              controller: _addressController,
              label: 'Adres',
              icon: Icons.home_outlined,
            ),
            _buildTextField(
              controller: _bioController,
              label: 'O mnie (opis)',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),

            SizedBox(height: AppSpacing.space6),

            _buildCategoriesSection(),

            SizedBox(height: AppSpacing.space6),

            _buildServiceRadiusSection(),

            SizedBox(height: AppSpacing.space6),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.paddingMD,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.gapMD),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusMD,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileProgress() {
    final user = ref.read(authProvider).user;

    int completedFields = 0;
    int totalFields = 6; // name, address, bio, categories, radius, kyc

    if (user?.name?.isNotEmpty == true) completedFields++;
    if (user?.address?.isNotEmpty == true) completedFields++;
    if (_bioController.text.isNotEmpty) completedFields++;
    if (_selectedCategories.isNotEmpty) completedFields++;
    if (_serviceRadius > 0) completedFields++;
    if (_isKycVerified == true) completedFields++;

    final percent = (completedFields / totalFields * 100).toInt();
    final isComplete = percent == 100;

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: isComplete ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weryfikacja',
                style: AppTypography.h4,
              ),
              Text(
                '$percent%',
                style: AppTypography.h3.copyWith(
                  color: isComplete ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          LinearProgressIndicator(
            value: completedFields / totalFields,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation(
              isComplete ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
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
            'Kategorie usług *',
            style: AppTypography.h4,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskCategoryData.all.map((data) {
              final categoryKey = data.category.name;
              final selected = _selectedCategories.contains(categoryKey);
              return FilterChip(
                label: Text(
                  data.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedCategories.add(categoryKey);
                    } else {
                      _selectedCategories.remove(categoryKey);
                    }
                  });
                },
                selectedColor: AppColors.success.withValues(alpha: 0.2),
                checkmarkColor: AppColors.gray900,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRadiusSection() {
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
            'Zasięg działania: ${_serviceRadius.toInt()} km',
            style: AppTypography.h4,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Slider(
            value: _serviceRadius,
            min: 5,
            max: 50,
            divisions: 45,
            label: '${_serviceRadius.toInt()} km',
            onChanged: (value) => setState(() => _serviceRadius = value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

}
