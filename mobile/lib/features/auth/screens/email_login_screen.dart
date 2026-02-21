import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Email login screen
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .loginWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Navigation handled by router redirect
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
    if (error.contains('401')) {
      return 'Nieprawidłowy email lub hasło';
    }
    if (error.contains('423') || error.contains('LOCKED')) {
      return 'Konto tymczasowo zablokowane. Spróbuj ponownie później.';
    }
    if (error.contains('Network')) {
      return 'Brak połączenia z internetem';
    }
    return 'Wystąpił błąd. Spróbuj ponownie.';
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: AppSpacing.space8),
        Text(
          'Zaloguj się',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.gapSM),
        Text(
          'Podaj swój email i hasło',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      margin: EdgeInsets.only(bottom: AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          SizedBox(width: AppSpacing.gapSM),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'jan@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Podaj adres email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
          return 'Podaj prawidłowy adres email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: 'Hasło',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? 'Pokaż hasło' : 'Ukryj hasło',
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Podaj hasło';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordLink(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.push(Routes.forgotPassword),
        child: Text(
          'Zapomniałeś hasła?',
          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
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
                'Zaloguj się',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nie masz konta? ',
          style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
        ),
        TextButton(
          onPressed: () => context.push(Routes.emailRegister),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Zarejestruj się',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie'),
        backgroundColor: AppColors.transparent,
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
                _buildHeader(),
                SizedBox(height: AppSpacing.space8),
                _buildErrorMessage(),
                _buildEmailField(),
                SizedBox(height: AppSpacing.paddingMD),
                _buildPasswordField(),
                _buildForgotPasswordLink(context),
                SizedBox(height: AppSpacing.paddingMD),
                _buildLoginButton(),
                SizedBox(height: AppSpacing.paddingLG),
                _buildRegisterLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
