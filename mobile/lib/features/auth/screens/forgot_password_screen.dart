import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Forgot password screen - request reset OTP, enter code, set new password
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _successMessage;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _requestReset() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .requestPasswordReset(_emailController.text.trim());

      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _successMessage = 'Kod został wysłany na podany adres email';
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nie udało się wysłać kodu. Spróbuj ponownie.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    if (_otpCode.length != 6) {
      setState(() => _errorMessage = 'Podaj 6-cyfrowy kod');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: _emailController.text.trim(),
            code: _otpCode,
            newPassword: _newPasswordController.text,
          );

      if (!mounted) return;

      // Show success and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasło zostało zmienione. Zaloguj się nowym hasłem.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(Routes.emailLogin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nieprawidłowy kod lub hasło nie spełnia wymagań';
        // Clear OTP
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset hasła'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: _codeSent ? _buildResetForm() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.space8),

          Icon(
            Icons.lock_reset,
            size: 64,
            color: AppColors.primary,
          ),

          SizedBox(height: AppSpacing.paddingLG),

          Text(
            'Zapomniałeś hasła?',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Podaj adres email, na który wyślemy kod do resetowania hasła.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppSpacing.space8),

          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              margin: EdgeInsets.only(bottom: AppSpacing.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestReset(),
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
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                return 'Podaj prawidłowy adres email';
              }
              return null;
            },
          ),

          SizedBox(height: AppSpacing.paddingLG),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _requestReset,
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
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Wyślij kod resetujący',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          SizedBox(height: AppSpacing.paddingMD),

          Center(
            child: TextButton(
              onPressed: () => context.push(Routes.emailLogin),
              child: Text(
                'Wróć do logowania',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.paddingLG),

          Text(
            'Zmień hasło',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Podaj kod z emaila i nowe hasło',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppSpacing.paddingLG),

          // Status messages
          if (_successMessage != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              margin: EdgeInsets.only(bottom: AppSpacing.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Text(
                _successMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              margin: EdgeInsets.only(bottom: AppSpacing.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // OTP input
          Text(
            'Kod weryfikacyjny',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 48,
                height: 56,
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: AppTypography.h5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),

          // Resend code
          Align(
            alignment: Alignment.centerRight,
            child: _resendCountdown > 0
                ? Padding(
                    padding: EdgeInsets.only(top: AppSpacing.gapSM),
                    child: Text(
                      'Wyślij ponownie za ${_resendCountdown}s',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _requestReset,
                    child: Text(
                      'Wyślij kod ponownie',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),

          SizedBox(height: AppSpacing.paddingLG),

          // New password
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nowe hasło',
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
                return 'Podaj nowe hasło';
              }
              if (value.length < 8) {
                return 'Hasło musi mieć minimum 8 znaków';
              }
              if (!RegExp(
                      r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])')
                  .hasMatch(value)) {
                return 'Hasło musi zawierać dużą i małą literę, cyfrę i znak specjalny';
              }
              return null;
            },
          ),

          SizedBox(height: AppSpacing.paddingMD),

          // Confirm password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Potwierdź nowe hasło',
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
              if (value != _newPasswordController.text) {
                return 'Hasła nie są identyczne';
              }
              return null;
            },
          ),

          SizedBox(height: AppSpacing.space8),

          // Reset button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _resetPassword,
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
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Zmień hasło',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
