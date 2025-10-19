import 'package:flutter/material.dart';
import '../../../resources/color_manager.dart';

typedef FutureVoidCallback = Future<void> Function();

class CloseChatDialog extends StatefulWidget {
  final FutureVoidCallback onClose;

  const CloseChatDialog({
    super.key,
    required this.onClose,
  });

  @override
  State<CloseChatDialog> createState() => _CloseChatDialogState();
}

class _CloseChatDialogState extends State<CloseChatDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    color: ColorManager.gray500,
                    iconSize: 18.0,
                  ),
                ],
              ),
              const Text(
                'Closing the chat will mark the conversation as closed. Are you sure you want to close this chat?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await widget.onClose();
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColorManager.blueLight800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ColorManager.blueLight800),
                        ),
                      )
                          : Text(
                        'Yes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ColorManager.blueLight800,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 14.0,
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
  }
}
