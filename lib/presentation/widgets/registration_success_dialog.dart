import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

class RegistrationSuccessDialog extends StatelessWidget {
  final VoidCallback? onOkPressed;

  const RegistrationSuccessDialog({
    Key? key,
    this.onOkPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorManager.lightGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: ColorManager.lightGreen,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Request Sent Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message
            const Text(
              'Your registration request has been submitted successfully. You will receive a response within 48 hours.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // OK Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onOkPressed != null) {
                    onOkPressed!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.blueLight800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, {VoidCallback? onOkPressed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RegistrationSuccessDialog(
        onOkPressed: onOkPressed,
      ),
    );
  }
}
