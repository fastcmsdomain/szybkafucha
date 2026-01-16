import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/theme.dart';

/// Avatar sizes
enum SFAvatarSize { small, medium, large, xlarge }

/// User avatar with optional online indicator
class SFAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final SFAvatarSize size;
  final bool isOnline;
  final VoidCallback? onTap;

  const SFAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = SFAvatarSize.medium,
    this.isOnline = false,
    this.onTap,
  });

  double get _size => switch (size) {
        SFAvatarSize.small => 32,
        SFAvatarSize.medium => 48,
        SFAvatarSize.large => 64,
        SFAvatarSize.xlarge => 96,
      };

  double get _fontSize => switch (size) {
        SFAvatarSize.small => 12,
        SFAvatarSize.medium => 16,
        SFAvatarSize.large => 24,
        SFAvatarSize.xlarge => 36,
      };

  double get _indicatorSize => switch (size) {
        SFAvatarSize.small => 10,
        SFAvatarSize.medium => 14,
        SFAvatarSize.large => 18,
        SFAvatarSize.xlarge => 24,
      };

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: imageUrl == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    )
                  : null,
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildInitials(),
                    ),
                  )
                : _buildInitials(),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _indicatorSize,
                height: _indicatorSize,
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
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.gray200,
      child: Center(
        child: SizedBox(
          width: _size * 0.4,
          height: _size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gray400,
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
