import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/bloc/customer/otp_customer_bloc/otp_customer_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/otp_customer_bloc/otp_customer_states.dart';
import 'package:spreadlee/presentation/customer/verify_otp/otp_header.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/services/chat_service.dart';
import '../../../core/languages_manager.dart';
import '../../resources/color_manager.dart';
import '../../resources/string_manager.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:spreadlee/presentation/bloc/customer/home_customer_bloc/home_customer_cubit.dart';
import 'package:spreadlee/presentation/customer/home/widget/add_country.dart';
import 'package:spreadlee/services/socket_service.dart';

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ChatService _chatService = ChatService();
  final FocusNode _focusNode = FocusNode();
  late Timer _timer;
  int _secondsRemaining = 120; // 2 minutes
  String _userContact = ''; // Store user contact locally

  @override
  void dispose() {
    _focusNode.dispose();
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void initState() {
    // context.read<HomeCubit>().initializeNotification();
    context.read<OtpCubit>().fToast.init(context);
    startTimer();

    // Get user contact directly from login response data only
    final otpCubit = context.read<OtpCubit>();

    // Debug: Print login model data
    if (kDebugMode) {
      print("=== OTP VIEW DEBUG ===");
      print("Login model exists: ${otpCubit.loginModel != null}");
      if (otpCubit.loginModel != null) {
        print("Login model data: ${otpCubit.loginModel!.data?.toJson()}");
        print("Identifier: ${otpCubit.loginModel!.data?.identifier}");
        print("Email: ${otpCubit.loginModel!.data?.email}");
        print("Phone: ${otpCubit.loginModel!.data?.phoneNumber}");
      }
      print("=====================");
    }

    // Get from login model directly - prioritize identifier field from API response
    if (otpCubit.loginModel?.data?.identifier != null &&
        otpCubit.loginModel!.data!.identifier!.isNotEmpty) {
      setState(() {
        _userContact = otpCubit.loginModel!.data!.identifier!;
      });
      if (kDebugMode) {
        print(
            "Retrieved userContact from login response (identifier): ${otpCubit.loginModel!.data!.identifier}");
      }
    } else if (otpCubit.loginModel?.data?.email != null &&
        otpCubit.loginModel!.data!.email!.isNotEmpty) {
      setState(() {
        _userContact = otpCubit.loginModel!.data!.email!;
      });
      if (kDebugMode) {
        print(
            "Retrieved userContact from login response (email): ${otpCubit.loginModel!.data!.email}");
      }
    } else if (otpCubit.loginModel?.data?.phoneNumber != null &&
        otpCubit.loginModel!.data!.phoneNumber!.isNotEmpty) {
      setState(() {
        _userContact = otpCubit.loginModel!.data!.phoneNumber!;
      });
      if (kDebugMode) {
        print(
            "Retrieved userContact from login response (phone): ${otpCubit.loginModel!.data!.phoneNumber}");
      }
    } else {
      // If no contact info in login response, try to get from secure storage as fallback
      _secureStorage.read(key: "userContact").then((value) {
        setState(() {
          _userContact = value ?? "";
        });
        if (kDebugMode) {
          print(
              "No contact info found in login response, using fallback: $value");
        }
      });
    }

    // Retrieve token from secure storage
    _secureStorage.read(key: "token").then((value) {
      Constants.token = value ?? "";
      if (kDebugMode) {
        print("Retrieved userToken: $value");
      }
    });

    super.initState();
  }

  String getFormattedTime() {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool isEmail(String contact) {
    return contact.contains('@');
  }

  void resendOtp(OtpCubit cubit) {
    if (_formKey.currentState!.validate()) {
      cubit.otpResend(
        email: isEmail(_userContact) ? _userContact : '',
        phoneNumber: !isEmail(_userContact) ? _userContact : '',
      );
    }

    setState(() {
      _secondsRemaining = 120; // Reset timer
    });
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    var cubit = OtpCubit.get(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<OtpCubit, OtpStates>(
        listener: (context, state) {
          if (state is OtpSuccessState) {
            if (cubit.otpModel?.message == "OTP verified successfully") {
              _secureStorage.write(key: "isUserLoggedIn", value: "true");
              // Clear user contact from local state after successful verification
              setState(() {
                _userContact = "";
              });
              // Check if customer_country is null or empty
              if (Constants.baseUrl.isNotEmpty && Constants.token.isNotEmpty) {
                // Resume any suspended services so sockets can initialize
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
              if (cubit.otpModel?.data?.customer_country == null ||
                  cubit.otpModel?.data?.customer_country?.isEmpty == true) {
                print("🔍 Showing country selection dialog...");
                CountrySelectionDialog.show(context, (selectedCountry) async {
                  print("Selected Country: $selectedCountry");
                  try {
                    // Update the customer country first
                    await context
                        .read<HomeCubit>()
                        .addCustomerCountry(customer_country: selectedCountry);

                    // Wait a bit to ensure the country update is processed
                    await Future.delayed(const Duration(milliseconds: 500));

                    // Load data before navigation to ensure home screen has data
                    await context
                        .read<HomeCubit>()
                        .getCustomerHomeData(isRefreshing: true);

                    // Navigate to home after data is loaded
                    Navigator.pushReplacementNamed(
                        context, Routes.customerHomeRoute);
                  } catch (e) {
                    print("Error in country selection flow: $e");
                    // Still navigate to home even if there's an error
                    Navigator.pushReplacementNamed(
                        context, Routes.customerHomeRoute);
                  }
                });
              } else {
                // Load data first for existing users
                context.read<HomeCubit>().getCustomerHomeData().then((_) {
                  Navigator.pushReplacementNamed(
                      context, Routes.customerHomeRoute);
                });
              }
            } else if (cubit.otpModel?.message ==
                "Phone number or email and OTP are required") {
              cubit.showCustomToast(
                message: AppStrings.PhoneEmailOtpRequired.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.otpModel?.message == "User not found") {
              cubit.showCustomToast(
                message: AppStrings.userNotFound.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.otpModel?.message ==
                "OTP not generated or expired") {
              cubit.showCustomToast(
                message: AppStrings.otpNotGenerated.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.otpModel?.message ==
                "OTP expired, request a new one") {
              cubit.showCustomToast(
                message: AppStrings.otpExpired.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.otpModel?.message == "Invalid OTP") {
              cubit.showCustomToast(
                message: AppStrings.invalidOtp.tr(),
                color: ColorManager.lightError,
              );
            }
          }
          if (state is OtpErrorState) {
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
                              ? '${AppStrings.enter4DigitCode.tr()} $_userContact'
                              : AppStrings.enter4DigitCode.tr(),
                          style: const TextStyle(
                            fontSize: 11.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        PinCodeTextField(
                          length: 4, // 4-digit OTP
                          obscureText: false,
                          animationType: AnimationType.fade,
                          keyboardType: TextInputType.number,
                          controller: _otpController,
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
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          onCompleted: (value) {
                            print("Entered OTP: $value");
                          },
                          onChanged: (value) {},
                          appContext: context,
                        ),
                        // Clear Button
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
                                onTap: () => resendOtp(cubit),
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
                        // Timer or "Send Again" button
                        Center(
                          child: _secondsRemaining >
                                  0 // Show Timer if still counting
                              ? Text.rich(
                                  TextSpan(
                                    text: "OTP Expires:  ", // Regular text
                                    style: const TextStyle(
                                        fontSize: 16.0, color: Colors.grey),
                                    children: [
                                      TextSpan(
                                        text: getFormattedTime(), // Timer text
                                        style: const TextStyle(
                                          fontSize: 18.0, // Bigger size
                                          fontWeight:
                                              FontWeight.bold, // Bold font
                                          color: Colors
                                              .black, // Change color (example: red)
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                        ),

                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment
                              .end, // Moves content to the bottom
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
                                            if (_formKey.currentState!
                                                .validate()) {
                                              cubit.verifyOtp(
                                                email: _userContact,
                                                phoneNumber: _userContact,
                                                otp: _otpController.text.trim(),
                                              );
                                            }
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: AppStrings.vpnDetect.tr(),
                                                backgroundColor:
                                                    ColorManager.lightGrey);
                                          }
                                        },
                                        child: state is OtpLoadingState
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
                                                    AppStrings.confirm.tr(),
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
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                // Clear all cached data when changing number
                                await _secureStorage.delete(key: 'userContact');
                                await _secureStorage.delete(key: 'otpExpired');
                                // Clear login model in OTP cubit
                                context.read<OtpCubit>().loginModel = null;
                                setState(() {
                                  _userContact = "";
                                });
                                Navigator.pushReplacementNamed(
                                    context, Routes.loginCustomerRoute);
                              },
                              child: Text(
                                AppStrings.changeNumber.tr(),
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
    );
  }

  bool isRTL() {
    return context.locale == ARABIC_LOCALE;
  }
}
