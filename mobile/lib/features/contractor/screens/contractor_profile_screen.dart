import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme.dart';

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

  // Contractor profile data for ratings
  double? _ratingAvg;
  int? _ratingCount;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _loadContractorProfile();
  }

  Future<void> _loadContractorProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/contractor/profile');
      final data = response.data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _ratingAvg = (data['ratingAvg'] as num?)?.toDouble();
          _ratingCount = data['ratingCount'] as int?;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contractor profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
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
      final payload = <String, dynamic>{};
      final name = _nameController.text.trim();
      if (name.isNotEmpty) payload['name'] = name;

      payload['phone'] = _phoneController.text.trim();
      payload['address'] = _addressController.text.trim();
      payload['bio'] = _bioController.text.trim();

      await api.put('/users/me', data: payload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil zapisany'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
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
                    child: user?.avatarUrl == null
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
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Zmiana zdjęcia w przygotowaniu'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
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

            _buildRatingsSection(),

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

  Widget _buildRatingsSection() {
    final user = ref.read(authProvider).user;
    final rating = _ratingAvg ?? 0.0;
    final reviews = _ratingCount ?? 0;

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
            'Oceny zleceniodawców',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.gapSM),
          if (_isLoadingProfile)
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              children: [
                Icon(Icons.star, color: AppColors.warning, size: 22),
                SizedBox(width: 6),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTypography.h4,
                ),
                SizedBox(width: 6),
                Text(
                  'na podstawie $reviews opinii',
                  style: AppTypography.caption.copyWith(color: AppColors.gray600),
                ),
              ],
            ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Opinie wkrótce dostępne do podglądu w aplikacji.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
          ),
          if (user?.isVerified == true) ...[
            SizedBox(height: AppSpacing.gapSM),
            Row(
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Zweryfikowany wykonawca',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
