/// Route paths for Szybka Fucha app
abstract class Routes {
  // Auth routes
  static const String welcome = '/';
  static const String publicHome = '/home';
  static const String termsOfService = '/legal/terms';
  static const String privacyPolicy = '/legal/privacy';
  static const String onboarding = '/onboarding';
  static const String browse = '/browse';
  static const String login = '/login';
  static const String phoneLogin = '/login/phone';
  static const String phoneOtp = '/login/phone/otp';
  static const String emailLogin = '/login/email';
  static const String emailRegister = '/register/email';
  static const String emailVerify = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';

  // Client routes
  static const String clientHome = '/client';
  static const String clientCategories = '/client/categories';
  static const String clientCreateTask = '/client/task/create';
  static const String clientSelectContractor = '/client/task/select-contractor';
  static const String clientPayment = '/client/task/payment';
  static const String clientTaskDetails = '/client/task/:taskId';
  static const String clientTaskTracking = '/client/task/:taskId/tracking';
  static const String clientTaskChat = '/client/task/:taskId/chat';
  static const String clientTaskRating = '/client/task/:taskId/rating';
  static const String clientTaskCompletion = '/client/task/:taskId/complete';
  static const String clientHistory = '/client/history';
  static const String clientProfile = '/client/profile';
  static const String clientProfileHelp = '/client/profile/help';
  static const String clientProfileEdit = '/client/profile/edit';
  static const String clientReviews = '/client/reviews';
  static const String clientTasks = '/client/tasks';

  // Contractor routes
  static const String contractorHome = '/contractor';
  static const String contractorRegistration = '/contractor/register';
  static const String contractorKyc = '/contractor/kyc';
  static const String contractorTaskList = '/contractor/tasks';
  static const String contractorTaskAlert = '/contractor/task/:taskId/alert';
  static const String contractorTaskDetails = '/contractor/task/:taskId';
  static const String contractorTaskNavigation =
      '/contractor/task/:taskId/navigation';
  static const String contractorTaskChat = '/contractor/task/:taskId/chat';
  static const String contractorTaskComplete =
      '/contractor/task/:taskId/complete';
  static const String contractorTaskReview = '/contractor/task/:taskId/review';
  static const String contractorProfileEdit = '/contractor/profile/edit';
  static const String contractorProfileHelp = '/contractor/profile/help';
  static const String contractorEarnings = '/contractor/earnings';
  static const String contractorProfile = '/contractor/profile';
  static const String contractorReviews = '/contractor/reviews';
  static const String contractorMyApplications = '/contractor/applications';
  static const String contractorTaskHistory = '/contractor/history';

  // Common routes
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Helper methods for dynamic routes
  static String clientTask(String taskId) => '/client/task/$taskId';
  static String clientTaskTrack(String taskId) =>
      '/client/task/$taskId/tracking';
  static String clientTaskChatRoute(String taskId) =>
      '/client/task/$taskId/chat';
  static String clientTaskRate(String taskId) => '/client/task/$taskId/rating';
  static String clientTaskComplete(String taskId) =>
      '/client/task/$taskId/complete';

  static String contractorTask(String taskId) => '/contractor/task/$taskId';
  static String contractorTaskAlertRoute(String taskId) =>
      '/contractor/task/$taskId/alert';
  static String contractorTaskNav(String taskId) =>
      '/contractor/task/$taskId/navigation';
  static String contractorTaskChatRoute(String taskId) =>
      '/contractor/task/$taskId/chat';
  static String contractorTaskCompleteRoute(String taskId) =>
      '/contractor/task/$taskId/complete';
  static String contractorTaskReviewRoute(String taskId) =>
      '/contractor/task/$taskId/review';
}
