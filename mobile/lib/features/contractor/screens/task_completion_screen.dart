import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';

/// Task completion screen for contractors - submit photo proof and complete task
class TaskCompletionScreen extends ConsumerStatefulWidget {
  final String taskId;
  final ContractorTask? task;

  const TaskCompletionScreen({
    super.key,
    required this.taskId,
    this.task,
  });

  @override
  ConsumerState<TaskCompletionScreen> createState() =>
      _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends ConsumerState<TaskCompletionScreen> {
  final List<File> _photos = [];
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Mock task - in production this would come from provider or extra
  late ContractorTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task ?? ContractorTask.mockActiveTask();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Navigate back safely - use go() if nothing to pop
  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.contractorHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = TaskCategoryData.fromCategory(_task.category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
        title: Text(
          'Zakończ zlecenie',
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task summary card
            _buildTaskSummary(categoryData),

            SizedBox(height: AppSpacing.space6),

            // Earnings breakdown
            _buildEarningsBreakdown(),

            SizedBox(height: AppSpacing.space6),

            // Photo proof section
            _buildPhotoProofSection(),

            SizedBox(height: AppSpacing.space6),

            // Notes section
            _buildNotesSection(),

            SizedBox(height: AppSpacing.space8),

            // Submit button
            _buildSubmitButton(),

            SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSummary(TaskCategoryData categoryData) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingSM),
            decoration: BoxDecoration(
              color: categoryData.color.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
            ),
            child: Icon(categoryData.icon, color: categoryData.color),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryData.name,
                  style: AppTypography.labelLarge,
                ),
                SizedBox(height: 2),
                Text(
                  _task.clientName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdown() {
    final platformFee = (_task.price * 0.17).round();
    final earnings = _task.price - platformFee;

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusXL,
      ),
      child: Column(
        children: [
          Text(
            'Twój zarobek',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            '$earnings zł',
            style: AppTypography.h1.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.gapLG),
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: AppRadius.radiusMD,
            ),
            child: Column(
              children: [
                _buildEarningsRow('Wartość zlecenia', '${_task.price} zł'),
                SizedBox(height: AppSpacing.gapSM),
                _buildEarningsRow('Prowizja platformy (17%)', '-$platformFee zł'),
                Divider(
                  color: AppColors.white.withValues(alpha: 0.3),
                  height: AppSpacing.gapLG,
                ),
                _buildEarningsRow('Do wypłaty', '$earnings zł', isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.9),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.white,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt, size: 20, color: AppColors.gray700),
            SizedBox(width: AppSpacing.gapSM),
            Text(
              'Zdjęcie wykonanej pracy',
              style: AppTypography.labelLarge,
            ),
            SizedBox(width: AppSpacing.gapSM),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingSM,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: AppRadius.radiusSM,
              ),
              child: Text(
                'Opcjonalne',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapSM),
        Text(
          'Dodaj zdjęcia jako potwierdzenie wykonania zlecenia',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
        ),
        SizedBox(height: AppSpacing.gapMD),

        // Photo grid
        Wrap(
          spacing: AppSpacing.gapMD,
          runSpacing: AppSpacing.gapMD,
          children: [
            ..._photos.asMap().entries.map((entry) {
              return _buildPhotoTile(entry.value, entry.key);
            }),
            if (_photos.length < 4) _buildAddPhotoTile(),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoTile(File photo, int index) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMD,
            image: DecorationImage(
              image: FileImage(photo),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.gray900.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.radiusMD,
          border: Border.all(
            color: AppColors.gray300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: AppColors.gray500),
            SizedBox(height: 4),
            Text(
              'Dodaj',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_alt_outlined, size: 20, color: AppColors.gray700),
            SizedBox(width: AppSpacing.gapSM),
            Text(
              'Notatki',
              style: AppTypography.labelLarge,
            ),
            SizedBox(width: AppSpacing.gapSM),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingSM,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: AppRadius.radiusSM,
              ),
              child: Text(
                'Opcjonalne',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Dodatkowe informacje o wykonanym zleceniu...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray400,
            ),
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
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitCompletion,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusLG,
          ),
          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.5),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: AppSpacing.gapSM),
                  Text(
                    'Potwierdź zakończenie',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Zrób zdjęcie'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Wybierz z galerii'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      // Handle camera permission error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie można uzyskać dostępu do aparatu'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      // Handle gallery permission error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie można uzyskać dostępu do galerii'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitCompletion() async {
    setState(() => _isSubmitting = true);

    try {
      // Call API to complete task
      // Note: Photo upload would require separate implementation (e.g., multipart upload)
      // For MVP, we just complete the task without photo URLs
      await ref.read(activeTaskProvider.notifier).completeTask(
        widget.taskId,
        photos: null, // Photos would need to be uploaded first and URLs passed here
      );

      // Clear active task from provider
      ref.read(activeTaskProvider.notifier).clearTask();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _buildSuccessDialog(dialogContext),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zakończenia zlecenia: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildSuccessDialog(BuildContext dialogContext) {
    final platformFee = (_task.price * 0.17).round();
    final earnings = _task.price - platformFee;

    return Dialog(
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
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: AppSpacing.gapLG),
            Text(
              'Zlecenie zakończone!',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Zarobiłeś $earnings zł',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Środki zostaną przelane na Twoje konto',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.gapXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Use dialogContext to pop the dialog, then navigate
                  Navigator.of(dialogContext).pop();
                  // Navigate to review client screen using dialogContext
                  dialogContext.go(
                    Routes.contractorTaskReviewRoute(widget.taskId),
                    extra: {
                      'clientName': _task.clientName,
                      'earnings': earnings,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMD,
                  ),
                ),
                child: const Text('Oceń klienta'),
              ),
            ),
            SizedBox(height: AppSpacing.gapMD),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                dialogContext.go(Routes.contractorHome);
              },
              child: Text(
                'Pomiń ocenę',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wyjść bez zapisywania?'),
        content: const Text(
          'Zlecenie nie zostanie oznaczone jako zakończone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _navigateBack(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Wyjdź'),
          ),
        ],
      ),
    );
  }
}
