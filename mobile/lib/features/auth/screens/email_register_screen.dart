import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Email registration screen with password strength indicator
class EmailRegisterScreen extends ConsumerStatefulWidget {
  const EmailRegisterScreen({super.key});

  @override
  ConsumerState<EmailRegisterScreen> createState() =>
      _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends ConsumerState<EmailRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  late String _selectedUserType;

  @override
  void initState() {
    super.initState();
    _selectedUserType = ref.read(authProvider).selectedRole ?? 'client';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Password strength checks
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordController.text.contains(RegExp(r'[@$!%*?&#]'));

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecial) score++;
    return score;
  }

  String get _strengthLabel {
    if (_passwordController.text.isEmpty) return '';
    if (_strengthScore <= 2) return 'Słabe';
    if (_strengthScore <= 3) return 'Średnie';
    if (_strengthScore <= 4) return 'Dobre';
    return 'Silne';
  }

  Color get _strengthColor {
    if (_strengthScore <= 2) return AppColors.error;
    if (_strengthScore <= 3) return AppColors.warning;
    if (_strengthScore <= 4) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
            userType: _selectedUserType,
          );

      if (!mounted) return;

      // Navigate to email verification
      context.push(
        Routes.emailVerify,
        extra: _emailController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(String error) {
    if (error.contains('409') || error.contains('Conflict')) {
      return 'Konto z tym adresem email już istnieje';
    }
    if (error.contains('Network')) {
      return 'Brak połączenia z internetem';
    }
    return 'Wystąpił błąd. Spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Utwórz konto',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.gapSM),
                Text(
                  'Podaj swoje dane i wybierz rolę',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSpacing.paddingLG),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    margin: EdgeInsets.only(bottom: AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMD,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        SizedBox(width: AppSpacing.gapSM),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        if (_errorMessage!.contains('już istnieje'))
                          TextButton(
                            onPressed: () =>
                                context.push(Routes.emailLogin),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.gapSM,
                              ),
                            ),
                            child: Text(
                              'Zaloguj się',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Role selector
                Row(
                  children: [
                    Expanded(
                      child: _RegRoleBox(
                        selected: _selectedUserType == 'client',
                        icon: Icons.manage_search_outlined,
                        title: 'Pracodawca',
                        subtitle: 'Szukam pomocy',
                        onTap: () =>
                            setState(() => _selectedUserType = 'client'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.gapMD),
                    Expanded(
                      child: _RegRoleBox(
                        selected: _selectedUserType == 'contractor',
                        icon: Icons.handyman_outlined,
                        title: 'Wykonawca',
                        subtitle: 'Chcę pomagać',
                        onTap: () =>
                            setState(() => _selectedUserType = 'contractor'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.paddingLG),

                // Name field (optional)
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Imię i nazwisko (opcjonalnie)',
                    hintText: 'Jan Kowalski',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.paddingMD),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'jan@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj adres email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                        .hasMatch(value.trim())) {
                      return 'Podaj prawidłowy adres email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.paddingMD),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Hasło',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Podaj hasło';
                    }
                    if (value.length < 8) {
                      return 'Hasło musi mieć minimum 8 znaków';
                    }
                    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])')
                        .hasMatch(value)) {
                      return 'Hasło musi zawierać dużą i małą literę, cyfrę i znak specjalny';
                    }
                    return null;
                  },
                ),

                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.gapSM),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _strengthScore / 5,
                            backgroundColor: AppColors.gray200,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_strengthColor),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.gapSM),
                      Text(
                        _strengthLabel,
                        style: AppTypography.caption.copyWith(
                          color: _strengthColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.gapSM),

                  // Requirements checklist
                  _buildRequirement('Minimum 8 znaków', _hasMinLength),
                  _buildRequirement('Wielka litera (A-Z)', _hasUppercase),
                  _buildRequirement('Mała litera (a-z)', _hasLowercase),
                  _buildRequirement('Cyfra (0-9)', _hasDigit),
                  _buildRequirement(
                      'Znak specjalny (@\$!%*?&#)', _hasSpecial),
                ],

                SizedBox(height: AppSpacing.paddingMD),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Potwierdź hasło',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Hasła nie są identyczne';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.space8),

                // Register button
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _register,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMD,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'Zarejestruj się',
                            style: AppTypography.buttonMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: AppSpacing.paddingMD),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Masz już konto? ',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    Semantics(
                      label: 'Zaloguj się',
                      button: true,
                      child: GestureDetector(
                        onTap: () => context.push(Routes.emailLogin),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapSM),
                          child: Text(
                            'Zaloguj się',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.paddingLG),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gapXS),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? AppColors.success : AppColors.gray400,
          ),
          SizedBox(width: AppSpacing.gapSM),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: met ? AppColors.success : AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegRoleBox extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RegRoleBox({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title — $subtitle',
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.paddingLG,
            horizontal: AppSpacing.paddingMD,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.gray100,
            borderRadius: AppRadius.radiusMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.white : AppColors.gray700,
              ),
              const SizedBox(height: AppSpacing.gapSM),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.gray700,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.gapXS),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
