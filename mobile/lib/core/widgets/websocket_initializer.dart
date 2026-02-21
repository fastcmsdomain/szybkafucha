/// WebSocket Initializer Widget
/// Connects/disconnects WebSocket based on authentication state

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/unread_messages_provider.dart';
import '../providers/websocket_provider.dart';
import '../services/websocket_service.dart';

/// Widget that manages WebSocket connection lifecycle based on auth state
/// Wrap your app with this widget to automatically connect/disconnect WebSocket
class WebSocketInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const WebSocketInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<WebSocketInitializer> createState() =>
      _WebSocketInitializerState();
}

class _WebSocketInitializerState extends ConsumerState<WebSocketInitializer> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Eagerly initialize unread messages provider so it registers its
    // WebSocket listener before any chat badge widget is rendered.
    ref.read(unreadMessagesProvider);
    // Check auth state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndConnect();
    });
  }

  void _checkAuthAndConnect() {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.token != null) {
      _connectWebSocket(authState.token!);
    }
  }

  Future<void> _connectWebSocket(String token) async {
    if (_isConnected) return;

    try {
      final wsService = ref.read(webSocketServiceProvider);
      await wsService.connect(token);
      _isConnected = true;
      debugPrint('✅ WebSocket connected with JWT token');
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
    }
  }

  void _disconnectWebSocket() {
    if (!_isConnected) return;

    try {
      final wsService = ref.read(webSocketServiceProvider);
      wsService.disconnect();
      _isConnected = false;
      debugPrint('🔌 WebSocket disconnected');
    } catch (e) {
      debugPrint('❌ WebSocket disconnect error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      final isAuthenticated = next.isAuthenticated;

      // User just logged in
      if (!wasAuthenticated && isAuthenticated && next.token != null) {
        _connectWebSocket(next.token!);
      }

      // User just logged out
      if (wasAuthenticated && !isAuthenticated) {
        _disconnectWebSocket();
      }

      // Token was refreshed (user still authenticated but token changed)
      if (wasAuthenticated &&
          isAuthenticated &&
          previous?.token != null &&
          next.token != null &&
          previous!.token != next.token) {
        debugPrint('🔄 Token refreshed, reconnecting WebSocket...');
        _disconnectWebSocket();
        _connectWebSocket(next.token!);
      }
    });

    return widget.child;
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    super.dispose();
  }
}

/// Provider to check if WebSocket is initialized and connected
final webSocketInitializedProvider = Provider<bool>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return wsService.isConnected;
});
