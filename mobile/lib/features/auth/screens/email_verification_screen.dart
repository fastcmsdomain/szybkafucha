import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';

/// Email verification screen with OTP input
/// Reuses the same OTP pattern as phone verification
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  int _attemptsLeft = 4;
  bool _attemptLimitReached = false;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _attemptsLeft = 4;
      _attemptLimitReached = false;
      _errorMessage = null;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6) return;
    if (_attemptLimitReached) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .verifyEmail(email: widget.email, code: _code);

      if (!mounted) return;

      // Show success, activate session, then go to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email zweryfikowany pomyślnie!'),
          backgroundColor: Colors.green,
        ),
      );
      await ref.read(authProvider.notifier).activateSession();
    } catch (e) {
      if (!mounted) return;
      final feedback = _mapOtpError(e);
      setState(() {
        _errorMessage = feedback.message;
        if (feedback.attemptsLeft != null) {
          _attemptsLeft = feedback.attemptsLeft!;
        }
        _attemptLimitReached = feedback.locked;
        // Clear inputs
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      await ref
          .read(authProvider.notifier)
          .resendEmailVerification(widget.email);

      if (!mounted) return;
      _startResendTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nowy kod został wysłany')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się wysłać kodu'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weryfikacja email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.space8),

              // Icon
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: AppColors.primary,
              ),

              SizedBox(height: AppSpacing.paddingLG),

              Text(
                'Weryfikacja adresu email',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.gapSM),
              Text(
                'Wysłaliśmy kod weryfikacyjny na',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                widget.email,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.space8),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.paddingMD),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.paddingMD),
                child: Text(
                  _attemptLimitReached
                      ? _resendCountdown > 0
                            ? 'Limit prób wykorzystany. Poczekaj ${_resendCountdown}s lub wyślij nowy kod.'
                            : 'Limit prób wykorzystany. Wyślij nowy kod.'
                      : 'Pozostałe próby: $_attemptsLeft',
                  style: AppTypography.bodySmall.copyWith(
                    color: _attemptLimitReached
                        ? AppColors.warning
                        : AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // OTP input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_attemptLimitReached,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      maxLength: 1,
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        // Auto-submit when all 6 digits entered
                        if (!_attemptLimitReached && _code.length == 6) {
                          _verify();
                        }
                      },
                    ),
                  );
                }),
              ),

              SizedBox(height: AppSpacing.paddingLG),

              // Verify button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                      _isLoading || _code.length != 6 || _attemptLimitReached
                      ? null
                      : _verify,
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
                          'Zweryfikuj',
                          style: AppTypography.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: AppSpacing.paddingLG),

              // Resend code
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Wyślij ponownie za ${_resendCountdown}s',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray400,
                        ),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resendCode,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Wyślij kod ponownie',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
              ),

              const Spacer(),

              // Skip link
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).activateSession();
                  },
                  child: Text(
                    'Zweryfikuj później',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _OtpErrorFeedback _mapOtpError(Object error) {
    if (error is ValidationException) {
      final data = error.data;
      final attemptsLeft = data is Map<String, dynamic>
          ? data['attemptsLeft'] as int?
          : null;
      final code = data is Map<String, dynamic>
          ? data['code'] as String?
          : null;

      return _OtpErrorFeedback(
        message: error.message,
        attemptsLeft: attemptsLeft,
        locked: code == 'EMAIL_OTP_ATTEMPTS_EXCEEDED' || attemptsLeft == 0,
      );
    }

    if (error is ApiException) {
      return _OtpErrorFeedback(message: error.message);
    }

    return const _OtpErrorFeedback(
      message: 'Nie udało się zweryfikować kodu. Spróbuj ponownie.',
    );
  }
}

class _OtpErrorFeedback {
  final String message;
  final int? attemptsLeft;
  final bool locked;

  const _OtpErrorFeedback({
    required this.message,
    this.attemptsLeft,
    this.locked = false,
  });
}
