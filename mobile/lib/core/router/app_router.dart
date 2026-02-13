import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth.dart';
import '../../features/chat/screens/screens.dart' as chat;
import '../../features/client/client.dart';
import '../../features/client/screens/client_profile_screen.dart';
import '../../features/contractor/models/contractor_task.dart';
import '../../features/contractor/screens/screens.dart' as contractor;
import '../../features/profile/profile.dart';
import '../providers/auth_provider.dart';
import 'routes.dart';

// Placeholder screens for features not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - Coming Soon')),
    );
  }
}

/// App router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthStateNotifier(ref);

  return GoRouter(
    initialLocation: Routes.publicHome,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Read current auth state from notifier (not captured variable)
      final isLoading = authNotifier.isLoading;
      final isAuthenticated = authNotifier.isAuthenticated;
      final onboardingComplete = authNotifier.onboardingComplete;

      final isAuthRoute = state.matchedLocation == Routes.welcome ||
          state.matchedLocation == Routes.login ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation == Routes.forgotPassword;
      final isProfileTabRoute = state.matchedLocation == Routes.welcome &&
          state.uri.queryParameters['tab'] == 'profile';

      // emailVerify is NOT an auth route — it must stay accessible
      // after registration (before activateSession is called)
      final isEmailVerifyRoute =
          state.matchedLocation == Routes.emailVerify;

      final isOnboardingRoute = state.matchedLocation == Routes.onboarding;
      final isBrowseRoute = state.matchedLocation == Routes.browse;
      final isPublicHomeRoute = state.matchedLocation == Routes.publicHome;
      final isLegalRoute = state.matchedLocation == Routes.termsOfService ||
          state.matchedLocation == Routes.privacyPolicy;

      // Debug logging
      print('🔍 Router redirect check:');
      print('  - Location: ${state.matchedLocation}');
      print('  - Loading: $isLoading');
      print('  - Authenticated: $isAuthenticated');
      print('  - Onboarding complete: $onboardingComplete');

      // While checking auth state, stay on current route
      if (isLoading) return null;

      // === AUTHENTICATED USERS ===
      // Always redirect to home (skip onboarding/browse)
      if (isAuthenticated) {
        // Allow email verification screen for authenticated users
        if (isEmailVerifyRoute) return null;

        // If on auth, onboarding, or browse route → redirect to home
        if (isAuthRoute || isOnboardingRoute || isBrowseRoute || isPublicHomeRoute) {
          final user = authNotifier.user;
          final destination = user?.isContractor == true
              ? Routes.contractorHome
              : Routes.clientHome;
          print('  ✅ Authenticated → redirecting to $destination');
          return destination;
        }
        // Already on valid route
        return null;
      }

      // === NOT AUTHENTICATED ===

      // First time user → show onboarding
      if (!onboardingComplete) {
        if (!isOnboardingRoute) {
          print('  ✅ No onboarding → redirecting to onboarding');
          return Routes.onboarding;
        }
        // Already on onboarding, allow it
        print('  ✅ On onboarding screen, allow');
        return null;
      }

      // Onboarding complete but not logged in
      // Plain "/" should behave as Home tab, not login/profile view.
      if (state.matchedLocation == Routes.welcome && !isProfileTabRoute) {
        print('  ✅ Root without profile tab → redirecting to public home');
        return Routes.publicHome;
      }

      // Allow /browse, auth routes, and email verify (so users can log in / verify)
      if (isBrowseRoute ||
          isAuthRoute ||
          isEmailVerifyRoute ||
          isPublicHomeRoute ||
          isLegalRoute) {
        print('  ✅ On browse or auth route, allow');
        return null;
      }

      // Everything else → redirect to browse
      print('  ✅ Onboarding done, not on browse/auth → redirecting to browse');
      return Routes.browse;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.browse,
        name: 'browse',
        builder: (context, state) => const PublicBrowseScreen(),
      ),
      GoRoute(
        path: Routes.publicHome,
        name: 'publicHome',
        builder: (context, state) => const PublicHomeScreen(),
      ),
      GoRoute(
        path: Routes.termsOfService,
        name: 'termsOfService',
        builder: (context, state) => const LegalDocumentScreen(
          title: 'Regulamin',
          assetPath: 'assets/legal/terms_of_service.txt',
        ),
      ),
      GoRoute(
        path: Routes.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const LegalDocumentScreen(
          title: 'Polityka prywatności',
          assetPath: 'assets/legal/privacy_policy.txt',
        ),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.phoneLogin,
        name: 'phoneLogin',
        builder: (context, state) {
          final userType = state.extra as String? ?? 'client';
          return PhoneLoginScreen(userType: userType);
        },
      ),
      GoRoute(
        path: Routes.phoneOtp,
        name: 'phoneOtp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phoneNumber = extra['phone'] as String? ?? '';
          final userType = extra['userType'] as String? ?? 'client';
          return OtpScreen(
            phoneNumber: phoneNumber,
            userType: userType,
          );
        },
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.emailLogin,
        name: 'emailLogin',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: Routes.emailRegister,
        name: 'emailRegister',
        builder: (context, state) => const EmailRegisterScreen(),
      ),
      GoRoute(
        path: Routes.emailVerify,
        name: 'emailVerify',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Client routes with shell for bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return _ClientShell(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.clientHome,
            name: 'clientHome',
            builder: (context, state) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: Routes.clientTasks,
            name: 'clientTasks',
            builder: (context, state) => const ClientTaskListScreen(),
          ),
          GoRoute(
            path: Routes.clientCategories,
            name: 'clientCategories',
            builder: (context, state) => const CategorySelectionScreen(),
          ),
          GoRoute(
            path: Routes.clientHistory,
            name: 'clientHistory',
            builder: (context, state) => const TaskHistoryScreen(),
          ),
          GoRoute(
            path: Routes.clientProfile,
            name: 'clientProfile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: Routes.clientProfileEdit,
            name: 'clientProfileEdit',
            builder: (context, state) => const ClientProfileScreen(),
          ),
          GoRoute(
            path: Routes.clientReviews,
            name: 'clientReviews',
            builder: (context, state) =>
                const ClientReviewsScreen(),
          ),
          // Task routes inside shell - bottom nav always visible
          GoRoute(
            path: Routes.clientCreateTask,
            name: 'clientCreateTask',
            builder: (context, state) {
              final category = state.extra as TaskCategory?;
              return CreateTaskScreen(initialCategory: category);
            },
          ),
          GoRoute(
            path: Routes.clientSelectContractor,
            name: 'clientSelectContractor',
            builder: (context, state) {
              final data = state.extra as ContractorSelectionData?;
              return ContractorSelectionScreen(taskData: data);
            },
          ),
          GoRoute(
            path: Routes.clientPayment,
            name: 'clientPayment',
            builder: (context, state) {
              final data = state.extra as PaymentData?;
              return PaymentScreen(paymentData: data);
            },
          ),
          GoRoute(
            path: Routes.clientTaskDetails,
            name: 'clientTaskDetails',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return PlaceholderScreen(title: 'Task $taskId');
            },
          ),
          GoRoute(
            path: Routes.clientTaskTracking,
            name: 'clientTaskTracking',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return TaskTrackingScreen(taskId: taskId);
            },
          ),
          GoRoute(
            path: Routes.clientTaskChat,
            name: 'clientTaskChat',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return PlaceholderScreen(title: 'Chat $taskId');
            },
          ),
          GoRoute(
            path: Routes.clientTaskRating,
            name: 'clientTaskRating',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return PlaceholderScreen(title: 'Rate $taskId');
            },
          ),
          GoRoute(
            path: Routes.clientTaskCompletion,
            name: 'clientTaskCompletion',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return TaskCompletionScreen(taskId: taskId);
            },
          ),
        ],
      ),

      // Contractor routes with shell for bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return _ContractorShell(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.contractorHome,
            name: 'contractorHome',
            builder: (context, state) => const contractor.ContractorHomeScreen(),
          ),
          GoRoute(
            path: Routes.contractorTaskList,
            name: 'contractorTaskList',
            builder: (context, state) =>
                const contractor.ContractorTaskListScreen(),
          ),
          GoRoute(
            path: Routes.contractorEarnings,
            name: 'contractorEarnings',
            builder: (context, state) => const contractor.EarningsScreen(),
          ),
          GoRoute(
            path: Routes.contractorProfile,
            name: 'contractorProfile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: Routes.contractorProfileEdit,
            name: 'contractorProfileEdit',
            builder: (context, state) => const contractor.ContractorProfileScreen(),
          ),
          GoRoute(
            path: Routes.contractorReviews,
            name: 'contractorReviews',
            builder: (context, state) =>
                const contractor.ContractorReviewsScreen(),
          ),
          // Task routes inside shell - bottom nav always visible
          GoRoute(
            path: Routes.contractorTaskAlert,
            name: 'contractorTaskAlert',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final task = state.extra as ContractorTask?;
              return contractor.TaskAlertScreen(taskId: taskId, task: task);
            },
          ),
          GoRoute(
            path: Routes.contractorTaskDetails,
            name: 'contractorTaskDetails',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return contractor.ActiveTaskScreen(taskId: taskId);
            },
          ),
          GoRoute(
            path: Routes.contractorTaskNavigation,
            name: 'contractorTaskNavigation',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return PlaceholderScreen(title: 'Navigation $taskId');
            },
          ),
          GoRoute(
            path: Routes.contractorTaskChat,
            name: 'contractorTaskChat',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return chat.ChatScreen(
                taskId: taskId,
                taskTitle: extra?['taskTitle'] ?? 'Czat',
                otherUserName: extra?['otherUserName'] ?? 'Unknown',
                otherUserAvatarUrl: extra?['otherUserAvatarUrl'],
                currentUserId: extra?['currentUserId'] ?? 'user_id',
                currentUserName: extra?['currentUserName'] ?? 'User',
              );
            },
          ),
          GoRoute(
            path: Routes.contractorTaskComplete,
            name: 'contractorTaskComplete',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final task = state.extra as ContractorTask?;
              return contractor.TaskCompletionScreen(taskId: taskId, task: task);
            },
          ),
          GoRoute(
            path: Routes.contractorTaskReview,
            name: 'contractorTaskReview',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return contractor.ReviewClientScreen(
                taskId: taskId,
                clientName: extra?['clientName'] as String?,
                earnings: extra?['earnings'] as int?,
              );
            },
          ),
        ],
      ),

      // Contractor registration and KYC (outside shell - one-time screens)
      GoRoute(
        path: Routes.contractorRegistration,
        name: 'contractorRegistration',
        redirect: (context, state) => Routes.contractorProfileEdit, // Redirect to profile edit
      ),
      GoRoute(
        path: Routes.contractorKyc,
        name: 'contractorKyc',
        builder: (context, state) => const contractor.KycVerificationScreen(),
      ),

      // Common routes
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Notifications'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Notifier to refresh router when auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      print('🔄 _AuthStateNotifier: Auth state changed, notifying listeners');
      notifyListeners();
    });
  }

  final Ref _ref;

  // Expose current auth state properties (reads from provider each time)
  bool get isLoading => _ref.read(authProvider).isLoading;
  bool get isAuthenticated => _ref.read(authProvider).isAuthenticated;
  bool get onboardingComplete => _ref.read(authProvider).onboardingComplete;
  User? get user => _ref.read(authProvider).user;
}

/// Client bottom navigation shell
class _ClientShell extends StatelessWidget {
  final Widget child;
  const _ClientShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Główna',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Zlecenia',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historia',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.clientTasks)) return 1;
    if (location.startsWith(Routes.clientHistory)) return 2;
    if (location.startsWith(Routes.clientProfile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.clientHome);
        return;
      case 1:
        context.go(Routes.clientTasks);
        return;
      case 2:
        context.go(Routes.clientHistory);
        return;
      case 3:
        context.go(Routes.clientProfile);
        return;
    }
  }
}

/// Contractor bottom navigation shell
class _ContractorShell extends StatelessWidget {
  final Widget child;
  const _ContractorShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Główna',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Zlecenia',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Zarobki',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.contractorTaskList)) return 1;
    if (location.startsWith(Routes.contractorEarnings)) return 2;
    if (location.startsWith(Routes.contractorProfile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.contractorHome);
        return;
      case 1:
        context.go(Routes.contractorTaskList);
        return;
      case 2:
        context.go(Routes.contractorEarnings);
        return;
      case 3:
        context.go(Routes.contractorProfile);
        return;
    }
  }
}
