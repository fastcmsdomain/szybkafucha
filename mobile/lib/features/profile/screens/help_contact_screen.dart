import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';

class HelpContactScreen extends ConsumerStatefulWidget {
  const HelpContactScreen({super.key});

  @override
  ConsumerState<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends ConsumerState<HelpContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final userName = ref.read(authProvider).user?.name?.trim() ?? '';
    _nameController = TextEditingController(text: userName);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/support/contact',
        data: {
          'name': _nameController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      if (!mounted) return;

      final successMessage =
          response['message'] as String? ??
          'Wiadomość wysłana. Odezwiemy się do Ciebie w ciągu 48 godzin.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );

      _messageController.clear();
      FocusScope.of(context).unfocus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _mapErrorMessage(Object error) {
    if (error is ValidationException) {
      return error.message;
    }
    if (error is ApiException) {
      return error.message;
    }
    return 'Nie udało się wysłać wiadomości. Spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomoc')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Skontaktuj się z nami', style: AppTypography.h4),
                SizedBox(height: AppSpacing.gapSM),
                Text(
                  'Opisz problem lub pytanie. Odpowiadamy zwykle w ciągu 48 godzin.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
                SizedBox(height: AppSpacing.paddingLG),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Imię',
                    hintText: 'Twoje imię',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.length < 2) {
                      return 'Wpisz imię (min. 2 znaki).';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.paddingMD),
                TextFormField(
                  controller: _messageController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 8,
                  maxLines: 14,
                  decoration: InputDecoration(
                    labelText: 'Treść wiadomości',
                    hintText: 'Opisz swój problem...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.length < 10) {
                      return 'Wiadomość musi mieć minimum 10 znaków.';
                    }
                    if (trimmed.length > 5000) {
                      return 'Wiadomość może mieć maksymalnie 5000 znaków.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.paddingLG),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _submit,
                  icon: _isSending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_isSending ? 'Wysyłanie...' : 'Wyślij'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
