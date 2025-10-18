import 'package:flutter/material.dart';
import 'dart:async';
import 'upload_progress_dialog.dart';

class UploadProgressManager {
  static OverlayEntry? _overlayEntry;
  static BuildContext? _context;
  static bool _isShowing = false;
  static Timer? _progressTimer;
  static double _targetProgress = 0.0;
  static double _currentProgress = 0.0;

  static final ValueNotifier<double> _progressNotifier =
      ValueNotifier<double>(0.0);
  static final ValueNotifier<String> _statusNotifier =
      ValueNotifier<String>('Preparing...');

  static void show(BuildContext context) {
    print('=== UploadProgressManager show() CALLED ===');
    print('[UploadProgressManager] show() called. _isShowing=$_isShowing');
    if (_isShowing) {
      print(
          '[UploadProgressManager] show() - already showing, calling hide() first');
      hide(); // Always hide any existing dialog before showing a new one
    }

    _context = context;
    _currentProgress = 0.0;
    _targetProgress = 0.0;
    _progressNotifier.value = 0.0;
    _statusNotifier.value = 'Preparing...';

    _overlayEntry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: _progressNotifier,
        builder: (context, progress, _) {
          return ValueListenableBuilder<String>(
            valueListenable: _statusNotifier,
            builder: (context, status, __) {
              return UploadProgressDialog(
                progress: progress,
                status: status,
              );
            },
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;

    // Start smooth progress simulation
    _startProgressSimulation();

    // Add a safety timeout to automatically hide after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (_isShowing) {
        print('[UploadProgressManager] Safety timeout reached, hiding dialog');
        hide();
      }
    });
  }

  static void _startProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isShowing) {
        timer.cancel();
        return;
      }

      // Only simulate progress if no manual progress has been set recently
      // or if we're still below the target progress
      if (_currentProgress < _targetProgress) {
        _currentProgress += 0.005; // Increment by 0.5% every 200ms (slower)
        if (_currentProgress > _targetProgress) {
          _currentProgress = _targetProgress;
        }
        _progressNotifier.value = _currentProgress;

        // Update status based on progress only if no manual status was set recently
        if (_currentProgress < 0.3) {
          _statusNotifier.value = 'Preparing upload...';
        } else if (_currentProgress < 0.6) {
          _statusNotifier.value = 'Uploading file...';
        } else if (_currentProgress < 0.9) {
          _statusNotifier.value = 'Processing...';
        } else if (_currentProgress < 1.0) {
          _statusNotifier.value = 'Finalizing...';
        } else {
          _statusNotifier.value = 'Upload complete!';
        }
      }
    });
  }

  static void updateProgress(double progress, String status) {
    print(
        '[UploadProgressManager] updateProgress() called. progress=$progress, status=$status, _isShowing=$_isShowing');
    if (!_isShowing || _overlayEntry == null || _context == null) return;

    _targetProgress = progress;
    _statusNotifier.value = status;

    // Automatically hide when progress is 100%
    if (progress >= 1.0) {
      print(
          '[UploadProgressManager] updateProgress() - progress >= 1.0, hiding immediately');
      // Stop the progress simulation immediately
      _progressTimer?.cancel();
      _currentProgress = 1.0;
      _progressNotifier.value = 1.0;
      _statusNotifier.value = 'Upload complete!';

      // Hide immediately instead of with delay
      hide();
    }
  }

  static void showError(String errorMessage) {
    if (!_isShowing || _overlayEntry == null || _context == null) return;
    _progressTimer?.cancel();
    _currentProgress = 0.0;
    _targetProgress = 0.0;
    _progressNotifier.value = 0.0;
    _statusNotifier.value = errorMessage;
  }

  static void hide() {
    print('=== UploadProgressManager hide() CALLED ===');
    print('[UploadProgressManager] hide() called. _isShowing=$_isShowing');
    if (!_isShowing || _overlayEntry == null) {
      print(
          '[UploadProgressManager] hide() - already hidden or no overlay, returning');
      return;
    }

    _progressTimer?.cancel();
    _overlayEntry!.remove();
    _overlayEntry = null;
    _context = null;
    _isShowing = false;
    _currentProgress = 0.0;
    _targetProgress = 0.0;
    print('[UploadProgressManager] hide() - overlay removed and state reset');
  }
}
