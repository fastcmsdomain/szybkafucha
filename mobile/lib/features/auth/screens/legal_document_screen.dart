import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.paddingLG),
                child: Text(
                  'Nie udało się wczytać dokumentu.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final content = snapshot.data ?? '';
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.paddingLG),
              child: SelectableText(
                content,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray700,
                  height: 1.7,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
