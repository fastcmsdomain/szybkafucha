import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Phone login screen
/// User enters their phone number to receive OTP
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
          AppStrings.phoneNumber,
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.space4),

                // Instructions
                Text(
                  'Podaj swój numer telefonu, a wyślemy Ci kod weryfikacyjny',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSpacing.space8),

                // Phone input
                _buildPhoneInput(),

                SizedBox(height: AppSpacing.space4),

                // Privacy note
                Text(
                  'Twój numer będzie używany wyłącznie do weryfikacji i kontaktu w sprawie zleceń',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Send code button
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
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
                          AppStrings.sendCode,
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
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          // Country code
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMD,
              vertical: AppSpacing.paddingMD,
            ),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '🇵🇱',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  '+48',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Phone number input
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
                _PhoneNumberFormatter(),
              ],
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: '123 456 789',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.gray400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingMD,
                  vertical: AppSpacing.paddingMD,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Wprowadź numer telefonu';
                }
                final digitsOnly = value.replaceAll(' ', '');
                if (digitsOnly.length != 9) {
                  return 'Numer musi mieć 9 cyfr';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = '+48${_phoneController.text.replaceAll(' ', '')}';

      // TODO: Call API to send OTP
      // await ref.read(authProvider.notifier).requestPhoneOtp(phone);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Navigate to OTP screen with phone number
        context.push(
          Routes.phoneOtp,
          extra: phone,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Formats phone number as: 123 456 789
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
