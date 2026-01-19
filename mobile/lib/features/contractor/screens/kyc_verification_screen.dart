import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/theme.dart';

/// KYC Verification screen for contractors - ID document, selfie, and bank account
class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() =>
      _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  File? _idFront;
  File? _idBack;
  File? _selfie;
  final _ibanController = TextEditingController();
  final _accountHolderController = TextEditingController();

  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _ibanController.dispose();
    _accountHolderController.dispose();
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
          'Weryfikacja tożsamości',
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress steps
          _buildStepIndicator(),

          // Step content
          Expanded(
            child: _buildCurrentStep(),
          ),

          // Navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      _KycStep('Dokument', Icons.badge_outlined),
      _KycStep('Selfie', Icons.face),
      _KycStep('Konto', Icons.account_balance),
    ];

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.primary
                                : AppColors.gray200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        size: 20,
                        color: isCompleted || isCurrent
                            ? AppColors.white
                            : AppColors.gray500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      step.label,
                      style: AppTypography.caption.copyWith(
                        color: isCurrent
                            ? AppColors.primary
                            : isCompleted
                                ? AppColors.gray700
                                : AppColors.gray400,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 20,
                      ),
                      color: isCompleted ? AppColors.success : AppColors.gray200,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildDocumentStep();
      case 1:
        return _buildSelfieStep();
      case 2:
        return _buildBankAccountStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokument tożsamości',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Zrób zdjęcie dowodu osobistego lub paszportu',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapXL),

          // Front of ID
          Text(
            'Przód dokumentu',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.gapMD),
          _buildDocumentUploader(
            file: _idFront,
            placeholder: 'Przód dowodu',
            icon: Icons.credit_card,
            onTap: () => _captureDocument(true),
          ),

          SizedBox(height: AppSpacing.gapLG),

          // Back of ID
          Text(
            'Tył dokumentu',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.gapMD),
          _buildDocumentUploader(
            file: _idBack,
            placeholder: 'Tył dowodu',
            icon: Icons.credit_card,
            onTap: () => _captureDocument(false),
          ),

          SizedBox(height: AppSpacing.gapXL),

          // Tips
          _buildTipsCard([
            'Upewnij się, że dokument jest dobrze oświetlony',
            'Wszystkie dane muszą być czytelne',
            'Nie używaj zdjęć dokumentu',
            'Akceptujemy dowód osobisty lub paszport',
          ]),
        ],
      ),
    );
  }

  Widget _buildDocumentUploader({
    required File? file,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: file != null ? null : AppColors.gray100,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: file != null ? AppColors.success : AppColors.gray300,
            width: file != null ? 2 : 1,
            style: file != null ? BorderStyle.solid : BorderStyle.solid,
          ),
          image: file != null
              ? DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: AppColors.gray500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  Text(
                    placeholder,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Zrób zdjęcie',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingSM,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray900.withValues(alpha: 0.7),
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 14,
                              color: AppColors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Zmień',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zdjęcie selfie',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Zrób zdjęcie swojej twarzy do weryfikacji',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapXL),

          // Selfie capture
          Center(
            child: GestureDetector(
              onTap: _captureSelfie,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: _selfie != null ? null : AppColors.gray100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selfie != null ? AppColors.success : AppColors.gray300,
                    width: _selfie != null ? 3 : 2,
                  ),
                  image: _selfie != null
                      ? DecorationImage(
                          image: FileImage(_selfie!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selfie == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.face,
                            size: 64,
                            color: AppColors.gray400,
                          ),
                          SizedBox(height: AppSpacing.gapMD),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Zrób selfie',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 24,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          if (_selfie != null) ...[
            SizedBox(height: AppSpacing.gapMD),
            Center(
              child: TextButton.icon(
                onPressed: _captureSelfie,
                icon: Icon(Icons.refresh),
                label: Text('Zrób ponownie'),
              ),
            ),
          ],

          SizedBox(height: AppSpacing.gapXL),

          // Tips
          _buildTipsCard([
            'Upewnij się, że twarz jest dobrze widoczna',
            'Zdejmij okulary przeciwsłoneczne i nakrycie głowy',
            'Zdjęcie robimy bez filtrów',
            'Dobre oświetlenie zwiększa szanse akceptacji',
          ]),
        ],
      ),
    );
  }

  Widget _buildBankAccountStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dane do wypłat',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Podaj numer konta, na które będziemy przelewać Twoje zarobki',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapXL),

          // IBAN field
          Text(
            'Numer konta (IBAN)',
            style: AppTypography.labelMedium,
          ),
          SizedBox(height: AppSpacing.gapSM),
          TextFormField(
            controller: _ibanController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'PL00 0000 0000 0000 0000 0000 0000',
              prefixIcon: Icon(Icons.account_balance, color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.gapLG),

          // Account holder name
          Text(
            'Imię i nazwisko właściciela konta',
            style: AppTypography.labelMedium,
          ),
          SizedBox(height: AppSpacing.gapSM),
          TextFormField(
            controller: _accountHolderController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Jan Kowalski',
              prefixIcon: Icon(Icons.person, color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.gapXL),

          // Security info
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.success,
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Twoje dane są bezpieczne',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'Korzystamy z szyfrowania end-to-end i nie udostępniamy danych osobom trzecim.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List<String> tips) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.accent,
              ),
              SizedBox(width: 8),
              Text(
                'Wskazówki',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          ...tips.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canProceed = _canProceed();

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                    side: BorderSide(color: AppColors.gray300),
                  ),
                  child: const Text('Wstecz'),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: AppSpacing.gapMD),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: _isSubmitting || !canProceed
                    ? null
                    : (_currentStep < 2 ? _nextStep : _submitVerification),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMD,
                  ),
                  disabledBackgroundColor: AppColors.gray300,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(
                        _currentStep < 2 ? 'Dalej' : 'Wyślij do weryfikacji',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _idFront != null && _idBack != null;
      case 1:
        return _selfie != null;
      case 2:
        return _ibanController.text.isNotEmpty &&
            _accountHolderController.text.isNotEmpty;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _captureDocument(bool isFront) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _idFront = File(image.path);
          } else {
            _idBack = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nie można uzyskać dostępu do aparatu'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() => _selfie = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nie można uzyskać dostępu do aparatu'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Show pending verification screen
      _showVerificationPendingDialog();
    }
  }

  void _showVerificationPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusXL,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.paddingLG),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top,
                  size: 64,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(height: AppSpacing.gapLG),
              Text(
                'Weryfikacja w toku',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.gapSM),
              Text(
                'Twoje dokumenty zostały wysłane do weryfikacji. Proces może potrwać do 24 godzin.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.gapMD),
              Container(
                padding: EdgeInsets.all(AppSpacing.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: AppRadius.radiusMD,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                    Expanded(
                      child: Text(
                        'Powiadomimy Cię gdy weryfikacja zostanie zakończona.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.gapXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/contractor');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  child: const Text('Rozumiem'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycStep {
  final String label;
  final IconData icon;

  _KycStep(this.label, this.icon);
}
