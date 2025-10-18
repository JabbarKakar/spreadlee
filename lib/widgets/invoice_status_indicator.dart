import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/services/invoice_status_sync_service.dart';
import 'dart:async';

/// Widget that displays real-time invoice status with animations
class InvoiceStatusIndicator extends StatefulWidget {
  final String invoiceId;
  final String? initialStatus;
  final double? size;
  final bool showText;
  final bool showAnimation;
  final VoidCallback? onStatusChanged;

  const InvoiceStatusIndicator({
    Key? key,
    required this.invoiceId,
    this.initialStatus,
    this.size,
    this.showText = true,
    this.showAnimation = true,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<InvoiceStatusIndicator> createState() => _InvoiceStatusIndicatorState();
}

class _InvoiceStatusIndicatorState extends State<InvoiceStatusIndicator>
    with TickerProviderStateMixin {
  final InvoiceStatusSyncService _statusService = InvoiceStatusSyncService();

  String? _currentStatus;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _initializeAnimations();
    _setupStatusListener();
  }

  void _initializeAnimations() {
    if (widget.showAnimation) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.elasticOut,
      ));

      _colorAnimation = ColorTween(
        begin: _getStatusColor(_currentStatus),
        end: _getStatusColor(_currentStatus),
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ));
    }
  }

  void _setupStatusListener() {
    _statusSubscription = _statusService.statusUpdateStream.listen(
      (statusUpdate) {
        if (statusUpdate['invoiceId'] == widget.invoiceId) {
          _updateStatus(statusUpdate['status']);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('InvoiceStatusIndicator: Error in status stream: $error');
        }
      },
    );
  }

  void _updateStatus(String newStatus) {
    if (_currentStatus != newStatus) {
      setState(() {
        _currentStatus = newStatus;
      });

      if (widget.showAnimation && _animationController != null) {
        _colorAnimation = ColorTween(
          begin: _getStatusColor(_currentStatus),
          end: _getStatusColor(newStatus),
        ).animate(CurvedAnimation(
          parent: _animationController!,
          curve: Curves.easeInOut,
        ));

        _animationController!.forward().then((_) {
          _animationController!.reverse();
        });
      }

      widget.onStatusChanged?.call();

      if (kDebugMode) {
        print(
            'InvoiceStatusIndicator: Status updated to $newStatus for invoice ${widget.invoiceId}');
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return ColorManager.lightGreen;
      case 'unpaid':
        return ColorManager.darkError;
      case 'pending':
        return ColorManager.orange;
      case 'expired':
        return ColorManager.darkGrey;
      default:
        return ColorManager.darkGrey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'unpaid':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      case 'expired':
        return Icons.check;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Unpaid';
      case 'pending':
        return 'Pending';
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 24.0;

    Widget statusWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(_currentStatus),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getStatusIcon(_currentStatus),
        color: Colors.white,
        size: size * 0.6,
      ),
    );

    if (widget.showAnimation && _animationController != null) {
      statusWidget = AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation?.value ?? 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color:
                    _colorAnimation?.value ?? _getStatusColor(_currentStatus),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(_currentStatus),
                color: Colors.white,
                size: size * 0.6,
              ),
            ),
          );
        },
      );
    }

    if (widget.showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statusWidget,
          const SizedBox(width: 8),
          Text(
            _getStatusText(_currentStatus),
            style: TextStyle(
              color: _getStatusColor(_currentStatus),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return statusWidget;
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _animationController?.dispose();
    super.dispose();
  }
}

/// Compact status badge widget
class InvoiceStatusBadge extends StatelessWidget {
  final String invoiceId;
  final String? initialStatus;
  final double? size;
  final EdgeInsets? padding;

  const InvoiceStatusBadge({
    Key? key,
    required this.invoiceId,
    this.initialStatus,
    this.size,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InvoiceStatusIndicator(
      invoiceId: invoiceId,
      initialStatus: initialStatus,
      size: size ?? 16.0,
      showText: false,
      showAnimation: true,
    );
  }
}

/// Status text widget with real-time updates
class InvoiceStatusText extends StatelessWidget {
  final String invoiceId;
  final String? initialStatus;
  final TextStyle? style;

  const InvoiceStatusText({
    Key? key,
    required this.invoiceId,
    this.initialStatus,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: InvoiceStatusSyncService().statusUpdateStream,
      builder: (context, snapshot) {
        String currentStatus = initialStatus ?? 'unknown';

        if (snapshot.hasData && snapshot.data!['invoiceId'] == invoiceId) {
          currentStatus = snapshot.data!['status'] ?? currentStatus;
        }

        return Text(
          _getStatusText(currentStatus),
          style: style ??
              TextStyle(
                color: _getStatusColor(currentStatus),
                fontWeight: FontWeight.w600,
              ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return ColorManager.lightGreen;
      case 'unpaid':
        return ColorManager.darkError;
      case 'pending':
        return ColorManager.orange;
      case 'expired':
        return ColorManager.darkGrey;
      default:
        return ColorManager.darkGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Unpaid';
      case 'pending':
        return 'Pending';
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }
}
