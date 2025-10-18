import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/presentation/customer/login/widget/login_header.dart';
import 'package:spreadlee/presentation/policy_and_terms/policy_and_terms.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/business/auth/widgets/register_type_dialog.dart';

import '../../../../core/app_prefs.dart';
import '../../../../core/di.dart';
import '../../../../core/languages_manager.dart';
import '../../../bloc/business/auth_bloc/auth_cubit.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';

class BusinessLoginView extends StatefulWidget {
  const BusinessLoginView({super.key});

  @override
  State<BusinessLoginView> createState() => _BusinessLoginViewState();
}

class _BusinessLoginViewState extends State<BusinessLoginView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AppPreferences _appPreferences = instance<AppPreferences>();
  bool _obscurePassword = true;

  // Use separate FocusNodes for each field.
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    context.read<AuthCubit>().fToast.init(context);
    super.initState();
  }

  bool isRTL() {
    return context.locale == ARABIC_LOCALE;
  }

  @override
  Widget build(BuildContext context) {
    var cubit = AuthCubit.get(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, LoginStates>(
        listener: (context, state) {
          if (state is LoginSuccessState) {
            if (cubit.loginModel?.message == "OTP sent successfully") {
              _appPreferences.setOTPExpiry(
                  key: "otpExpiry", value: cubit.loginModel!.otpExpiry ?? "");
              // Clear any cached contact info to prevent showing old data
              cubit.loginModel?.data?.phoneNumber = null;
              cubit.loginModel?.data?.identifier = null;

              // Store phone number from API response (phoneNumber field for business)
              if (cubit.loginModel?.data?.phoneNumber != null) {
                _appPreferences.setUserContact(
                    key: "userContact",
                    value: cubit.loginModel!.data!.phoneNumber!);
                if (kDebugMode) {
                  print(
                      "Business login - phone number set: ${cubit.loginModel!.data!.phoneNumber}");
                }
              }
              _appPreferences.setUsername(
                  key: "username", value: _usernameController.text);
              _appPreferences.setPassword(
                  key: "passwordGen", value: _passwordController.text);
              // Login model is already available in AuthCubit, no need to pass it
              Navigator.pushReplacementNamed(
                  context, Routes.compantotpVerifyRoute);
            } else if (cubit.loginModel?.message == "User not found") {
              cubit.showCustomToast(
                message: "User not found",
                color: ColorManager.lightError,
              );
            } else if (cubit.loginModel?.message ==
                "Username and password are required") {
              cubit.showCustomToast(
                message: "Username and password are required",
                color: ColorManager.lightError,
              );
            } else if (cubit.loginModel?.message == "OTP is still valid.") {
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
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppStrings.enterCodePhone.tr(),
                          style: const TextStyle(
                              fontSize: 11.0,
                              color: Colors.grey,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 18.0),
                        Text(
                          AppStrings.username.tr(),
                          style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4.0),
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          decoration: InputDecoration(
                            hintText: AppStrings.enterUsername.tr(),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12.0,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  const BorderSide(color: ColorManager.error),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.pleaseEnterUsername.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14.0),
                        Text(
                          AppStrings.password.tr(),
                          style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4.0),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: AppStrings.enterPassword.tr(),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12.0,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  const BorderSide(color: ColorManager.error),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.pleaseEnterPassword.tr();
                            }
                            if (value.length < 6) {
                              return AppStrings.passwordMinLength.tr();
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, Routes.forgotPasswordRoute);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 8),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 10.0),
                              child: FutureBuilder(
                                  future: Future.value(false),
                                  builder:
                                      (context, AsyncSnapshot<bool> snapshot) {
                                    if (snapshot.hasData) {
                                      return InkWell(
                                        onTap: () {
                                          if (snapshot.data.toString() ==
                                              "false") {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              cubit.loginBusiness(
                                                username:
                                                    _usernameController.text,
                                                passwordGen:
                                                    _passwordController.text,
                                              );
                                            }
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
                                                      fontSize: 14,
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
                            const SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.dontHaveAccount.tr(),
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins'),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const RegisterTypeDialog(),
                                    );
                                  },
                                  child: Text(
                                    AppStrings.register.tr(),
                                    style: TextStyle(
                                        color: ColorManager.blueLight800,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () => Navigator.pushNamed(
                                    context, Routes.loginCustomerRoute),
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
                                    AppStrings.registerAsCustomer.tr(),
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
