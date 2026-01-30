/// WebSocket Service
/// Manages Socket.io connections, events, and real-time communication
/// Includes dev mode mock implementation for offline testing

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/websocket_config.dart';

/// Callback type for event handlers
typedef EventCallback = void Function(dynamic data);

/// WebSocket connection states
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Real-time event data models
class LocationUpdateEvent {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationUpdateEvent({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationUpdateEvent.fromJson(Map<String, dynamic> json) {
    return LocationUpdateEvent(
      userId: json['userId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ChatMessageEvent {
  final String id;
  final String taskId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  ChatMessageEvent({
    required this.id,
    required this.taskId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return ChatMessageEvent(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'senderId': senderId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Contractor info received with task status updates
class ContractorInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final double rating;
  final int completedTasks;
  final String? bio;

  ContractorInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.completedTasks,
    this.bio,
  });

  factory ContractorInfo.fromJson(Map<String, dynamic> json) {
    return ContractorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'rating': rating,
    'completedTasks': completedTasks,
    'bio': bio,
  };
}

class TaskStatusEvent {
  final String taskId;
  final String status;
  final DateTime updatedAt;
  final String updatedBy;
  final ContractorInfo? contractor;

  TaskStatusEvent({
    required this.taskId,
    required this.status,
    required this.updatedAt,
    required this.updatedBy,
    this.contractor,
  });

  factory TaskStatusEvent.fromJson(Map<String, dynamic> json) {
    return TaskStatusEvent(
      taskId: json['taskId'] as String,
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      contractor: json['contractor'] != null
          ? ContractorInfo.fromJson(json['contractor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'status': status,
    'updatedAt': updatedAt.toIso8601String(),
    'updatedBy': updatedBy,
    if (contractor != null) 'contractor': contractor!.toJson(),
  };
}

class UserOnlineEvent {
  final String userId;
  final String userType; // 'client' | 'contractor'

  UserOnlineEvent({required this.userId, required this.userType});

  factory UserOnlineEvent.fromJson(Map<String, dynamic> json) {
    return UserOnlineEvent(
      userId: json['userId'] as String,
      userType: json['userType'] as String,
    );
  }
}

/// New task available event (sent to contractors)
class NewTaskEvent {
  final String id;
  final String category;
  final String title;
  final double budgetAmount;
  final String address;
  final double locationLat;
  final double locationLng;
  final DateTime createdAt;
  final double? score;
  final double? distance;

  NewTaskEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.budgetAmount,
    required this.address,
    required this.locationLat,
    required this.locationLng,
    required this.createdAt,
    this.score,
    this.distance,
  });

  factory NewTaskEvent.fromJson(Map<String, dynamic> json) {
    // Task data may be nested under 'task' key
    final taskData = json['task'] as Map<String, dynamic>? ?? json;

    return NewTaskEvent(
      id: taskData['id'] as String,
      category: taskData['category'] as String,
      title: taskData['title'] as String,
      budgetAmount: (taskData['budgetAmount'] as num).toDouble(),
      address: taskData['address'] as String,
      locationLat: (taskData['locationLat'] as num).toDouble(),
      locationLng: (taskData['locationLng'] as num).toDouble(),
      createdAt: taskData['createdAt'] is String
          ? DateTime.parse(taskData['createdAt'] as String)
          : DateTime.now(),
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      distance:
          json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'budgetAmount': budgetAmount,
        'address': address,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'createdAt': createdAt.toIso8601String(),
        if (score != null) 'score': score,
        if (distance != null) 'distance': distance,
      };
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  late IO.Socket _socket;
  WebSocketState _state = WebSocketState.disconnected;
  String? _jwtToken;
  int _reconnectAttempts = 0;
  Timer? _mockTimer;

  // Event listeners
  final Map<String, List<EventCallback>> _listeners =
      <String, List<EventCallback>>{};

  // Stream controllers for state changes
  late StreamController<WebSocketState> _stateController;

  /// Current connection state
  WebSocketState get state => _state;

  /// Stream of connection state changes
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// Is currently connected
  bool get isConnected => _state == WebSocketState.connected;

  /// Initialize WebSocket service with JWT token
  Future<void> connect(String jwtToken) async {
    _stateController = StreamController<WebSocketState>.broadcast();
    _jwtToken = jwtToken;

    // Use mock implementation in dev mode
    if (WebSocketConfig.devModeEnabled && kDebugMode) {
      _initializeDevMode();
      return;
    }

    await _connectReal(jwtToken);
  }

  /// Real WebSocket connection
  Future<void> _connectReal(String jwtToken) async {
    if (_state == WebSocketState.connecting || _state == WebSocketState.connected) {
      return;
    }

    _updateState(WebSocketState.connecting);

    try {
      final connectionParams = <String, dynamic>{
        ...WebSocketConfig.connectionParams,
        'token': jwtToken,
      };

      _socket = IO.io(
        WebSocketConfig.fullUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setQuery(connectionParams)
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(
                WebSocketConfig.reconnectConfig['reconnectionDelay'] as int)
            .setReconnectionDelayMax(
                WebSocketConfig.reconnectConfig['reconnectionDelayMax'] as int)
            .setReconnectionAttempts(
                WebSocketConfig.reconnectConfig['reconnectionAttempts'] as int)
            .build(),
      );

      // Connection established
      _socket.on('connect', (_) {
        _reconnectAttempts = 0;
        _updateState(WebSocketState.connected);
        _notifyListeners('connected', null);
      });

      // Connection error
      _socket.on('connect_error', (error) {
        _updateState(WebSocketState.error);
        _notifyListeners('error', {'message': error.toString()});
      });

      // Reconnecting
      _socket.on('reconnect_attempt', (_) {
        _reconnectAttempts++;
        _updateState(WebSocketState.reconnecting);
      });

      // Disconnected
      _socket.on('disconnect', (_) {
        _updateState(WebSocketState.disconnected);
        _notifyListeners('disconnected', null);
      });

      // Server error events
      _socket.on(WebSocketConfig.error, (data) {
        _notifyListeners('error', data);
      });

      // Real-time events
      _socket.on(WebSocketConfig.locationUpdate, (data) {
        try {
          final event = LocationUpdateEvent.fromJson(data as Map<String, dynamic>);
          _notifyListeners(WebSocketConfig.locationUpdate, event);
        } catch (e) {
          _notifyListeners('error', {'message': 'Failed to parse location update: $e'});
        }
      });

      _socket.on(WebSocketConfig.messageNew, (data) {
        try {
          final event = ChatMessageEvent.fromJson(data as Map<String, dynamic>);
          _notifyListeners(WebSocketConfig.messageNew, event);
        } catch (e) {
          _notifyListeners('error', {'message': 'Failed to parse message: $e'});
        }
      });

      _socket.on(WebSocketConfig.messageRead, (data) {
        _notifyListeners(WebSocketConfig.messageRead, data);
      });

      _socket.on(WebSocketConfig.taskStatus, (data) {
        try {
          final event = TaskStatusEvent.fromJson(data as Map<String, dynamic>);
          _notifyListeners(WebSocketConfig.taskStatus, event);
        } catch (e) {
          _notifyListeners('error', {'message': 'Failed to parse task status: $e'});
        }
      });

      _socket.on(WebSocketConfig.userOnline, (data) {
        try {
          final event = UserOnlineEvent.fromJson(data as Map<String, dynamic>);
          _notifyListeners(WebSocketConfig.userOnline, event);
        } catch (e) {
          _notifyListeners('error', {'message': 'Failed to parse user online: $e'});
        }
      });

      _socket.on(WebSocketConfig.userOffline, (data) {
        try {
          final event = UserOnlineEvent.fromJson(data as Map<String, dynamic>);
          _notifyListeners(WebSocketConfig.userOffline, event);
        } catch (e) {
          _notifyListeners('error', {'message': 'Failed to parse user offline: $e'});
        }
      });

      // New task available for contractors
      _socket.on(WebSocketConfig.taskNewAvailable, (data) {
        try {
          final event = NewTaskEvent.fromJson(data as Map<String, dynamic>);
          _notifyListeners(WebSocketConfig.taskNewAvailable, event);
          debugPrint('📢 New task available: ${event.title} (${event.distance?.toStringAsFixed(1)}km)');
        } catch (e) {
          _notifyListeners('error', {'message': 'Failed to parse new task: $e'});
        }
      });
    } catch (e) {
      _updateState(WebSocketState.error);
      _notifyListeners('error', {'message': 'Connection failed: $e'});
      rethrow;
    }
  }

  /// Dev mode: Mock WebSocket without backend
  void _initializeDevMode() {
    _updateState(WebSocketState.connected);
    _notifyListeners('connected', null);

    final config = WebSocketConfig.devModeConfig;
    final simulateLocationUpdates =
        config['simulateLocationUpdates'] as bool? ?? true;
    final locationIntervalSeconds =
        config['locationUpdateIntervalSeconds'] as int? ?? 15;
    final simulateMessages = config['simulateIncomingMessages'] as bool? ?? true;
    final messageDelay = config['messageDelaySeconds'] as int? ?? 5;

    // Simulate location updates
    if (simulateLocationUpdates) {
      _mockTimer = Timer.periodic(
        Duration(seconds: locationIntervalSeconds),
        (_) {
          final random = Random();
          final latitude = 52.2297 + (random.nextDouble() - 0.5) * 0.01;
          final longitude = 21.0122 + (random.nextDouble() - 0.5) * 0.01;

          final event = LocationUpdateEvent(
            userId: 'mock_contractor_id',
            latitude: latitude,
            longitude: longitude,
            timestamp: DateTime.now(),
          );

          _notifyListeners(WebSocketConfig.locationUpdate, event);
        },
      );
    }

    // Simulate incoming messages
    if (simulateMessages) {
      Future.delayed(Duration(seconds: messageDelay), () {
        final messages = [
          'Już prawie tam!',
          'Jestem na miejscu',
          'Wszystko gotowe do pracy',
          'Czy masz jakieś specjalne instrukcje?',
          'Dziękuję za zlecenie!',
        ];
        final random = Random();
        final randomMessage = messages[random.nextInt(messages.length)];

        final event = ChatMessageEvent(
          id: 'mock_msg_${DateTime.now().millisecondsSinceEpoch}',
          taskId: 'mock_task_id',
          senderId: 'mock_contractor_id',
          content: randomMessage,
          createdAt: DateTime.now(),
        );

        _notifyListeners(WebSocketConfig.messageNew, event);
      });
    }
  }

  /// Send location update (contractor only)
  void emitLocationUpdate({
    required double latitude,
    required double longitude,
  }) {
    if (_state != WebSocketState.connected && !WebSocketConfig.devModeEnabled) {
      _notifyListeners('error', {'message': 'Not connected to WebSocket'});
      return;
    }

    if (!WebSocketConfig.devModeEnabled) {
      _socket.emit(WebSocketConfig.sendLocation, {
        'latitude': latitude,
        'longitude': longitude,
      });
    }

    // Emit locally for listeners
    final event = LocationUpdateEvent(
      userId: _jwtToken ?? 'unknown',
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
    _notifyListeners(WebSocketConfig.locationUpdate, event);
  }

  /// Join task room
  void joinTask(String taskId) {
    if (_state != WebSocketState.connected && !WebSocketConfig.devModeEnabled) {
      _notifyListeners('error', {'message': 'Not connected to WebSocket'});
      return;
    }

    if (!WebSocketConfig.devModeEnabled) {
      _socket.emit(WebSocketConfig.taskJoin, {'taskId': taskId});
    }
  }

  /// Leave task room
  void leaveTask(String taskId) {
    if (_state != WebSocketState.connected && !WebSocketConfig.devModeEnabled) {
      _notifyListeners('error', {'message': 'Not connected to WebSocket'});
      return;
    }

    if (!WebSocketConfig.devModeEnabled) {
      _socket.emit(WebSocketConfig.taskLeave, {'taskId': taskId});
    }
  }

  /// Send chat message
  void sendMessage({
    required String taskId,
    required String content,
  }) {
    if (_state != WebSocketState.connected && !WebSocketConfig.devModeEnabled) {
      _notifyListeners('error', {'message': 'Not connected to WebSocket'});
      return;
    }

    if (!WebSocketConfig.devModeEnabled) {
      _socket.emit(WebSocketConfig.sendMessage, {
        'taskId': taskId,
        'content': content,
      });
    }

    // Emit locally for listeners
    final event = ChatMessageEvent(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      senderId: _jwtToken ?? 'unknown',
      content: content,
      createdAt: DateTime.now(),
    );
    _notifyListeners(WebSocketConfig.messageNew, event);
  }

  /// Mark messages as read
  void markMessagesRead(String taskId) {
    if (_state != WebSocketState.connected && !WebSocketConfig.devModeEnabled) {
      _notifyListeners('error', {'message': 'Not connected to WebSocket'});
      return;
    }

    if (!WebSocketConfig.devModeEnabled) {
      _socket.emit(WebSocketConfig.markRead, {'taskId': taskId});
    }
  }

  /// Register event listener
  void on(String event, EventCallback callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  /// Remove event listener
  void off(String event, EventCallback callback) {
    _listeners[event]?.remove(callback);
  }

  /// Notify all listeners of an event
  void _notifyListeners(String event, dynamic data) {
    _listeners[event]?.forEach((callback) => callback(data));
  }

  /// Update connection state
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Disconnect WebSocket
  void disconnect() {
    if (WebSocketConfig.devModeEnabled) {
      _mockTimer?.cancel();
    } else {
      _socket.disconnect();
    }

    _updateState(WebSocketState.disconnected);
    _listeners.clear();
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _stateController.close();
  }
}
