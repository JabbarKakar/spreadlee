import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spreadlee/domain/subaccount_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/bloc/business/subaccounts/subaccounts_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/customer/login/widget/country_code_text_field.dart';

class ChangeInfoDialog extends StatefulWidget {
  final SubaccountModel subaccount;
  final Function(String phoneCode, String phoneNumber, String password) onSave;

  const ChangeInfoDialog({
    super.key,
    required this.subaccount,
    required this.onSave,
  });

  @override
  State<ChangeInfoDialog> createState() => _ChangeInfoDialogState();
}

class _ChangeInfoDialogState extends State<ChangeInfoDialog> {
  late TextEditingController _passwordController;
  late TextEditingController _phoneNumberController;
  late FocusNode _passwordFocusNode;
  String _selectedCountryCode = '+966';
  bool _passwordVisibility = false;
  bool _passwordError = false;
  final bool _passwordLengthError = false;
  bool _phoneError = false;
  bool _phoneLengthError = false;

  @override
  void initState() {
    super.initState();
    _passwordController =
        TextEditingController(text: widget.subaccount.data?[0].passwordGen);
    _passwordFocusNode = FocusNode();

    // Parse existing phone number
    final existingPhone = widget.subaccount.data?[0].phoneNumber ?? '';
    if (existingPhone.isNotEmpty && existingPhone.startsWith('+')) {
      // Try to extract country code from the beginning
      // Common country codes: +1, +7, +20, +27, +30, +31, +32, +33, +34, +36, +39, +40, +41, +43, +44, +45, +46, +47, +48, +49, +51, +52, +53, +54, +55, +56, +57, +58, +60, +61, +62, +63, +64, +65, +66, +81, +82, +84, +86, +90, +91, +92, +93, +94, +95, +98, +212, +213, +216, +218, +220, +221, +222, +223, +224, +225, +226, +227, +228, +229, +230, +231, +232, +233, +234, +235, +236, +237, +238, +239, +240, +241, +242, +243, +244, +245, +246, +248, +249, +250, +251, +252, +253, +254, +255, +256, +257, +258, +260, +261, +262, +263, +264, +265, +266, +267, +268, +269, +290, +291, +297, +298, +299, +350, +351, +352, +353, +354, +355, +356, +357, +358, +359, +370, +371, +372, +373, +374, +375, +376, +377, +378, +380, +381, +382, +383, +385, +386, +387, +389, +420, +421, +423, +500, +501, +502, +503, +504, +505, +506, +507, +508, +509, +590, +591, +592, +593, +594, +595, +596, +597, +598, +599, +670, +672, +673, +674, +675, +676, +677, +678, +679, +680, +681, +682, +683, +684, +685, +686, +687, +688, +689, +690, +691, +692, +850, +852, +853, +855, +856, +880, +886, +960, +961, +962, +963, +964, +965, +966, +967, +968, +970, +971, +972, +973, +974, +975, +976, +977, +992, +993, +994, +995, +996, +998

      String? extractedCountryCode;
      String? extractedPhoneNumber;

      // Try to match common country codes (longest first to avoid partial matches)
      final countryCodes = [
        '+966', '+971', '+965', '+973', '+974', '+970', '+972', '+961', '+962',
        '+963', '+964', '+967', '+968', // Middle East
        '+1',
        '+7',
        '+20',
        '+27',
        '+30',
        '+31',
        '+32',
        '+33',
        '+34',
        '+36',
        '+39',
        '+40',
        '+41',
        '+43',
        '+44',
        '+45',
        '+46',
        '+47',
        '+48',
        '+49', // Europe & others
        '+51',
        '+52',
        '+53',
        '+54',
        '+55',
        '+56',
        '+57',
        '+58',
        '+60',
        '+61',
        '+62',
        '+63',
        '+64',
        '+65',
        '+81',
        '+82',
        '+84',
        '+86',
        '+90',
        '+91',
        '+92',
        '+93',
        '+94',
        '+95',
        '+98', // Asia & Americas
        '+212',
        '+213',
        '+216',
        '+218',
        '+220',
        '+221',
        '+222',
        '+223',
        '+224',
        '+225',
        '+226',
        '+227',
        '+228',
        '+229',
        '+230',
        '+231',
        '+232',
        '+233',
        '+234',
        '+235',
        '+236',
        '+237',
        '+238',
        '+239',
        '+240',
        '+241',
        '+242',
        '+243',
        '+244',
        '+245',
        '+246',
        '+248',
        '+249',
        '+250',
        '+251',
        '+252',
        '+253',
        '+254',
        '+255',
        '+256',
        '+257',
        '+258',
        '+260',
        '+261',
        '+262',
        '+263',
        '+264',
        '+265',
        '+266',
        '+267',
        '+268',
        '+269',
        '+290',
        '+291',
        '+297',
        '+298',
        '+299', // Africa
        '+350',
        '+351',
        '+352',
        '+353',
        '+354',
        '+355',
        '+356',
        '+357',
        '+358',
        '+359',
        '+370',
        '+371',
        '+372',
        '+373',
        '+374',
        '+375',
        '+376',
        '+377',
        '+378',
        '+380',
        '+381',
        '+382',
        '+383',
        '+385',
        '+386',
        '+387',
        '+389',
        '+420',
        '+421',
        '+423', // Europe
        '+500',
        '+501',
        '+502',
        '+503',
        '+504',
        '+505',
        '+506',
        '+507',
        '+508',
        '+509',
        '+590',
        '+591',
        '+592',
        '+593',
        '+594',
        '+595',
        '+596',
        '+597',
        '+598',
        '+599', // Americas
        '+670',
        '+672',
        '+673',
        '+674',
        '+675',
        '+676',
        '+677',
        '+678',
        '+679',
        '+680',
        '+681',
        '+682',
        '+683',
        '+684',
        '+685',
        '+686',
        '+687',
        '+688',
        '+689',
        '+690',
        '+691',
        '+692', // Pacific
        '+850',
        '+852',
        '+853',
        '+855',
        '+856',
        '+880',
        '+886',
        '+960',
        '+961',
        '+962',
        '+963',
        '+964',
        '+965',
        '+966',
        '+967',
        '+968',
        '+970',
        '+971',
        '+972',
        '+973',
        '+974',
        '+975',
        '+976',
        '+977',
        '+992',
        '+993',
        '+994',
        '+995',
        '+996',
        '+998' // Asia
      ];

      // Sort by length (longest first) to match longer codes first
      countryCodes.sort((a, b) => b.length.compareTo(a.length));

      for (final code in countryCodes) {
        if (existingPhone.startsWith(code)) {
          extractedCountryCode = code;
          extractedPhoneNumber = existingPhone.substring(code.length);
          break;
        }
      }

      if (extractedCountryCode != null && extractedPhoneNumber != null) {
        _selectedCountryCode = extractedCountryCode;
        _phoneNumberController =
            TextEditingController(text: extractedPhoneNumber);
      } else {
        // Fallback: try to split by space or use default
        final phoneParts = existingPhone.split(' ');
        if (phoneParts.isNotEmpty) {
          _selectedCountryCode = phoneParts[0];
          _phoneNumberController = TextEditingController(
            text: phoneParts.length > 1 ? phoneParts.sublist(1).join('') : '',
          );
        } else {
          _phoneNumberController = TextEditingController();
        }
      }
    } else {
      _phoneNumberController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 0.0, 0.0, 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 24.0,
                        ),
                        Text(
                          'Changing SubAccounts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16.0,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: ColorManager.gray500,
                            size: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number: *',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      CountryCodeTextField(
                        initialCountryCode: _selectedCountryCode,
                        phoneLengthError: _phoneLengthError,
                        enterPhoneError: _phoneError,
                        onChange: (value) {
                          setState(() {
                            _phoneError = false;
                            _phoneLengthError = false;
                          });
                        },
                        onCountryCodeChanged: (countryCode) {
                          setState(() {
                            _selectedCountryCode = countryCode;
                          });
                        },
                        updateMaskLength: (maskLength) {
                          // Optionally handle mask length if needed
                        },
                        controller: _phoneNumberController,
                      ),
                      if (_phoneError)
                        Text(
                          'Please enter phone number.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorManager.alertError500,
                            fontSize: 12.0,
                          ),
                        ),
                      if (_phoneLengthError)
                        Text(
                          'Please enter a valid phone number.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorManager.alertError500,
                            fontSize: 12.0,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password: *',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorManager.gray100,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: _passwordError || _passwordLengthError
                                ? ColorManager.alertError500
                                : ColorManager.gray50,
                            width: 1.0,
                          ),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: !_passwordVisibility,
                          decoration: InputDecoration(
                            isDense: false,
                            hintText: 'Enter Password',
                            hintStyle: theme.textTheme.labelMedium?.copyWith(
                              color: ColorManager.gray500,
                              fontSize: 14.0,
                            ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisibility = !_passwordVisibility;
                                });
                              },
                              icon: Icon(
                                _passwordVisibility
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: ColorManager.gray400,
                                size: 20.0,
                              ),
                            ),
                          ),
                          style: theme.textTheme.bodyMedium,
                          keyboardType: TextInputType.visiblePassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'\S+')),
                          ],
                        ),
                      ),
                      if (_passwordError)
                        Text(
                          'Please enter password.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorManager.alertError500,
                            fontSize: 12.0,
                          ),
                        ),
                      if (_passwordLengthError)
                        Text(
                          'Password should be at least 8 characters.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorManager.alertError500,
                            fontSize: 12.0,
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 12.0, 0.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ColorManager.blueLight800,
                              minimumSize: const Size(double.infinity, 40.0),
                              padding: EdgeInsets.zero,
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                  color: ColorManager.blueLight800,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Construct phone number from country code and phone number
                              final phoneNumber = _phoneNumberController.text
                                      .trim()
                                      .isNotEmpty
                                  ? (_selectedCountryCode +
                                      _phoneNumberController.text
                                          .trim()
                                          .replaceAll(RegExp(r'[^0-9]'), ''))
                                  : '';

                              if (phoneNumber ==
                                      widget.subaccount.data?[0].phoneNumber &&
                                  _passwordController.text ==
                                      widget.subaccount.data?[0].passwordGen) {
                                return; // No changes made
                              }

                              if (phoneNumber.isEmpty ||
                                  _passwordController.text.isEmpty) {
                                setState(() {
                                  _phoneError = phoneNumber.isEmpty;
                                  _passwordError =
                                      _passwordController.text.isEmpty;
                                });
                                return;
                              }

                              try {
                                await context
                                    .read<SubaccountsCubit>()
                                    .updateSubaccount(
                                      id: widget.subaccount.data?[0].id ?? '',
                                      password: _passwordController.text,
                                      phoneNumber: phoneNumber,
                                      context: context,
                                    );

                                if (mounted) {
                                  Navigator.pop(context);
                                  widget.onSave(
                                    _selectedCountryCode,
                                    phoneNumber,
                                    _passwordController.text,
                                  );
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: const Text(
                                          'Information has been changed successfully.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor:
                                          ColorManager.alertError500,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.blueLight800,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40.0),
                              padding: EdgeInsets.zero,
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              disabledBackgroundColor:
                                  ColorManager.buttonDisable,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
