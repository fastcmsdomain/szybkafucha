import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SzybkaFuchaApp(),
    ),
  );
}

class SzybkaFuchaApp extends StatelessWidget {
  const SzybkaFuchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Szybka Fucha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }
}

/// Temporary welcome screen to showcase design system
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.space12),

              // Logo placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.radiusMD,
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Szybka',
                          style: AppTypography.h3,
                        ),
                        TextSpan(
                          text: 'Fucha',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.space16),

              // Headline
              Text(
                'Pomoc jest bliżej niż myślisz',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.space4),

              Text(
                'Znajdź pomocnika do drobnych zadań w kilka minut',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),

              Spacer(),

              // Buttons preview
              ElevatedButton(
                onPressed: () {},
                child: Text('Szukam pomocy'),
              ),

              SizedBox(height: AppSpacing.gapMD),

              OutlinedButton(
                onPressed: () {},
                child: Text('Chcę pomagać i zarabiać'),
              ),

              SizedBox(height: AppSpacing.space8),

              // Footer
              Text(
                'Dołączając, akceptujesz Regulamin i Politykę Prywatności',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
