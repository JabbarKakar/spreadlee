import 'package:flutter/material.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';


class CountryPickerWidget extends StatelessWidget {
  final Function(String) onCountrySelected;
  final String? Function(String?)? validator;

  const CountryPickerWidget({
    Key? key,
    required this.onCountrySelected,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CSCPickerPlus(
              showCities: false,
              showStates: false,
              flagState: CountryFlag.DISABLE,
              countryStateLanguage: CountryStateLanguage.englishOrNative,
              dropdownDecoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      formFieldState.hasError ? Colors.red : Colors.transparent,
                ),
              ),
              onCountryChanged: (country) {
                onCountrySelected(country);
                formFieldState.didChange(country);
              },
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  formFieldState.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
