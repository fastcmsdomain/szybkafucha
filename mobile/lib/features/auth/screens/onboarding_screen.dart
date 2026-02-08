import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    print('🎯 Completing onboarding...');
    await ref.read(authProvider.notifier).markOnboardingComplete();
    print('✅ Onboarding marked as complete');
    print('📍 Current auth state onboardingComplete: ${ref.read(authProvider).onboardingComplete}');

    // Use microtask to ensure navigation happens AFTER state update is fully processed
    if (mounted) {
      Future.microtask(() {
        if (mounted) {
          print('🚀 Navigating to browse via microtask');
          context.go(Routes.browse);
        }
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < 2)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                AppStrings.onboardingSkip,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  _OnboardingPageWithVideo(
                    title: AppStrings.onboardingTitle1,
                    subtitle: AppStrings.onboardingSubtitle1,
                    description: AppStrings.onboardingDescription1,
                    videoPath: 'assets/videos/SzybkaFuchaHero.mp4',
                  ),
                  _OnboardingPage(
                    icon: Icons.verified_user,
                    title: AppStrings.onboardingTitle2,
                    subtitle: AppStrings.onboardingSubtitle2,
                    description: AppStrings.onboardingDescription2,
                  ),
                  _OnboardingPage(
                    icon: Icons.bolt,
                    title: AppStrings.onboardingTitle3,
                    subtitle: AppStrings.onboardingSubtitle3,
                    description: AppStrings.onboardingDescription3,
                  ),
                ],
              ),
            ),
            _buildDotIndicators(),
            const SizedBox(height: 24),
            _buildNextButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _currentPage < 2
                ? AppStrings.onboardingNext
                : AppStrings.onboardingStart,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: AppColors.primary,
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageWithVideo extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final String videoPath;

  const _OnboardingPageWithVideo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.videoPath,
  });

  @override
  State<_OnboardingPageWithVideo> createState() => _OnboardingPageWithVideoState();
}

class _OnboardingPageWithVideoState extends State<_OnboardingPageWithVideo> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.videoPath);
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('❌ Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.subtitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Video player
          if (_isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const SizedBox(height: 32),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
