import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';

/// Secure storage provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
