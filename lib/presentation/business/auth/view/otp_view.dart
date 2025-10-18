import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/customer/verify_otp/otp_header.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/core/di.dart';
import 'package:spreadlee/core/app_prefs.dart';
import 'package:spreadlee/presentation/bloc/business/auth_bloc/auth_cubit.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/socket_service.dart';

import '../../../resources/string_manager.dart';

class OtpBusinessView extends StatefulWidget {
  const OtpBusinessView({super.key});

  @override
  State<OtpBusinessView> createState() => _OtpBusinessViewState();
}

class _OtpBusinessViewState extends State<OtpBusinessView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _otpController;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ChatService _chatService = ChatService();
  String? _phoneNumber;
  String _userContact = ''; // Store user contact locally
  bool _isDisposed = false;
  AuthCubit? _authCubit;
  FToast? _fToast;
  bool _isInitialized = false;

  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _secondsRemaining = 120; // 2 minutes
  final AppPreferences _appPreferences = instance<AppPreferences>();

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startTimer();
    _loadPhoneNumber();

    _secureStorage.read(key: "token").then((value) {
      if (!_isDisposed) {
        Constants.token = value ?? "";
        if (kDebugMode) {
          print("Retrieved userToken: $value");
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _authCubit = context.read<AuthCubit>();
      _fToast = _authCubit?.fToast;
      _fToast?.init(context);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _focusNode.dispose();
    _otpController.dispose();
    _fToast = null;
    _authCubit = null;
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadPhoneNumber() async {
    if (_isDisposed) return;

    // Get user contact directly from login response data - prioritize identifier field from API response
    String? userContactFromResponse;

    // Debug: Print login model data
    if (kDebugMode) {
      print("=== BUSINESS OTP VIEW DEBUG ===");
      print("Login model exists: ${_authCubit?.loginModel != null}");
      if (_authCubit?.loginModel != null) {
        print("Login model data: ${_authCubit!.loginModel!.data?.toJson()}");
        print("Identifier: ${_authCubit!.loginModel!.data?.identifier}");
        print("Phone: ${_authCubit!.loginModel!.data?.phoneNumber}");
      }
      print("=================================");
    }

    // Prioritize phoneNumber field (from API response) for business
    if (_authCubit?.loginModel?.data?.phoneNumber != null &&
        _authCubit!.loginModel!.data!.phoneNumber!.isNotEmpty) {
      userContactFromResponse = _authCubit!.loginModel!.data!.phoneNumber;
    } else if (_authCubit?.loginModel?.data?.identifier != null &&
        _authCubit!.loginModel!.data!.identifier!.isNotEmpty) {
      userContactFromResponse = _authCubit!.loginModel!.data!.identifier;
    }

    if (userContactFromResponse != null) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _userContact = userContactFromResponse!;
        _phoneNumber = userContactFromResponse;
      });
      if (kDebugMode) {
        print(
            "Retrieved userContact from login response: $userContactFromResponse");
      }
    } else {
      // If no contact info in login response, try to get from secure storage as fallback
      if (!mounted || _isDisposed) return;
      _secureStorage.read(key: "userContact").then((value) {
        if (!mounted || _isDisposed) return;
        setState(() {
          _phoneNumber = value;
          _userContact = value ?? "";
        });
        if (kDebugMode) {
          print(
              "No contact info found in login response, using fallback: $value");
        }
      });
    }
  }

  void resendOtp() async {
    if (_isDisposed || !mounted || _authCubit == null) return;

    try {
      if (_formKey.currentState?.validate() ?? false) {
        final username = await _appPreferences.getUserContact(key: "username");
        final passwordGen =
            await _appPreferences.getUserContact(key: "passwordGen");

        if (!mounted || _isDisposed || _authCubit == null) return;

        if (username != null && passwordGen != null) {
          _authCubit!.otpResend(
            username: username,
            passwordGen: passwordGen,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in resendOtp: $e');
      }
      return;
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      _secondsRemaining = 120;
    });
    _startTimer();
  }

  void _showToast(
      {required String message,
      required Color color,
      Color messageColor = Colors.black}) {
    if (_isDisposed || _fToast == null || _authCubit == null) return;

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s10),
        color: color,
      ),
      child: Text(
        message,
        style: getBoldStyle(color: messageColor),
      ),
    );

    _fToast?.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed || _authCubit == null) {
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async {
        _timer?.cancel();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<AuthCubit, LoginStates>(
          listener: (context, state) {
            if (_isDisposed || _authCubit == null) return;

            if (state is OtpSuccessState) {
              if (_authCubit!.otpModel?.message ==
                  "OTP verified successfully") {
                _secureStorage.write(key: "isUserLoggedIn", value: "true");
                // Clear user contact from local state after successful verification
                setState(() {
                  _userContact = "";
                });
                if (Constants.baseUrl.isNotEmpty &&
                    Constants.token.isNotEmpty) {
                  try {
                    ChatService().resume();
                  } catch (e) {
                    if (kDebugMode) print('Error resuming ChatService: $e');
                  }
                  try {
                    SocketService().resume();
                  } catch (e) {
                    if (kDebugMode) print('Error resuming SocketService: $e');
                  }

                  _chatService.baseUrl = Constants.baseUrl;
                  _chatService.token = Constants.token;
                  _chatService.initializeSocket();
                }
                Navigator.pushReplacementNamed(
                    context, Routes.companyHomeRoute);
              } else if (_authCubit!.otpModel?.message ==
                  "Phone number and OTP are required") {
                _showToast(
                  message: AppStrings.PhoneEmailOtpRequired.tr(),
                  color: ColorManager.lightError,
                );
              } else if (_authCubit!.otpModel?.message == "User not found") {
                _showToast(
                  message: AppStrings.userNotFound.tr(),
                  color: ColorManager.lightError,
                );
              } else if (_authCubit!.otpModel?.message ==
                  "User not found or OTP not generated") {
                _showToast(
                  message: AppStrings.otpNotGenerated.tr(),
                  color: ColorManager.lightError,
                );
              } else if (_authCubit!.otpModel?.message ==
                  "OTP expired, request a new one") {
                _showToast(
                  message: AppStrings.otpExpired.tr(),
                  color: ColorManager.lightError,
                );
              } else if (_authCubit!.otpModel?.message == "Invalid OTP") {
                _showToast(
                  message: AppStrings.invalidOtp.tr(),
                  color: ColorManager.lightError,
                );
              }
            }
            if (state is OtpErrorState) {
              _showToast(
                  message: AppStrings.errorOnSendOtp.tr(),
                  color: ColorManager.lightError,
                  messageColor: ColorManager.white);
            }
          },
          builder: (context, state) {
            if (_isDisposed || _authCubit == null) {
              return const SizedBox.shrink();
            }

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
                          const OtpHeaderWidget(),
                          const SizedBox(height: 24.0),
                          Text(
                            AppStrings.otpVerify.tr(),
                            style: const TextStyle(
                              fontSize: 32.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            _userContact.isNotEmpty
                                ? '${AppStrings.enter4DigitCodeWithPhone.tr()} $_userContact'
                                : AppStrings.enter4DigitCodeWithPhone.tr(),
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          if (!_isDisposed && _authCubit != null)
                            PinCodeTextField(
                              length: 4,
                              obscureText: false,
                              animationType: AnimationType.fade,
                              keyboardType: TextInputType.number,
                              controller: _otpController,
                              enabled: !_isDisposed,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(8),
                                fieldHeight: 60,
                                fieldWidth: 70,
                                activeFillColor: Colors.grey[100],
                                inactiveFillColor: Colors.grey[100],
                                selectedFillColor: Colors.grey[100],
                                inactiveColor: Colors.grey[100],
                                activeColor: ColorManager.blueLight800,
                                selectedColor: ColorManager.blueLight800,
                              ),
                              animationDuration:
                                  const Duration(milliseconds: 300),
                              enableActiveFill: true,
                              onCompleted: (value) {
                                if (!_isDisposed &&
                                    mounted &&
                                    _authCubit != null) {
                                  print("Entered OTP: $value");
                                  _authCubit!.verifyOtp(
                                    phoneNumber: _userContact.isNotEmpty
                                        ? _userContact
                                        : (_phoneNumber ?? ""),
                                    otp: value.trim(),
                                  );
                                }
                              },
                              onChanged: (value) {
                                if (_isDisposed || !mounted) return;
                              },
                              appContext: context,
                            ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  _otpController.clear();
                                },
                                child: const Text(
                                  "Clear",
                                  style: TextStyle(
                                      fontSize: 13.0, color: Colors.black),
                                ),
                              ),
                              const Spacer(),
                              if (_secondsRemaining == 0)
                                InkWell(
                                  onTap: resendOtp,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Resend",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: ColorManager.blueLight800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.message,
                                        color: ColorManager.blueLight800,
                                        size: 14.0,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 15.0),
                          Center(
                            child: _secondsRemaining > 0
                                ? Text.rich(
                                    TextSpan(
                                      text: "OTP Expires:  ",
                                      style: const TextStyle(
                                          fontSize: 16.0, color: Colors.grey),
                                      children: [
                                        TextSpan(
                                          text: getFormattedTime(),
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                          ),
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
                                    builder: (context,
                                        AsyncSnapshot<bool> snapshot) {
                                      if (snapshot.hasData) {
                                        return InkWell(
                                          onTap: () {
                                            if (snapshot.data.toString() ==
                                                "false") {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                _authCubit!.verifyOtp(
                                                  phoneNumber: _userContact
                                                          .isNotEmpty
                                                      ? _userContact
                                                      : (_phoneNumber ?? ""),
                                                  otp: _otpController.text
                                                      .trim(),
                                                );
                                              }
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      AppStrings.vpnDetect.tr(),
                                                  backgroundColor:
                                                      ColorManager.lightGrey);
                                            }
                                          },
                                          child: state is OtpLoadingState
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    backgroundColor:
                                                        ColorManager
                                                            .blueLight800,
                                                    color: ColorManager.white,
                                                  ),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: ColorManager
                                                        .blueLight800,
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
                                                      AppStrings.confirm.tr(),
                                                      textAlign:
                                                          TextAlign.center,
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
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  // Clear all cached data when changing username
                                  await _secureStorage.delete(
                                      key: 'userContact');
                                  await _secureStorage.delete(
                                      key: 'otpExpired');
                                  await _secureStorage.delete(key: 'username');
                                  await _secureStorage.delete(
                                      key: 'passwordGen');
                                  // Clear login model in AuthCubit
                                  _authCubit?.loginModel = null;
                                  setState(() {
                                    _userContact = "";
                                  });
                                  Navigator.pushReplacementNamed(
                                      context, Routes.logincompanyRoute);
                                },
                                child: Text(
                                  AppStrings.changeUsername.tr(),
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16.0,
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
      ),
    );
  }

  String getFormattedTime() {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
