import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/customer/login/widget/country_code_text_field.dart';

class EditEmailPhoneScreen extends StatefulWidget {
  const EditEmailPhoneScreen({super.key});

  @override
  State<EditEmailPhoneScreen> createState() => _EditEmailPhoneScreenState();
}

class _EditEmailPhoneScreenState extends State<EditEmailPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _emailError = false;
  bool _phoneError = false;
  bool _phoneLengthError = false;
  String _completePhoneNumber = '';
  String _selectedCountryCode = '+966';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentContactInfo();
    context.read<SettingCubit>().getContactInfo();
  }

  void _loadCurrentContactInfo() async {
    const storage = FlutterSecureStorage();
    await storage.read(key: 'email') ?? '';
    await storage.read(key: 'phoneNumber') ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _updateContactInfo() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _emailError = _emailController.text.isEmpty;
        _phoneError = _completePhoneNumber.isEmpty;
      });
      return;
    }

    // Get the new values
    final newEmail = _emailController.text.trim();
    final newPhone = _completePhoneNumber.trim();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Always send both values to ensure proper update
      await context.read<SettingCubit>().changeContactInfo(
            newEmail: newEmail,
            newPhoneNumber: newPhone,
          );
    } finally {
      // Hide loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Email & Phone Number'.tr(),
            style: getMediumStyle(
              fontSize: 16.0,
              color: ColorManager.primaryText,
            ),
          ),
        ),
        body: BlocConsumer<SettingCubit, SettingState>(
          listener: (context, state) {
            if (state is ContactInfoSuccessState) {
              // Update the form with current values
              setState(() {
                _emailController.text = state.data.email;
                if (state.data.phoneNumber.isNotEmpty) {
                  // Parse the phone number to extract country code and number
                  String phoneNumber = state.data.phoneNumber;

                  if (phoneNumber.startsWith('+')) {
                    // Find the country code by trying different lengths
                    int countryCodeEnd = 1;
                    bool foundValidCode = false;

                    // Try to find a valid country code (2-4 digits after +)
                    for (int i = 2; i <= 4 && i < phoneNumber.length; i++) {
                      String potentialCode = phoneNumber.substring(0, i);

                      if ([
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
                        '+49',
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
                        '+66',
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
                        '+98',
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
                        '+299',
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
                        '+423',
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
                        '+599',
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
                        '+692',
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
                        '+998'
                      ].contains(potentialCode)) {
                        countryCodeEnd = i;
                        foundValidCode = true;

                        if (kDebugMode) {
                          print(
                              'Found valid country code: $potentialCode at position $i');
                        }
                      }
                    }

                    if (foundValidCode) {
                      _selectedCountryCode =
                          phoneNumber.substring(0, countryCodeEnd);
                      String phoneWithoutCode =
                          phoneNumber.substring(countryCodeEnd);
                      _phoneNumberController.text =
                          phoneWithoutCode.replaceAll(RegExp(r'[^0-9]'), '');
                      _completePhoneNumber = state.data.phoneNumber;
                    } else {
                      // Fallback: assume +966 for Saudi Arabia if no valid code found
                      _selectedCountryCode = '+966';
                      _phoneNumberController.text = phoneNumber
                          .substring(1)
                          .replaceAll(RegExp(r'[^0-9]'), '');
                      _completePhoneNumber = state.data.phoneNumber;
                    }
                  } else {
                    _phoneNumberController.text =
                        phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
                    _completePhoneNumber = _selectedCountryCode +
                        phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
                  }
                } else {
                  // If phone number is empty, clear the controller
                  _phoneNumberController.clear();
                  _completePhoneNumber = '';
                }
              });
            } else if (state is CreateSettingSuccessState) {
              // Show success message
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(
                    'Your contact information has been updated successfully.'
                        .tr(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'.tr()),
                    ),
                  ],
                ),
              ).then((_) {
                // Refresh contact info after successful update
                context.read<SettingCubit>().getContactInfo();
                // Close the screen
                Navigator.pop(context);
              });
            } else if (state is CreateSettingErrorState) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(state.error),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'.tr()),
                    ),
                  ],
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ContactInfoLoadingState) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email Field
                            Text(
                              'Your Email:'.tr(),
                              style: getMediumStyle(
                                fontSize: 12.0,
                                color: ColorManager.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                hintText: 'Enter Your Email'.tr(),
                                filled: true,
                                fillColor: ColorManager.gray100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                    color: ColorManager.alertError500,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email address.'.tr();
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email address.'
                                      .tr();
                                }
                                return null;
                              },
                            ),
                            if (_emailError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Please enter a valid email.'.tr(),
                                  style: getRegularStyle(
                                    fontSize: 12.0,
                                    color: ColorManager.alertError500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24.0),

                            // Phone Field
                            Text(
                              'Phone Number:'.tr(),
                              style: getMediumStyle(
                                fontSize: 12.0,
                                color: ColorManager.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            CountryCodeTextField(
                              initialCountryCode: _selectedCountryCode,
                              phoneLengthError: _phoneLengthError,
                              enterPhoneError: _phoneError,
                              enabled: _isEditing,
                              onChange: (value) {
                                setState(() {
                                  _completePhoneNumber = _selectedCountryCode +
                                      value.replaceAll(RegExp(r'[^0-9]'), '');
                                  _phoneError = false;
                                  _phoneLengthError = false;
                                });
                              },
                              updateMaskLength: (maskLength) {
                                // Handle mask length if needed
                              },
                              controller: _phoneNumberController,
                              onCountryCodeChanged: (countryCode) {
                                setState(() {
                                  _selectedCountryCode = countryCode;
                                  _completePhoneNumber = _selectedCountryCode +
                                      _phoneNumberController.text
                                          .replaceAll(RegExp(r'[^0-9]'), '');
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: state is CreateSettingLoadingState
                          ? null
                          : () async {
                              if (_isEditing) {
                                await _updateContactInfo();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        disabledBackgroundColor: ColorManager.buttonDisable,
                      ),
                      child: state is CreateSettingLoadingState
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEditing ? 'Save'.tr() : 'Edit'.tr(),
                              style: getMediumStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
