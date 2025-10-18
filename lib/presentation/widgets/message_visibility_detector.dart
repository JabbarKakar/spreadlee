import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A widget that detects when its child becomes visible and calls a callback
class MessageVisibilityDetector extends StatefulWidget {
  final Widget child;
  final String messageId;
  final bool isFromCurrentUser;
  final VoidCallback? onMessageVisible;
  final VoidCallback? onMessageInvisible;

  const MessageVisibilityDetector({
    Key? key,
    required this.child,
    required this.messageId,
    required this.isFromCurrentUser,
    this.onMessageVisible,
    this.onMessageInvisible,
  }) : super(key: key);

  @override
  State<MessageVisibilityDetector> createState() =>
      _MessageVisibilityDetectorState();
}

class _MessageVisibilityDetectorState extends State<MessageVisibilityDetector> {
  final GlobalKey _widgetKey = GlobalKey();
  bool _isVisible = false;
  bool _hasTriggeredVisible = false;

  @override
  void initState() {
    super.initState();
    // Trigger visibility check after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;

    final RenderObject? renderObject =
        _widgetKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final RenderBox renderBox = renderObject;

      // Check if the widget is visible in the viewport
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // Get the screen size
      final screenSize = MediaQuery.of(context).size;

      // Check if the widget is within the visible area
      final isCurrentlyVisible = position.dy >= 0 &&
          position.dy <= screenSize.height &&
          position.dy + size.height >= 0;

      if (isCurrentlyVisible && !_isVisible) {
        _isVisible = true;
        if (!_hasTriggeredVisible) {
          _hasTriggeredVisible = true;
          if (kDebugMode) {
            print(
                'MessageVisibilityDetector: Message ${widget.messageId} became visible');
          }
          widget.onMessageVisible?.call();
        }
      } else if (!isCurrentlyVisible && _isVisible) {
        _isVisible = false;
        if (kDebugMode) {
          print(
              'MessageVisibilityDetector: Message ${widget.messageId} became invisible');
        }
        widget.onMessageInvisible?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Check visibility on scroll
        if (notification is ScrollUpdateNotification) {
          _checkVisibility();
        }
        return false;
      },
      child: Container(
        key: _widgetKey,
        child: widget.child,
      ),
    );
  }
}

