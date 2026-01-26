import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';

/// Global API client provider
/// This is the single source of truth for the API client instance
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
