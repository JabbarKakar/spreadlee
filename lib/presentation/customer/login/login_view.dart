import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/presentation/bloc/customer/login_customer_bloc/login_customer_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/login_customer_bloc/login_customer_states.dart';
import 'package:spreadlee/presentation/bloc/customer/otp_customer_bloc/otp_customer_cubit.dart';
import 'package:spreadlee/presentation/customer/login/widget/login_header.dart';
import 'package:spreadlee/presentation/policy_and_terms/policy_and_terms.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import '../../../core/app_prefs.dart';
import '../../../core/di.dart';
import '../../../core/languages_manager.dart';
import '../../resources/color_manager.dart';
import '../../resources/string_manager.dart';
import 'widget/country_code_text_field.dart';

enum InputType { email, phone }

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AppPreferences _appPreferences = instance<AppPreferences>();
  // late final PhoneController _phoneController; // REMOVE
  // Use separate FocusNodes for each field.
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  // New state for custom phone input
  final String _selectedCountryCode = '+966';
  // Remove: String _enteredPhoneNumber = '';
  // Remove: bool _enterPhoneError = false;
  // Remove: bool _customPhoneLengthError = false;

  @override
  void dispose() {
    // _phoneController.dispose(); // REMOVE
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // _phoneController = PhoneController(); // REMOVE
    // _phoneController.value = PhoneNumber.parse('+966'); // REMOVE
    context.read<LoginCubit>().fToast.init(context);
  }

  bool isRTL() {
    return context.locale == ARABIC_LOCALE;
  }

  @override
  Widget build(BuildContext context) {
    var cubit = LoginCubit.get(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<LoginCubit, LoginStates>(
        listener: (context, state) {
          if (state is LoginSuccessState) {
            if (cubit.loginModel?.message == "OTP sent successfully") {
              _appPreferences.setOTPExpiry(
                  key: "otpExpiry", value: cubit.loginModel!.otpExpiry ?? "");
              // Pass login model to OTP cubit and clear any previous data
              final otpCubit = context.read<OtpCubit>();
              otpCubit.loginModel = cubit.loginModel;
              // Clear any cached contact info to prevent showing old data
              otpCubit.loginModel?.data?.email = null;
              otpCubit.loginModel?.data?.phoneNumber = null;
              otpCubit.loginModel?.data?.identifier = null;
              // Set the current contact info
              if (_emailController.text.trim().isNotEmpty) {
                final email = _emailController.text.trim();
                otpCubit.loginModel?.data?.email = email;
                otpCubit.loginModel?.data?.identifier = email;
              } else if (_phoneNumberController.text.trim().isNotEmpty) {
                final phone = _selectedCountryCode +
                    _phoneNumberController.text
                        .trim()
                        .replaceAll(RegExp(r'[^0-9]'), '');
                otpCubit.loginModel?.data?.phoneNumber = phone;
                otpCubit.loginModel?.data?.identifier = phone;
              }
              Navigator.pushReplacementNamed(context, Routes.otpVerifyRoute);
              context.read<OtpCubit>().fToast.init(context);
            } else if (cubit.loginModel?.message ==
                "Phone number or email is required") {
              cubit.showCustomToast(
                message: AppStrings.phoneEmailRequired.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.loginModel?.message ==
                "OTP is still valid for minutes.") {
              cubit.showCustomToast(
                message: AppStrings.otpStillValid.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.loginModel?.message ==
                "Your account has been requested for deletion. Please contact support if you wish to reactivate your account.") {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Center(
                    child: Text(
                      'Account Deletion Requested',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  content: const Text(
                    'Your account has been requested for deletion. Please wait until your request is approved so you can register again.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontSize: 12),
                  ),
                  actions: [
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                              fontFamily: 'Poppins', color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
          if (state is LoginErrorState) {
            cubit.showCustomToast(
                message: AppStrings.errorOnSendOtp.tr(),
                color: ColorManager.lightError,
                messageColor: ColorManager.white);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LoginHeaderWidget(),
                        const SizedBox(height: 24.0),
                        Text(
                          AppStrings.loginNow.tr(),
                          style: const TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppStrings.enterCodePhone.tr(),
                          style: const TextStyle(
                            fontSize: 11.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 28.0),
                        Text(AppStrings.emailphone.tr(),
                            style: const TextStyle(
                                fontSize: 10.0, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8.0),
                        // Show both fields at the same time
                        Column(
                          children: [
                            // Email Field
                            SizedBox(
                              width: 400,
                              height: 50,
                              child: TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: AppStrings.enterEmailPhone.tr(),
                                  labelStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                    color: ColorManager.greycard,
                                    letterSpacing: 1.2,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: InputBorder.none,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: ColorManager.blueLight800,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),

                            const Center(child: Text("OR")),

                            const SizedBox(height: 20.0),

                            // Phone Field
                            CountryCodeTextField(
                              initialCountryCode: _selectedCountryCode,
                              phoneLengthError:
                                  false, // or implement your own validation if needed
                              enterPhoneError:
                                  false, // or implement your own validation if needed
                              onChange: (value) {
                                setState(() {
                                  // No need to update _enteredPhoneNumber
                                });
                              },
                              updateMaskLength: (maskLength) {
                                // Optionally handle mask length if needed
                              },
                              controller: _phoneNumberController,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: FutureBuilder(
                                  future: Future.value(false),
                                  builder:
                                      (context, AsyncSnapshot<bool> snapshot) {
                                    if (snapshot.hasData) {
                                      return InkWell(
                                        onTap: () {
                                          if (snapshot.data.toString() ==
                                              "false") {
                                            // Validation: at least one field must be filled
                                            if (_emailController.text
                                                    .trim()
                                                    .isEmpty &&
                                                _phoneNumberController.text
                                                    .trim()
                                                    .isEmpty) {
                                              cubit.showCustomToast(
                                                message: AppStrings
                                                    .phoneEmailRequired
                                                    .tr(),
                                                color: ColorManager.lightError,
                                              );
                                              return;
                                            }
                                            print(
                                                'Email: ${_emailController.text.trim()}');
                                            print(
                                                'Phone: ${_phoneNumberController.text.trim()}');
                                            // Email takes priority if both are filled
                                            cubit.login(
                                              email: _emailController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? _emailController.text.trim()
                                                  : '',
                                              phoneNumber: _phoneNumberController
                                                      .text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? (_selectedCountryCode +
                                                      _phoneNumberController
                                                          .text
                                                          .trim()
                                                          .replaceAll(
                                                              RegExp(r'[^0-9]'),
                                                              ''))
                                                  : '',
                                            );
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: AppStrings.vpnDetect.tr(),
                                                backgroundColor:
                                                    ColorManager.lightGrey);
                                          }
                                        },
                                        child: state is LoginLoadingState
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  backgroundColor:
                                                      ColorManager.blueLight800,
                                                  color: ColorManager.white,
                                                ),
                                              )
                                            : Container(
                                                width: double.infinity,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color:
                                                      ColorManager.blueLight800,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                      color: ColorManager
                                                          .blueLight800,
                                                      width: 1.0),
                                                ),
                                                alignment: Alignment.center,
                                                child: Center(
                                                  child: Text(
                                                    AppStrings.login.tr(),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      );
                                    } else {
                                      return CircularProgressIndicator(
                                        color: ColorManager.lightGreen,
                                        backgroundColor: ColorManager.white,
                                      );
                                    }
                                  }),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () => Navigator.pushNamed(
                                    context, Routes.logincompanyRoute),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                        color: ColorManager.blueLight800,
                                        width: 1.0),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Text(
                                    AppStrings.requsterAsinfluComp.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: ColorManager.blueLight800),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              AppStrings.byLoggingIn.tr(),
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.grey),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                bool isArabic =
                                    _appPreferences.getAppLanguage() == 'ar';
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PolicyAndTerms(
                                      documentType: isArabic
                                          ? DocumentType.policyArabic
                                          : DocumentType.policyEnglish,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                AppStrings.privatPolicy.tr(),
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: ColorManager.blueLight800),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
