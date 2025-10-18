import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';

class DeclinedBankReasonDialog extends StatelessWidget {
  final String? rejectionReason;

  const DeclinedBankReasonDialog({
    super.key,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24.0,
                ),
                Expanded(
                  child: Text(
                    'Reason for Declination'.tr(),
                    textAlign: TextAlign.center,
                    style: getMediumStyle(
                      fontSize: 16.0,
                      color: ColorManager.primaryText,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: ColorManager.primaryText,
                  iconSize: 18.0,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Reason:'.tr(),
              style: getMediumStyle(
                fontSize: 12.0,
                color: ColorManager.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorManager.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rejectionReason ?? 'No reason provided'.tr(),
                style: getRegularStyle(
                  fontSize: 14.0,
                  color: ColorManager.primaryText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.blueLight800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Close'.tr(),
                  style: getMediumStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
