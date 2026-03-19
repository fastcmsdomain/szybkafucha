import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// OTP verification screen
/// User enters the 6-digit code sent to their phone
class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String userType;
  final bool linkMode;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.userType = 'client',
    this.linkMode = false,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;
  late String _selectedUserType;
  String? _errorMessage;
  int _attemptsLeft = 4;
  bool _attemptLimitReached = false;

  @override
  void initState() {
    super.initState();
    _selectedUserType = widget.userType;
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _errorMessage = null;
      _attemptsLeft = 4;
      _attemptLimitReached = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.linkMode
              ? 'Potwierdź numer telefonu'
              : AppStrings.verificationCode,
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.space4),

              // Instructions
              Text(
                widget.linkMode
                    ? 'Wpisz 6-cyfrowy kod SMS, aby potwierdzić numer telefonu'
                    : 'Wpisz 6-cyfrowy kod wysłany na numer',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.gapSM),

              // Phone number
              Text(
                widget.phoneNumber,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.space8),

              // OTP input boxes
              _buildOtpInputs(),

              if (_errorMessage != null) ...[
                SizedBox(height: AppSpacing.gapSM),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: AppSpacing.gapSM),
              Text(
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

              SizedBox(height: AppSpacing.space8),

              // Resend code
              _buildResendButton(),

              const Spacer(),

              // Verify button
              ElevatedButton(
                onPressed: _isLoading || _attemptLimitReached
                    ? null
                    : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(
                        'Weryfikuj',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
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
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              }
              if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              // Auto-submit when all filled
              if (!_attemptLimitReached && _getOtp().length == 6) {
                _verifyCode();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _resendCountdown == 0 ? _resendCode : null,
      child: Text(
        _resendCountdown > 0
            ? '${AppStrings.resendCodeIn} ${_resendCountdown}s'
            : AppStrings.resendCode,
        style: AppTypography.bodyMedium.copyWith(
          color: _resendCountdown > 0 ? AppColors.gray400 : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final otp = _getOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wprowadź pełny 6-cyfrowy kod'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_attemptLimitReached) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.linkMode) {
        await ref
            .read(authProvider.notifier)
            .verifyPhoneLinkOtp(phone: widget.phoneNumber, otp: otp);

        if (!mounted) return;
        final user = ref.read(authProvider).user;
        final profileRoute = user?.isContractor == true
            ? Routes.contractorProfile
            : Routes.clientProfile;
        context.go(profileRoute);
      } else {
        await ref
            .read(authProvider.notifier)
            .verifyPhoneOtp(
              phone: widget.phoneNumber,
              otp: otp,
              userType: _selectedUserType,
            );
      }

      // Navigation is handled by auth state change in router
    } catch (e) {
      if (mounted) {
        final feedback = _mapOtpError(e);
        setState(() {
          _errorMessage = feedback.message;
          if (feedback.attemptsLeft != null) {
            _attemptsLeft = feedback.attemptsLeft!;
          }
          _attemptLimitReached = feedback.locked;
        });
        // Clear OTP inputs
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      if (widget.linkMode) {
        await ref
            .read(authProvider.notifier)
            .requestPhoneLinkOtp(widget.phoneNumber);
      } else {
        await ref
            .read(authProvider.notifier)
            .requestPhoneOtp(widget.phoneNumber);
      }
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.codeSent),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się wysłać kodu. Spróbuj ponownie.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        locked: code == 'OTP_ATTEMPTS_EXCEEDED' || attemptsLeft == 0,
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
