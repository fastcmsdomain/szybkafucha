import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rating_stars.dart';

/// Contractor-only editable profile screen
class ContractorProfileScreen extends ConsumerStatefulWidget {
  const ContractorProfileScreen({super.key});

  @override
  ConsumerState<ContractorProfileScreen> createState() =>
      _ContractorProfileScreenState();
}

class _ContractorReview {
  final String id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? fromUserName;
  final String? fromUserAvatarUrl;

  const _ContractorReview({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    this.fromUserName,
    this.fromUserAvatarUrl,
  });

  factory _ContractorReview.fromJson(Map<String, dynamic> json) {
    return _ContractorReview(
      id: json['id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      fromUserName: json['fromUserName'] as String?,
      fromUserAvatarUrl:
          ApiConfig.getFullMediaUrl(json['fromUserAvatarUrl'] as String?),
    );
  }
}

class _ContractorProfileScreenState
    extends ConsumerState<ContractorProfileScreen> {
  final DateFormat _reviewDateFormat = DateFormat('dd.MM.yyyy', 'pl_PL');

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  // Contractor profile data for ratings
  double? _ratingAvg;
  int? _ratingCount;
  bool _isLoadingProfile = true;
  bool _isLoadingReviews = true;
  List<_ContractorReview> _reviews = const [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _loadContractorData();
  }

  Future<void> _loadContractorData() async {
    await Future.wait([
      _loadContractorProfile(),
      _loadContractorReviews(),
    ]);
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

  Future<void> _loadContractorReviews() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/contractor/profile/ratings');
      final data = response.data as List<dynamic>;

      if (mounted) {
        setState(() {
          _reviews = data
              .whereType<Map<String, dynamic>>()
              .map(_ContractorReview.fromJson)
              .toList();
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contractor ratings: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
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
      final payload = <String, dynamic>{};
      final name = _nameController.text.trim();
      if (name.isNotEmpty) payload['name'] = name;

      payload['phone'] = _phoneController.text.trim();
      payload['address'] = _addressController.text.trim();
      payload['bio'] = _bioController.text.trim();

      await api.put('/users/me', data: payload);

      // Refresh user data in authProvider to update local state
      await ref.read(authProvider.notifier).refreshUser();

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mój profil'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profil'),
              Tab(text: 'Oceny'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(),
            _buildRatingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = ref.watch(authProvider).user;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    final reviewCount = _ratingCount ?? _reviews.length;

    return RefreshIndicator(
      onRefresh: _loadContractorData,
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        children: [
          Container(
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
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Row(
                    children: [
                      SFRatingStars(
                        rating: rating,
                        size: 22,
                        showValue: true,
                      ),
                      SizedBox(width: AppSpacing.gapSM),
                      Text(
                        '$reviewCount opinii',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
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
          ),
          SizedBox(height: AppSpacing.gapMD),
          if (_isLoadingReviews)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (_reviews.isEmpty)
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: AppRadius.radiusMD,
                border: Border.all(color: AppColors.gray200),
              ),
              child: Text(
                'Brak opinii do wyświetlenia.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            )
          else
            ..._reviews.map(_buildReviewCard),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_ContractorReview review) {
    final reviewerInitial =
        (review.fromUserName?.trim().isNotEmpty == true ? review.fromUserName! : 'U')[0]
            .toUpperCase();
    final comment = review.comment?.trim();

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.gapSM),
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gray200,
                backgroundImage: review.fromUserAvatarUrl != null
                    ? NetworkImage(review.fromUserAvatarUrl!)
                    : null,
                child: review.fromUserAvatarUrl == null
                    ? Text(
                        reviewerInitial,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray700,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: AppSpacing.gapSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.fromUserName ?? 'Użytkownik',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              SFRatingStars(
                rating: review.rating.toDouble(),
                size: 18,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            (comment?.isNotEmpty == true) ? comment! : 'Brak komentarza.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray700,
              fontStyle: (comment?.isNotEmpty == true)
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    return _reviewDateFormat.format(date.toLocal());
  }
}
