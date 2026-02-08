import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme.dart';

/// Client-only editable profile screen
class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState
    extends ConsumerState<ClientProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: ''); // Bio loaded from client profile
    _addressController = TextEditingController(text: user?.address ?? '');
    _loadClientProfile();
  }

  Future<void> _loadClientProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/client/profile');
      final data = response as Map<String, dynamic>;

      // DEBUG: Print the entire response
      debugPrint('=== CLIENT PROFILE API RESPONSE ===');
      debugPrint('Full response: $data');
      debugPrint('Bio: ${data['bio']}');
      debugPrint('===================================');

      if (mounted) {
        setState(() {
          // Load bio from client profile (role-specific)
          final bio = data['bio'] as String?;
          debugPrint('DEBUG: Loading bio = $bio');
          // Always set controller text to match backend state (even if null/empty)
          _bioController.text = bio ?? '';
          debugPrint('DEBUG: Set bioController.text to: ${_bioController.text}');
        });
      }
    } catch (e) {
      debugPrint('Error loading client profile: $e');
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
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);

      // Update user data (name, phone, address, avatar - shared data)
      final userPayload = <String, dynamic>{};
      final name = _nameController.text.trim();
      if (name.isNotEmpty) userPayload['name'] = name;
      userPayload['phone'] = _phoneController.text.trim();
      userPayload['address'] = _addressController.text.trim();

      debugPrint('=== SAVING CLIENT PROFILE ===');
      debugPrint('User payload: $userPayload');

      await api.put('/users/me', data: userPayload);

      // Update client profile (bio - role-specific data)
      final clientPayload = <String, dynamic>{
        'bio': _bioController.text.trim(),
      };

      debugPrint('Client payload: $clientPayload');

      await api.put('/client/profile', data: clientPayload);

      debugPrint('Profile saved successfully');
      debugPrint('============================');

      // Refresh user data in authProvider to update local state
      await ref.read(authProvider.notifier).refreshUser();

      // Reload client profile to refresh bio in UI
      await _loadClientProfile();

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój profil'),
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
                                (user?.name ?? 'K').isNotEmpty
                                    ? user!.name![0].toUpperCase()
                                    : 'K',
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

}
