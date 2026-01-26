/// WebSocket Provider
/// Riverpod state management for real-time connections

import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../config/websocket_config.dart';

/// WebSocket service singleton provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

/// WebSocket connection state provider
final webSocketStateProvider = StreamProvider<WebSocketState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.stateStream;
});

/// Check if WebSocket is connected
final webSocketConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(webSocketStateProvider);
  return state.whenData((s) => s == WebSocketState.connected).maybeWhen(
        data: (isConnected) => isConnected,
        orElse: () => false,
      );
});

/// Location updates stream
final locationUpdatesProvider = StreamProvider<LocationUpdateEvent>((ref) async* {
  final service = ref.watch(webSocketServiceProvider);
  final controller = StreamController<LocationUpdateEvent>();

  void onLocationUpdate(dynamic data) {
    if (data is LocationUpdateEvent) {
      controller.add(data);
    }
  }

  service.on(WebSocketConfig.locationUpdate, onLocationUpdate);

  try {
    yield* controller.stream;
  } finally {
    service.off(WebSocketConfig.locationUpdate, onLocationUpdate);
    controller.close();
  }
});

/// Chat messages stream
final chatMessagesProvider = StreamProvider<ChatMessageEvent>((ref) async* {
  final service = ref.watch(webSocketServiceProvider);
  final controller = StreamController<ChatMessageEvent>();

  void onNewMessage(dynamic data) {
    if (data is ChatMessageEvent) {
      controller.add(data);
    }
  }

  service.on(WebSocketConfig.messageNew, onNewMessage);

  try {
    yield* controller.stream;
  } finally {
    service.off(WebSocketConfig.messageNew, onNewMessage);
    controller.close();
  }
});

/// Task status updates stream
final taskStatusUpdatesProvider = StreamProvider<TaskStatusEvent>((ref) async* {
  final service = ref.watch(webSocketServiceProvider);
  final controller = StreamController<TaskStatusEvent>();

  void onStatusUpdate(dynamic data) {
    if (data is TaskStatusEvent) {
      controller.add(data);
    }
  }

  service.on(WebSocketConfig.taskStatus, onStatusUpdate);

  try {
    yield* controller.stream;
  } finally {
    service.off(WebSocketConfig.taskStatus, onStatusUpdate);
    controller.close();
  }
});

/// New task available stream (for contractors)
final newTaskAvailableProvider = StreamProvider<NewTaskEvent>((ref) async* {
  final service = ref.watch(webSocketServiceProvider);
  final controller = StreamController<NewTaskEvent>();

  void onNewTask(dynamic data) {
    if (data is NewTaskEvent) {
      controller.add(data);
    }
  }

  service.on(WebSocketConfig.taskNewAvailable, onNewTask);

  try {
    yield* controller.stream;
  } finally {
    service.off(WebSocketConfig.taskNewAvailable, onNewTask);
    controller.close();
  }
});

/// User online/offline events stream
final userPresenceProvider = StreamProvider<UserOnlineEvent>((ref) async* {
  final service = ref.watch(webSocketServiceProvider);
  final onlineController = StreamController<UserOnlineEvent>();
  final offlineController = StreamController<UserOnlineEvent>();

  void onUserOnline(dynamic data) {
    if (data is UserOnlineEvent) {
      onlineController.add(data);
    }
  }

  void onUserOffline(dynamic data) {
    if (data is UserOnlineEvent) {
      offlineController.add(data);
    }
  }

  service.on(WebSocketConfig.userOnline, onUserOnline);
  service.on(WebSocketConfig.userOffline, onUserOffline);

  try {
    yield* StreamGroup.merge([onlineController.stream, offlineController.stream]);
  } finally {
    service.off(WebSocketConfig.userOnline, onUserOnline);
    service.off(WebSocketConfig.userOffline, onUserOffline);
    onlineController.close();
    offlineController.close();
  }
});

// Note: WebSocket initialization is now handled by WebSocketInitializer widget
// which automatically connects/disconnects based on auth state
