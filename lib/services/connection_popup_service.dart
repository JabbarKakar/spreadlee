import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import '../presentation/resources/color_manager.dart';
import '../presentation/resources/style_manager.dart';
import '../core/constant.dart';
import 'connection_monitor_service.dart';
import 'socket_service.dart';
import 'chat_service.dart';

/// Service to handle connection-related popups (internet and socket)
/// Provides a clean, centralized way to show connection status popups
class ConnectionPopupService {
  static final ConnectionPopupService _instance =
      ConnectionPopupService._internal();
  factory ConnectionPopupService() => _instance;
  ConnectionPopupService._internal();

  BuildContext? _currentContext;
  bool _isShowingPopup = false;
  String? _currentPopupType;

  // References to connection services for retry functionality
  ConnectionMonitorService? _connectionMonitor;
  SocketService? _socketService;
  ChatService? _chatService;

  /// Initialize with the current context
  void initialize(BuildContext context) {
    _currentContext = context;

    if (kDebugMode) {
      print('ConnectionPopupService: Initialized with context');
    }
  }

  /// Set connection services for retry functionality
  void setConnectionServices(
      ConnectionMonitorService connectionMonitor, SocketService socketService) {
    _connectionMonitor = connectionMonitor;
    _socketService = socketService;
    _chatService = ChatService();

    if (kDebugMode) {
      print('ConnectionPopupService: Connection services set');
    }
  }

  /// Show internet connection lost popup
  void showInternetConnectionLost() {
    if (_isShowingPopup && _currentPopupType == 'internet_lost') return;

    _showConnectionPopup(
      title: 'connection_no_internet'.tr(),
      message: 'connection_no_internet_message'.tr(),
      icon: Icons.wifi_off,
      type: 'internet_lost',
      showRetryButton: true,
    );
  }

  /// Show internet connection restored popup
  void showInternetConnectionRestored() {
    if (_isShowingPopup && _currentPopupType == 'internet_restored') return;

    _showConnectionPopup(
      title: 'connection_internet_restored'.tr(),
      message: 'connection_internet_restored_message'.tr(),
      icon: Icons.wifi,
      type: 'internet_restored',
      showRetryButton: false,
      autoClose: true,
    );
  }

  /// Show socket connection lost popup
  void showSocketConnectionLost() {
    if (_isShowingPopup && _currentPopupType == 'socket_lost') return;

    _showConnectionPopup(
      title: 'connection_socket_lost'.tr(),
      message: 'connection_socket_lost_message'.tr(),
      icon: Icons.cloud_off,
      type: 'socket_lost',
      showRetryButton: true,
    );
  }

  /// Show socket connection restored popup
  void showSocketConnectionRestored() {
    if (_isShowingPopup && _currentPopupType == 'socket_restored') return;

    _showConnectionPopup(
      title: 'connection_socket_restored'.tr(),
      message: 'connection_socket_restored_message'.tr(),
      icon: Icons.cloud_done,
      type: 'socket_restored',
      showRetryButton: false,
      autoClose: true,
    );
  }

  /// Show general connection error popup
  void showConnectionError({String? customMessage}) {
    if (_isShowingPopup && _currentPopupType == 'connection_error') return;

    // Clean up technical error message for end users
    String userFriendlyMessage = _getUserFriendlyErrorMessage(customMessage);

    _showConnectionPopup(
      title: 'connection_error'.tr(),
      message: userFriendlyMessage,
      icon: Icons.error_outline,
      type: 'connection_error',
      showRetryButton: true,
    );
  }

  /// Convert technical error messages to user-friendly messages
  String _getUserFriendlyErrorMessage(String? customMessage) {
    if (customMessage == null) {
      return 'connection_error_message'.tr();
    }

    String message = customMessage.toLowerCase();

    // Check for specific error types and provide user-friendly messages
    if (message.contains('host lookup') ||
        message.contains('nodename nor servname')) {
      return 'connection_error_message'.tr();
    } else if (message.contains('socket') || message.contains('connection')) {
      return 'connection_error_message'.tr();
    } else if (message.contains('network') || message.contains('internet')) {
      return 'connection_error_message'.tr();
    } else if (message.contains('timeout')) {
      return 'connection_error_message'.tr();
    } else if (message.contains('dioexception')) {
      return 'connection_error_message'.tr();
    }

    // For any other technical errors, show generic message
    return 'connection_error_message'.tr();
  }

  // /// Show reconnection attempt popup
  // void showReconnectionAttempt(int attempt, int maxAttempts) {
  //   if (_isShowingPopup && _currentPopupType == 'reconnecting') return;

  //   _showConnectionPopup(
  //     title: 'connection_reconnecting'.tr(),
  //     message:
  //         '${'connection_reconnecting_message'.tr()} ($attempt/$maxAttempts)',
  //     icon: Icons.refresh,
  //     type: 'reconnecting',
  //     showRetryButton: false,
  //     showProgress: true,
  //   );
  // }

  /// Hide current popup
  void hidePopup() {
    if (_currentContext != null && _isShowingPopup) {
      Navigator.of(_currentContext!, rootNavigator: true).pop();
      _isShowingPopup = false;
      _currentPopupType = null;

      if (kDebugMode) {
        print('ConnectionPopupService: Popup hidden');
      }
    }
  }

  /// Check if popup is currently showing
  bool get isShowingPopup => _isShowingPopup;

  /// Get current popup type
  String? get currentPopupType => _currentPopupType;

  /// Internal method to show connection popup
  void _showConnectionPopup({
    required String title,
    required String message,
    required IconData icon,
    required String type,
    bool showRetryButton = false,
    bool autoClose = false,
    bool showProgress = false,
  }) {
    if (_currentContext == null) {
      if (kDebugMode) {
        print('ConnectionPopupService: No context available to show popup');
      }
      return;
    }

    // Hide existing popup if different type
    if (_isShowingPopup && _currentPopupType != type) {
      hidePopup();
    }

    // Don't show if already showing same type
    if (_isShowingPopup && _currentPopupType == type) {
      return;
    }

    _isShowingPopup = true;
    _currentPopupType = type;

    if (kDebugMode) {
      print('ConnectionPopupService: Showing popup - $type');
    }

    showDialog(
      context: _currentContext!,
      barrierDismissible:
          !showProgress, // Don't allow dismiss if showing progress
      builder: (BuildContext context) => _ConnectionPopupDialog(
        title: title,
        message: message,
        icon: icon,
        showRetryButton: showRetryButton,
        showProgress: showProgress,
        onRetry: () {
          hidePopup();
          _onRetryPressed(type);
        },
        onClose: () {
          hidePopup();
          _onClosePressed(type);
        },
      ),
    );

    // Auto close for success messages
    if (autoClose) {
      Timer(const Duration(seconds: 3), () {
        hidePopup();
      });
    }
  }

  /// Handle retry button press
  void _onRetryPressed(String type) {
    if (kDebugMode) {
      print('ConnectionPopupService: Retry pressed for $type');
    }

    // Hide the current popup
    hidePopup();

    // Implement proper retry logic based on type
    switch (type) {
      case 'internet_lost':
        // Trigger internet connectivity check and attempt reconnection
        _retryInternetConnection();
        break;
      case 'socket_lost':
        // Trigger socket reconnection
        _retrySocketConnection();
        break;
      case 'connection_error':
        // Trigger general reconnection (both internet and socket)
        _retryGeneralConnection();
        break;
    }
  }

  /// Handle close button press
  void _onClosePressed(String type) {
    if (kDebugMode) {
      print('ConnectionPopupService: Close pressed for $type');
    }

    // Hide the current popup
    hidePopup();

    // For reconnecting popup, stop reconnection attempts and show connection error
    if (type == 'reconnecting') {
      // Stop reconnection attempts by setting max attempts reached
      _socketService?.stopReconnectionAttempts();

      // Show connection error popup instead
      showConnectionError(
          customMessage:
              'Connection lost. Please check your internet connection and try again.');
      return;
    }

    // For socket-related popups, reset the connection state to prevent false positives
    if (type == 'socket_lost' || type == 'connection_error') {
      _socketService?.resetConnectionState();
    }
  }

  /// Retry internet connection
  void _retryInternetConnection() {
    if (kDebugMode) {
      print('ConnectionPopupService: Retrying internet connection...');
    }

    // // Show reconnecting popup
    // showReconnectionAttempt(1, 3);

    // Force connectivity check
    Timer(const Duration(seconds: 2), () {
      _connectionMonitor?.forceConnectivityCheck();
      hidePopup();
    });
  }

  /// Retry socket connection
  void _retrySocketConnection() {
    if (kDebugMode) {
      print('ConnectionPopupService: Retrying socket connection...');
    }

    // // Show reconnecting popup
    // showReconnectionAttempt(1, 3);

    // Force socket reconnection using ChatService
    Timer(const Duration(seconds: 2), () {
      if (_chatService != null &&
          Constants.userId.isNotEmpty &&
          Constants.token.isNotEmpty) {
        // Initialize ChatService with proper configuration
        _chatService!.initializeSocket();
      }
      hidePopup();
    });
  }

  /// Retry general connection (both internet and socket)
  void _retryGeneralConnection() {
    if (kDebugMode) {
      print('ConnectionPopupService: Retrying general connection...');
    }

    // // Show reconnecting popup
    // showReconnectionAttempt(1, 3);

    // Force both internet and socket reconnection
    Timer(const Duration(seconds: 2), () {
      _connectionMonitor?.forceConnectivityCheck();
      if (_chatService != null &&
          Constants.userId.isNotEmpty &&
          Constants.token.isNotEmpty) {
        // Initialize ChatService with proper configuration
        _chatService!.initializeSocket();
      }
      hidePopup();
    });
  }

  /// Dispose resources
  void dispose() {
    hidePopup();
    _currentContext = null;
  }
}

/// Custom dialog widget for connection popups
class _ConnectionPopupDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool showRetryButton;
  final bool showProgress;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ConnectionPopupDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.showRetryButton,
    required this.showProgress,
    required this.onRetry,
    required this.onClose,
  });

  @override
  State<_ConnectionPopupDialog> createState() => _ConnectionPopupDialogState();
}

class _ConnectionPopupDialogState extends State<_ConnectionPopupDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorManager.blueLight800.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: ColorManager.blueLight800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.title,
                    style: getBoldStyle(
                      fontSize: 18,
                      color: ColorManager.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    widget.message,
                    style: getRegularStyle(
                      fontSize: 14,
                      color: ColorManager.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Progress indicator (if showing progress)
                  if (widget.showProgress) ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF677BA9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Buttons
                  Row(
                    children: [
                      if (widget.showRetryButton) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onRetry,
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: ColorManager.blueLight800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'connection_retry'.tr(),
                              style: getMediumStyle(
                                fontSize: 14,
                                color: ColorManager.blueLight800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.blueLight800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            widget.showRetryButton
                                ? 'connection_close'.tr()
                                : 'connection_ok'.tr(),
                            style: getMediumStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
