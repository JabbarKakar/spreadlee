import 'package:flutter/material.dart';
import 'package:spreadlee/core/force_logout_handler.dart';
import 'package:spreadlee/services/chat_service.dart';

/// A wrapper widget that listens for force logout events from the chat service
/// and handles them by showing a dialog and clearing user data.
class ForceLogoutWrapper extends StatefulWidget {
  final Widget child;
  final ChatService? chatService;

  const ForceLogoutWrapper({
    Key? key,
    required this.child,
    this.chatService,
  }) : super(key: key);

  @override
  State<ForceLogoutWrapper> createState() => _ForceLogoutWrapperState();
}

class _ForceLogoutWrapperState extends State<ForceLogoutWrapper> {
  @override
  void initState() {
    super.initState();
    // Set up force logout listener if chat service is provided
    if (widget.chatService != null) {
      widget.chatService!.onForceLogout((data) {
        if (mounted) {
          ForceLogoutHandler.handleForceLogout(context, data);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A mixin that can be used in StatefulWidgets to handle force logout events
mixin ForceLogoutMixin<T extends StatefulWidget> on State<T> {
  ChatService? _chatService;

  /// Set up the chat service for force logout handling
  void setupForceLogoutHandler(ChatService chatService) {
    _chatService = chatService;
    _chatService!.onForceLogout((data) {
      if (mounted) {
        ForceLogoutHandler.handleForceLogout(context, data);
      }
    });
  }

  /// Clean up the force logout handler
  @override
  void dispose() {
    _chatService = null;
    super.dispose();
  }
}
