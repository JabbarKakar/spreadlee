import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/login_model.dart';
import '../../../../core/constant.dart';
import '../../../../domain/otp_model.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:spreadlee/services/force_logout_service.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/socket_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<LoginStates> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  LoginModel? loginModel;
  OtpModel? otpModel;
  FToast fToast = FToast();
  bool isSecure = true;

  AuthCubit() : super(LoginInitState());

  static AuthCubit get(context) => BlocProvider.of(context);

  showCustomToast(
      {required String message,
      required Color color,
      Color messageColor = Colors.black}) {
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
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  Future<void> loginBusiness({
    required String username,
    required String passwordGen,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(LoginLoadingState());

      Map<String, dynamic> loginData = {
        'username': username,
        'passwordGen': passwordGen,
      };

      DioHelper.postData(endPoint: Constants.loginBusiness, data: loginData)
          .then((value) async {
        loginModel = LoginModel.fromJson(value!.data);
        if (kDebugMode) {
          print("message : ${loginModel!.message}");
        }
        if (loginModel?.message == "Username and password are required") {
          showCustomToast(
            message: "Username and password are required",
            color: ColorManager.lightError,
          );
        } else if (loginModel?.message == "OTP is still valid.") {
          showCustomToast(
            message: "OTP is still valid for minutes",
            color: ColorManager.lightError,
          );
        } else if (loginModel?.message == "User not found") {
          showCustomToast(
            message: "User not found",
            color: ColorManager.lightError,
          );
        } else {
          // Save credentials and phone number
          await _secureStorage.write(key: 'username', value: username);
          await _secureStorage.write(key: 'passwordGen', value: passwordGen);

          await _secureStorage.write(
              key: 'otpExpired', value: loginModel!.otpExpiry?.toString());

          // Store the phone number from API response in the login model for OTP screen
          if (loginModel!.data?.phoneNumber != null) {
            // Business API returns phoneNumber directly, so we use that
            await _secureStorage.write(
                key: 'userContact', value: loginModel!.data!.phoneNumber!);
            if (kDebugMode) {
              print(
                  "Business phone number saved: ${loginModel!.data!.phoneNumber}");
              print("Login model updated: ${loginModel!.data!.toJson()}");
            }
          }

          // Update Constants
        }
        emit(LoginSuccessState());
      }).catchError((error) {
        emit(LoginErrorState(error.toString()));
        if (kDebugMode) {
          print("Login API Error: ${error.toString()}");
          print(error.toString());
          print("******* LOGIN ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  void showNoInternetMessage() {
    // Implement your no internet message logic here
  }

  Future<void> verifyOtp(
      {required String phoneNumber, required String otp}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(OtpLoadingState());

      Map<String, dynamic> otpData = {
        "otp": otp,
        "phoneNumber": phoneNumber,
      };

      try {
        final response = await DioHelper.postData(
            endPoint: Constants.verifyOtpBusiness, data: otpData);

        if (response == null || response.data == null) {
          emit(OtpErrorState("Invalid response from server"));
          showCustomToast(
            message: "Invalid response from server",
            color: ColorManager.lightError,
          );
          return;
        }

        if (kDebugMode) {
          print("OTP Response Data: ${response.data}");
          print("Data object: ${response.data['data']}");
          print("ID from response: ${response.data['data']['id']}");
        }

        otpModel = OtpModel.fromJson(response.data);

        if (otpModel == null) {
          emit(OtpErrorState("Failed to parse server response"));
          showCustomToast(
            message: "Failed to parse server response",
            color: ColorManager.lightError,
          );
          return;
        }

        if (kDebugMode) {
          print("Parsed OtpModel data: ${otpModel?.data?.toJson()}");
          print("Parsed user ID: ${otpModel?.data?.id}");
        }

        // Handle specific error messages
        if (otpModel?.message == "Phone number and OTP are required") {
          showCustomToast(
            message: "Phone number and OTP are required",
            color: ColorManager.lightError,
          );
        } else if (otpModel?.message == "User not found") {
          showCustomToast(
            message: "User not found",
            color: ColorManager.lightError,
          );
        } else if (otpModel?.message == "User not found or OTP not generated") {
          showCustomToast(
            message: "User not found or OTP not generated",
            color: ColorManager.lightError,
          );
        } else if (otpModel?.message == "OTP expired, request a new one") {
          showCustomToast(
            message: "OTP expired, request a new one",
            color: ColorManager.lightError,
          );
        } else if (otpModel?.message == "Invalid OTP") {
          showCustomToast(
            message: "Invalid OTP",
            color: ColorManager.lightError,
          );
        } else if (otpModel?.token != null) {
          // Success case - save token and role
          if (kDebugMode) {
            print("Storing user ID: ${otpModel!.data?.id}");
          }
          await _secureStorage.write(
              key: 'token', value: otpModel!.token ?? "");
          await _secureStorage.write(
              key: 'role', value: otpModel!.data?.role ?? "");
          await _secureStorage.write(
              key: 'userId', value: otpModel!.data?.id ?? "");
          await _secureStorage.write(
              key: 'commercialName',
              value: otpModel!.data?.commercialName ?? "");
          await _secureStorage.write(
              key: 'publicName', value: otpModel!.data?.publicName ?? "");
          await _secureStorage.write(
              key: 'photoUrl', value: otpModel!.data?.photoUrl ?? "");
          await _secureStorage.write(
              key: 'subMainAccount',
              value: otpModel!.data?.subMainAccount ?? "");
          await _secureStorage.write(
              key: 'username', value: otpModel!.data?.username ?? "");

          String? savedToken = await _secureStorage.read(key: 'token');
          String? savedRole = await _secureStorage.read(key: 'role');
          String? savedUserId = await _secureStorage.read(key: 'userId');
          String? savedCommercialName =
              await _secureStorage.read(key: 'commercialName');
          String? savedPublicName =
              await _secureStorage.read(key: 'publicName');
          String? savedPhotoUrl = await _secureStorage.read(key: 'photoUrl');
          String? savedSubMainAccount =
              await _secureStorage.read(key: 'subMainAccount');
          String? savedUsername = await _secureStorage.read(key: 'username');

          Constants.token = savedToken ?? "";
          Constants.role = savedRole ?? "";
          Constants.userId = savedUserId ?? "";
          Constants.commercialName = savedCommercialName ?? "";
          Constants.publicName = savedPublicName ?? "";
          Constants.photoUrl = savedPhotoUrl ?? "";
          Constants.subMainAccount = savedSubMainAccount ?? "";
          Constants.username = savedUsername ?? "";

          print("Constants.token: ${Constants.token}");
          print("Constants.role: ${Constants.role}");
          print("Constants.userId: ${Constants.userId}");
          print("Constants.commercialName: ${Constants.commercialName}");
          print("Constants.publicName: ${Constants.publicName}");
          print("Constants.photoUrl: ${Constants.photoUrl}");
          print("Constants.subMainAccount: ${Constants.subMainAccount}");
          print("Constants.username: ${Constants.username}");

          // Reinitialize force logout service with the new token
          ForceLogoutService.reinitialize();
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

          emit(OtpSuccessState());
          return;
        }

        // If we get here, something went wrong but wasn't caught above
        emit(OtpErrorState(otpModel?.message ?? "Unknown error occurred"));
        showCustomToast(
          message: otpModel?.message ?? "Unknown error occurred",
          color: ColorManager.lightError,
        );
      } catch (error) {
        String errorMessage = (error is DioException)
            ? (error.response?.data?['message'] ??
                error.message ??
                "Network error occurred")
            : error.toString();

        emit(OtpErrorState(errorMessage));
        showCustomToast(
          message: errorMessage,
          color: ColorManager.lightError,
        );

        if (kDebugMode) {
          print("Otp API Error: $errorMessage");
          print(error.toString());
          print("******* Otp ERROR ******");
        }
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> otpResend(
      {required String username, required String passwordGen}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(OtpResendLoadingState());

      Map<String, dynamic> loginData = {
        "username": username,
        "passwordGen": passwordGen,
      };

      DioHelper.postData(endPoint: Constants.loginBusiness, data: loginData)
          .then((value) {
        loginModel = LoginModel.fromJson(value!.data);
        if (kDebugMode) {
          print("message : ${loginModel!.message}");
        }
        if (loginModel?.message == "Username and password are required") {
        } else if (loginModel?.message == "OTP is still valid.") {
        } else {
          _secureStorage.write(
              key: 'otpExpired', value: loginModel!.otpExpiry?.toString());
        }

        emit(OtpResendSuccessState());
      }).catchError((error) {
        emit(OtpResendErrorState(error.toString()));
        print("Login API Error: \${error.toString()}");
        if (kDebugMode) {
          print(error.toString());
          print("******* LOGIN ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> forgotPassword({
    required String email,
    required String username,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ForgotPasswordLoadingState());

      Map<String, dynamic> data = {
        "email": email,
        "username": username,
      };

      DioHelper.updateData(endPoint: Constants.forgotPassword, data: data)
          .then((value) async {
        loginModel = LoginModel.fromJson(value!.data);
        if (kDebugMode) {
          print("message : ${loginModel!.message}");
        }
        if (loginModel?.message ==
            "Password reset successful. New password has been sent to your email.") {
          emit(ForgotPasswordSuccessState());
        } else {
          emit(
              ForgotPasswordErrorState(loginModel?.message ?? "Unknown error"));
        }
      }).catchError((error) {
        emit(ForgotPasswordErrorState(error.toString()));
        if (kDebugMode) {
          print("Forgot Password API Error: ${error.toString()}");
          print(error.toString());
          print("******* FORGOT PASSWORD ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  // Test function to verify marketing fields conversion
  void _testMarketingFieldsConversion() {
    if (kDebugMode) {
      print("=== TESTING MARKETING FIELDS CONVERSION ===");

      // Test case 1: List of strings
      List<String> testList = [
        "Radio Advertising",
        "Metro Stations Advertising",
        "Taxis & Buses Advertising"
      ];
      String result1 = testList.join(',');
      print("Test 1 - List to string: '$result1'");

      // Test case 2: Empty list
      List<String> emptyList = [];
      String result2 = emptyList.join(',');
      print("Test 2 - Empty list: '$result2'");

      // Test case 3: Single item
      List<String> singleList = ["Branding"];
      String result3 = singleList.join(',');
      print("Test 3 - Single item: '$result3'");

      print("==========================================");
    }
  }

  Future<FormData> registrationToFormData(Map<String, dynamic> data) async {
    // Test the conversion logic
    _testMarketingFieldsConversion();

    // Create form data map
    final formDataMap = <String, dynamic>{
      "companyName": data['companyName'],
      "commercialName": data['commercialName'],
      "role": data['role'],
      "publicName": data['publicName'],
      "fullName": data['fullName'],
      "commercialNumber": data['commercialNumber'],
      "vatNumber": data['vatNumber'],
      "isApproved": data['isApproved'].toString(),
      "selectedPriceTag": data['selectedPriceTag'],
      "email": data['email'],
      "phoneNumber": data['phoneNumber'],
    };

    // Handle files - they might be either XFile or MultipartFile
    if (data['vATCertificate'] != null) {
      if (data['vATCertificate'] is XFile) {
        final file = data['vATCertificate'] as XFile;
        if (!File(file.path).existsSync()) {
          print("Error: VAT Certificate file does not exist at ${file.path}");
          throw Exception("VAT Certificate file not found");
        }
        formDataMap['vATCertificate'] = await MultipartFile.fromFile(
          File(file.path).path,
          filename: file.name,
        );
      } else if (data['vATCertificate'] is MultipartFile) {
        // Clone the MultipartFile to avoid reuse issues
        final multipartFile = data['vATCertificate'] as MultipartFile;
        formDataMap['vATCertificate'] = multipartFile.clone();
      }
    }

    if (data['comRegForm'] != null) {
      if (data['comRegForm'] is XFile) {
        final file = data['comRegForm'] as XFile;
        if (!File(file.path).existsSync()) {
          print(
              "Error: Commercial Register Form file does not exist at ${file.path}");
          throw Exception("Commercial Register Form file not found");
        }
        formDataMap['comRegForm'] = await MultipartFile.fromFile(
          File(file.path).path,
          filename: file.name,
        );
      } else if (data['comRegForm'] is MultipartFile) {
        // Clone the MultipartFile to avoid reuse issues
        final multipartFile = data['comRegForm'] as MultipartFile;
        formDataMap['comRegForm'] = multipartFile.clone();
      }
    }

    if (data['pricingDetails'] != null) {
      if (data['pricingDetails'] is XFile) {
        final file = data['pricingDetails'] as XFile;
        if (!File(file.path).existsSync()) {
          print("Error: Pricing Details file does not exist at ${file.path}");
          throw Exception("Pricing Details file not found");
        }
        formDataMap['pricingDetails'] = await MultipartFile.fromFile(
          File(file.path).path,
          filename: file.name,
        );
      } else if (data['pricingDetails'] is MultipartFile) {
        // Clone the MultipartFile to avoid reuse issues
        final multipartFile = data['pricingDetails'] as MultipartFile;
        formDataMap['pricingDetails'] = multipartFile.clone();
      }
    }

    // Send marketing_fields as JSON array instead of comma-separated string
    if (data['marketing_fields'] is List) {
      final marketingFieldsList = data['marketing_fields'] as List;
      formDataMap['marketing_fields'] = marketingFieldsList;
    } else {
      formDataMap['marketing_fields'] = data['marketing_fields'] ?? [];
    }

    // Keep social_media_accs as JSON for complex structure
    formDataMap['social_media_accs'] =
        jsonEncode(data['social_media_accs'] ?? []);

    // Keep countries as JSON for complex structure
    formDataMap['countries'] = jsonEncode(data['countries']);

    // Send country_names as array (FormData will handle the formatting)
    if (data['country_names'] is List) {
      formDataMap['country_names'] = data['country_names'];
    } else {
      formDataMap['country_names'] = data['country_names'] ?? [];
    }

    // Send city_names as array (FormData will handle the formatting)
    if (data['city_names'] is List) {
      formDataMap['city_names'] = data['city_names'];
    } else {
      formDataMap['city_names'] = data['city_names'] ?? [];
    }

    // Focused marketing fields debug

    final formData = FormData.fromMap(formDataMap);

    return formData;
  }

  Future<void> registerBusiness({
    required Map<String, dynamic> registrationData,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(RegistrationLoadingState());

      final formData = await registrationToFormData(registrationData);

      DioHelper.postDataWithFiles(
              endPoint: Constants.registration, data: formData)
          .then((value) async {
        // You can parse a RegistrationModel here if you have one
        // final message = value?.data['message'] ?? '';
        loginModel = LoginModel.fromJson(value!.data);
        if (kDebugMode) {
          print("Registration message : ${loginModel!.message}");
        }
        if (loginModel!.message == "Some required fields are missing") {
          showCustomToast(
            message: "Some required fields are missing",
            color: ColorManager.lightError,
          );
        } else if (loginModel!.message == "User already exists") {
          showCustomToast(
            message: "User already exists",
            color: ColorManager.lightError,
          );
        } else {
          // Handle successful registration logic here
        }
        emit(RegistrationSuccessState());
      }).catchError((error) {
        emit(RegistrationErrorState(error.toString()));
        if (kDebugMode) {
          print("Registration API Error: $error");
          print(error.toString());
          print("******* REGISTRATION ERROR ******");
        }
        showCustomToast(
          message: "Registration failed: $error",
          color: ColorManager.lightError,
        );
      });
    } else {
      showNoInternetMessage();
    }
  }
}
