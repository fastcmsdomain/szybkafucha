import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/credits_provider.dart';
import '../../../core/providers/kyc_provider.dart';
import '../../../core/router/routes.dart';
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
  late final TextEditingController _dateOfBirthController;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  // Categories and service radius
  Set<String> _selectedCategories = {};
  double _serviceRadius = 10.0;

  // KYC verification status
  bool _isKycVerified = false;

  // Whether the user originally had an email set — determines if field is editable
  // Phone is always read-only (auth credential, requires OTP to change)
  bool _hadEmailOnLoad = false;
  bool _hadDateOfBirthOnLoad = false;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: ''); // Bio loaded from contractor profile
    _addressController = TextEditingController(text: user?.address ?? '');
    _dateOfBirthController = TextEditingController();
    _dateOfBirth = user?.dateOfBirth;
    _dateOfBirthController.text = user?.dateOfBirth != null
        ? _formatDateForDisplay(user!.dateOfBirth!)
        : '';
    _hadDateOfBirthOnLoad = user?.dateOfBirth != null;
    _hadEmailOnLoad = user?.email?.isNotEmpty == true;
    _loadContractorProfile();
    ref.read(creditsProvider.notifier).fetchBalance();
    ref.read(kycProvider.notifier).fetchStatus();
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
      debugPrint('DateOfBirth: ${data['dateOfBirth'] ?? data['date_of_birth']}');
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
            _serviceRadius = (double.tryParse(serviceRadiusKm.toString()) ?? 10.0).clamp(5.0, 50.0);
            debugPrint('DEBUG: Set serviceRadius to: $_serviceRadius');
          }

          // Load KYC verification status
          final kycStatus = data['kycStatus'] as String?;
          _isKycVerified = (kycStatus == 'verified');
          debugPrint('DEBUG: Set isKycVerified to: $_isKycVerified');

          final userData = data['user'];
          final dateOfBirthRaw = data['dateOfBirth'] ??
              data['date_of_birth'] ??
              data['birthDate'] ??
              (userData is Map<String, dynamic>
                  ? (userData['dateOfBirth'] ??
                      userData['date_of_birth'] ??
                      userData['birthDate'])
                  : null);
          final parsedDateOfBirth = dateOfBirthRaw is String
              ? DateTime.tryParse(dateOfBirthRaw)
              : null;
          if (parsedDateOfBirth != null ||
              data.containsKey('dateOfBirth') ||
              data.containsKey('date_of_birth') ||
              data.containsKey('birthDate')) {
            _dateOfBirth = parsedDateOfBirth;
            _hadDateOfBirthOnLoad = parsedDateOfBirth != null;
            _dateOfBirthController.text = parsedDateOfBirth != null
                ? _formatDateForDisplay(parsedDateOfBirth)
                : '';
          }
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
    _dateOfBirthController.dispose();
    super.dispose();
  }

  String _formatDateForDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _formatDateForApi(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _normalizePhoneForApi(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final normalized = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.startsWith('+')) return normalized;
    if (normalized.length == 9) return '+48$normalized';
    return normalized;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Wybierz datę urodzenia',
      cancelText: 'Anuluj',
      confirmText: 'Wybierz',
    );

    if (pickedDate == null) return;

    setState(() {
      _dateOfBirth = pickedDate;
      _dateOfBirthController.text = _formatDateForDisplay(pickedDate);
    });
  }

  Future<void> _saveProfile() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('Imię i nazwisko jest wymagane');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);

      // Update shared user data.
      final normalizedPhone = _normalizePhoneForApi(_phoneController.text);
      final email = _emailController.text.trim();
      final userPayload = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (normalizedPhone != null) 'phone': normalizedPhone,
        'address': _addressController.text.trim(),
        if (email.isNotEmpty) 'email': email,
        if (_dateOfBirth != null) 'dateOfBirth': _formatDateForApi(_dateOfBirth!),
        if (_dateOfBirth == null && _hadDateOfBirthOnLoad) 'dateOfBirth': null,
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
    final kycState = ref.watch(kycProvider);

    // Compute whether profile is 100% complete (mirrors _buildProfileProgress logic)
    // 5 real items: name, address, bio, categories, kyc (serviceRadius always has a value)
    final isProfileComplete = user?.name?.isNotEmpty == true &&
        user?.address?.isNotEmpty == true &&
        _bioController.text.isNotEmpty &&
        _selectedCategories.isNotEmpty &&
        kycState.selfieVerified;

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
            // Avatar + change photo + verified badge
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
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
                                    (user?.name?.isNotEmpty ?? false)
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
                  if (isProfileComplete) ...[
                    SizedBox(height: AppSpacing.gapSM),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppColors.success, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Zweryfikowany',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: AppSpacing.space6),

            _buildProfileProgress(),

            SizedBox(height: AppSpacing.space6),

            _buildWalletShortcut(),

            SizedBox(height: AppSpacing.space6),

            _buildTextField(
              controller: _nameController,
              label: 'Imię i nazwisko *',
              icon: Icons.person_outline,
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Numer telefonu',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              helperText:
                  'Dodaj numer telefonu. Numer 9-cyfrowy zapiszemy automatycznie z prefixem +48.',
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Adres email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
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
            _buildTextField(
              controller: _dateOfBirthController,
              label: 'Data urodzenia (opcjonalnie)',
              icon: Icons.cake_outlined,
              readOnly: true,
              showReadOnlyLock: false,
              onTap: _pickDateOfBirth,
              suffixIcon: _dateOfBirth != null
                  ? IconButton(
                      tooltip: 'Wyczyść datę',
                      onPressed: () {
                        setState(() {
                          _dateOfBirth = null;
                          _dateOfBirthController.clear();
                        });
                      },
                      icon: Icon(Icons.clear, size: 18, color: AppColors.gray500),
                    )
                  : Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.gray500,
                    ),
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

            SizedBox(height: AppSpacing.space8),

            _buildHowItWorksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SFRainbowText('Jak zacząć zarabiać?', style: AppTypography.h5),
        SizedBox(height: AppSpacing.gapMD),
        _buildStepItem(
          number: '1',
          title: 'Przeglądaj zlecenia',
          description:
              'Nowe zadania pojawiają się w Twojej okolicy — wybierz to, co Ci odpowiada',
          icon: Icons.search,
          color: AppColors.primary,
        ),
        _buildStepItem(
          number: '2',
          title: 'Złóż ofertę',
          description: 'Zaproponuj swoją cenę i wyślij zgłoszenie do szefa',
          icon: Icons.local_offer_outlined,
          color: AppColors.warning,
        ),
        _buildStepItem(
          number: '3',
          title: 'Wykonaj zadanie',
          description:
              'Szef wybrał Cię! Rozpocznij pracę i zrealizuj zlecenie',
          icon: Icons.handyman,
          color: AppColors.success,
        ),
        _buildStepItem(
          number: '4',
          title: 'Oceń szefa',
          description:
              'Po zakończeniu oceń współpracę — to pomaga całej społeczności',
          icon: Icons.star_outline,
          color: AppColors.info,
        ),
        _buildStepItem(
          number: '5',
          title: 'Gotowe!',
          description:
              'Zlecenie zakończone! Twoja ocena rośnie, a nowe zlecenia czekają',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF8B5CF6),
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
    required Color color,
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
                  color: color,
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
                  child: Container(width: 2, color: AppColors.gray200),
                ),
            ],
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.paddingMD),
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
                  Icon(icon, color: color, size: 24),
                ],
              ),
            ),
          ),
        ],
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
    String? helperText,
    VoidCallback? onTap,
    bool showReadOnlyLock = true,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.gapMD),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: readOnly
            ? AppTypography.bodyMedium.copyWith(color: AppColors.gray500)
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
          helperStyle: AppTypography.caption.copyWith(color: AppColors.gray400),
          suffixIcon: suffixIcon ??
              (readOnly && showReadOnlyLock
                  ? Icon(Icons.lock_outline, size: 16, color: AppColors.gray400)
                  : null),
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusMD,
          ),
          filled: readOnly,
          fillColor: readOnly ? AppColors.gray50 : null,
        ),
      ),
    );
  }

  Widget _buildProfileProgress() {
    final user = ref.watch(authProvider).user;
    final kycState = ref.watch(kycProvider);

    // Hide entirely while KYC status is being fetched — prevents flash of progress bar
    if (kycState.isLoading) return const SizedBox.shrink();

    // Build list of missing items (5 real checks; serviceRadius always has a value)
    final missing = <({String label, IconData icon, VoidCallback? onTap})>[];

    if (user?.name?.isNotEmpty != true)
      missing.add((label: 'Imię i nazwisko', icon: Icons.person_outline, onTap: null));
    if (user?.address?.isNotEmpty != true)
      missing.add((label: 'Adres zamieszkania', icon: Icons.home_outlined, onTap: null));
    if (_bioController.text.isEmpty)
      missing.add((label: 'Opis (o mnie)', icon: Icons.description_outlined, onTap: null));
    if (_selectedCategories.isEmpty)
      missing.add((label: 'Kategorie usług', icon: Icons.category_outlined, onTap: null));
    if (!kycState.selfieVerified)
      missing.add((
        label: 'Weryfikacja tożsamości (ID + selfie)',
        icon: Icons.badge_outlined,
        onTap: () => context.push(Routes.contractorKyc),
      ));

    // All done — verified badge shown under photo instead
    if (missing.isEmpty) return const SizedBox.shrink();

    const total = 5;
    final completed = total - missing.length;
    final percent = (completed / total * 100).toInt();

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uzupełnij profil', style: AppTypography.h4),
              Text(
                '$percent%',
                style: AppTypography.h3.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          LinearProgressIndicator(
            value: completed / total,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation(AppColors.warning),
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            'Brakuje:',
            style: AppTypography.caption.copyWith(color: AppColors.gray600),
          ),
          SizedBox(height: AppSpacing.gapXS),
          ...missing.map(
            (item) => InkWell(
              onTap: item.onTap,
              borderRadius: AppRadius.radiusSM,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(item.icon, size: 14, color: AppColors.gray600),
                    SizedBox(width: AppSpacing.gapSM),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                    if (item.onTap != null)
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletShortcut() {
    final credits = ref.watch(creditsProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
        title: Text('Portfel', style: AppTypography.bodyMedium),
        subtitle: Text(
          '${credits.balance.toStringAsFixed(2)} zł',
          style: AppTypography.caption.copyWith(
            color: credits.balance >= 10 ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.gray400),
        onTap: () => context.push(Routes.contractorWallet),
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
            'Kategorie usług:',
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
