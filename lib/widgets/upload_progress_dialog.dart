import 'package:flutter/material.dart';
import 'dart:async';

import '../presentation/resources/color_manager.dart';

class UploadProgressDialog extends StatefulWidget {
  final double progress;
  final String status;
  final bool isError;

  const UploadProgressDialog({
    Key? key,
    required this.progress,
    required this.status,
    this.isError = false,
  }) : super(key: key);

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _scrollController;
  late Animation<Offset> _scrollAnimation;

  double _currentProgress = 0.0;
  Timer? _progressTimer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();

    // Initialize progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: _currentProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Initialize scroll animation
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scrollAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(
      parent: _scrollController,
      curve: Curves.easeInOut,
    ));

    // Start auto-scrolling
    _startAutoScroll();

    // Listen to progress changes
    _progressAnimation.addListener(() {
      setState(() {
        _currentProgress = _progressAnimation.value;
      });
    });

    // Start progress animation
    _animateProgress();
  }

  @override
  void didUpdateWidget(UploadProgressDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progress != widget.progress) {
      _animateProgress();
    }
  }

  void _animateProgress() {
    _progressAnimation = Tween<double>(
      begin: _currentProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _progressController.reset();
    _progressController.forward();
  }

  void _startAutoScroll() {
    _scrollController.repeat(reverse: true);
    setState(() {
      _isScrolling = true;
    });
  }

  void _stopAutoScroll() {
    _scrollController.stop();
    setState(() {
      _isScrolling = false;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scrollController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String percentText = '${(_currentProgress * 100).toInt()}%';
    String displayText = widget.status.contains('%')
        ? widget.status
        : 'Uploading... $percentText';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _scrollAnimation,
          child: Container(
            width: 340,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular upload icon with rotation animation
                AnimatedRotation(
                  turns: _isScrolling ? 1 : 0,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_rounded,
                      color: ColorManager.blueLight800,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Uploading text and percent
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isError ? Colors.red : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Rounded linear progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    minHeight: 4,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isError ? Colors.red : ColorManager.blueLight800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
