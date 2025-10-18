import 'package:flutter/foundation.dart';
import 'dart:async';
import 'chat_service.dart';

// Event types
enum ChatEventType {
  newMessage,
  userStatusChange,
  userStartedTyping,
  userStoppedTyping,
  messageSeenUpdate,
  messageReceived,
  messagesRead,
  forceLogout,
  invoiceUpdated,
}

// Event data structure
class ChatEvent {
  final ChatEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ChatEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Event listener interface
typedef ChatEventListener = void Function(ChatEvent event);

class ChatEventManager {
  static final ChatEventManager _instance = ChatEventManager._internal();
  factory ChatEventManager() => _instance;
  ChatEventManager._internal();

  final Map<ChatEventType, List<ChatEventListener>> _listeners = {};
  final ChatService _chatService = ChatService(); // Use singleton
  bool _isInitialized = false;
  Timer? _cleanupTimer;

  // Initialize the event manager
  void initialize() {
    if (_isInitialized) return;

    if (kDebugMode) {
      print('ChatEventManager: Initializing event manager');
    }

    // Set up socket event listeners
    _setupSocketListeners();

    // Start cleanup timer for typing indicators
    _startCleanupTimer();

    _isInitialized = true;
  }

  // Set up socket event listeners
  void _setupSocketListeners() {
    // New message events
    _chatService.addOnNewMessageListener((data) {
      _emitEvent(ChatEventType.newMessage, data);
    });

    // User status events
    _chatService.onUserStatusChange((data) {
      _emitEvent(ChatEventType.userStatusChange, data);
    });

    // Typing events
    _chatService.onUserStartedTyping((data) {
      _emitEvent(ChatEventType.userStartedTyping, data);
    });

    _chatService.onUserStoppedTyping((data) {
      _emitEvent(ChatEventType.userStoppedTyping, data);
    });

    // Message read events
    _chatService.onMessageSeenUpdate((data) {
      _emitEvent(ChatEventType.messageSeenUpdate, data);
    });

    _chatService.onMessageReceived((data) {
      _emitEvent(ChatEventType.messageReceived, data);
    });

    _chatService.onMessagesRead((data) {
      _emitEvent(ChatEventType.messagesRead, data);
    });

    // Other events
    _chatService.onForceLogout((data) {
      _emitEvent(ChatEventType.forceLogout, data);
    });

    _chatService.onInvoiceUpdated((data) {
      _emitEvent(ChatEventType.invoiceUpdated, data);
    });
  }

  // Emit an event to all registered listeners
  void _emitEvent(ChatEventType type, Map<String, dynamic> data) {
    final event = ChatEvent(type: type, data: data);

    if (kDebugMode) {
      print('ChatEventManager: Emitting event: $type');
      print('ChatEventManager: Event data: $data');
    }

    final listeners = _listeners[type];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(event);
        } catch (e) {
          if (kDebugMode) {
            print('ChatEventManager: Error in event listener: $e');
          }
        }
      }
    }
  }

  // Add event listener
  void addEventListener(ChatEventType type, ChatEventListener listener) {
    if (!_listeners.containsKey(type)) {
      _listeners[type] = [];
    }
    _listeners[type]!.add(listener);

    if (kDebugMode) {
      print('ChatEventManager: Added listener for event type: $type');
      print(
          'ChatEventManager: Total listeners for $type: ${_listeners[type]!.length}');
    }
  }

  // Remove event listener
  void removeEventListener(ChatEventType type, ChatEventListener listener) {
    final listeners = _listeners[type];
    if (listeners != null) {
      listeners.remove(listener);

      if (kDebugMode) {
        print('ChatEventManager: Removed listener for event type: $type');
        print(
            'ChatEventManager: Remaining listeners for $type: ${listeners.length}');
      }
    }
  }

  // Remove all listeners for a specific event type
  void removeAllListenersForType(ChatEventType type) {
    _listeners.remove(type);

    if (kDebugMode) {
      print('ChatEventManager: Removed all listeners for event type: $type');
    }
  }

  // Remove all listeners
  void removeAllListeners() {
    _listeners.clear();

    if (kDebugMode) {
      print('ChatEventManager: Removed all event listeners');
    }
  }

  // Start cleanup timer for typing indicators
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _cleanupStaleTypingIndicators();
    });
  }

  // Clean up stale typing indicators
  void _cleanupStaleTypingIndicators() {
    final now = DateTime.now();
    const staleThreshold =
        Duration(seconds: 30); // Consider typing stale after 30 seconds

    // This will be handled by individual providers that track typing timestamps
    if (kDebugMode) {
      print('ChatEventManager: Running typing indicator cleanup');
    }
  }

  // Get chat service instance
  ChatService get chatService => _chatService;

  // Check if event manager is initialized
  bool get isInitialized => _isInitialized;

  // Get debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'listenerCounts': _listeners.map(
          (type, listeners) => MapEntry(type.toString(), listeners.length)),
      'socketConnected': _chatService.isConnected,
    };
  }

  // Dispose resources
  void dispose() {
    if (kDebugMode) {
      print('ChatEventManager: Disposing event manager');
    }

    _cleanupTimer?.cancel();
    removeAllListeners();
    _isInitialized = false;
  }
}
