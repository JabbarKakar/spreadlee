import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

class CountryCodePicker extends StatelessWidget {
  final String initialCountryCode;
  final Function(String) onCountryCodeChanged;
  final Function(String) onPhoneNumberChanged;

  const CountryCodePicker({
    super.key,
    required this.initialCountryCode,
    required this.onCountryCodeChanged,
    required this.onPhoneNumberChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.gray100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: ColorManager.gray50,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              // TODO: Show country code picker dialog
              // For now, just toggle between +966 and +1
              onCountryCodeChanged(
                initialCountryCode == '+966' ? '+1' : '+966',
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    initialCountryCode,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 4.0),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ColorManager.gray400,
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 20.0,
            width: 1.0,
            color: ColorManager.gray400,
          ),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter Phone Number',
                hintStyle: theme.textTheme.labelMedium?.copyWith(
                  color: ColorManager.gray500,
                  fontSize: 14.0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: onPhoneNumberChanged,
            ),
          ),
        ],
      ),
    );
  }
}
