import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Bottom navigation item data
class SFBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const SFBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Custom bottom navigation bar for Szybka Fucha
class SFBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SFBottomNavItem> items;

  const SFBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Predefined items for client role
  static List<SFBottomNavItem> get clientItems => [
        SFBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Start',
        ),
        SFBottomNavItem(
          icon: Icons.list_alt_outlined,
          activeIcon: Icons.list_alt_rounded,
          label: 'Zlecenia',
        ),
        SFBottomNavItem(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: 'Wiadomości',
        ),
        SFBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
        ),
      ];

  /// Predefined items for contractor role
  static List<SFBottomNavItem> get contractorItems => [
        SFBottomNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Panel',
        ),
        SFBottomNavItem(
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          label: 'Zlecenia',
        ),
        SFBottomNavItem(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: 'Wiadomości',
        ),
        SFBottomNavItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: 'Zarobki',
        ),
        SFBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingSM,
            vertical: AppSpacing.paddingXS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _NavItem(
                icon: isSelected ? item.activeIcon : item.icon,
                label: item.label,
                isSelected: isSelected,
                onTap: () => onTap(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingSM,
          vertical: AppSpacing.paddingXS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.gray400,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
