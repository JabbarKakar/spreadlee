import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/login_model.dart';
import 'package:spreadlee/domain/otp_model.dart';
import 'package:spreadlee/domain/delete_account_model.dart';
import 'package:spreadlee/presentation/bloc/customer/otp_customer_bloc/otp_customer_states.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/services/force_logout_service.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/services/chat_service.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';

class OtpCubit extends Cubit<OtpStates> {
  OtpCubit() : super(OtpInitState());

  static OtpCubit get(context) => BlocProvider.of(context);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  FToast fToast = FToast();
  bool isSecure = true;
  void changeIsSecure() {
    isSecure = !isSecure;
    emit(OtpChangeIsSecureState());
  }

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

  showNoInternetMessage() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s10),
        color: ColorManager.lightGrey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi),
          const SizedBox(
            width: 12.0,
          ),
          Text(
            AppStrings.noInternetConnection.tr(),
            style: getBoldStyle(color: ColorManager.black),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  OtpModel? otpModel;
  Future<void> verifyOtp(
      {required String email,
      required String phoneNumber,
      required String otp}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(OtpLoadingState());

      Map<String, dynamic> otpData = {
        "otp": otp,
      };
      if (email.isNotEmpty && email.contains('@')) {
        otpData["email"] = email;
      } else if (phoneNumber.isNotEmpty) {
        otpData["phoneNumber"] = phoneNumber;
      }

      DioHelper.postData(endPoint: Constants.verifyOtp, data: otpData)
          .then((value) async {
        otpModel = OtpModel.fromJson(value!.data);

        if (otpModel?.message == "Phone number or email and OTP are required") {
        } else if (otpModel?.message == "User not found") {
        } else if (otpModel?.message == "OTP not generated or expired") {
        } else if (otpModel?.message == "OTP expired, request a new one") {
        } else if (otpModel?.message == "Invalid OTP") {
        } else {
          if (otpModel?.token != null) {
            print("Token: ${otpModel!.token}");
            await _secureStorage.write(
                key: 'token', value: otpModel!.token ?? "");
            await _secureStorage.write(
                key: 'role', value: otpModel!.data!.role ?? "");
            await _secureStorage.write(
                key: 'userId', value: otpModel!.data!.id ?? "");
            String? savedToken = await _secureStorage.read(key: 'token');
            String? savedRole = await _secureStorage.read(key: 'role');
            String? savedUserId = await _secureStorage.read(key: 'userId');
            Constants.token = savedToken ?? "";
            Constants.userId = savedUserId ?? "";
            Constants.role = savedRole ?? "";

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
          }

          _secureStorage.read(key: 'token');
        }

        emit(OtpSuccessState());
      }).catchError((error) {
        emit(OtpErrorState(error.toString()));
        print("Otp API Error: \${error.toString()}");
        if (kDebugMode) {
          print(error.toString());
          print("******* Otp ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  LoginModel? loginModel;

  Future<void> otpResend(
      {required String email, required String phoneNumber}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(OtpResendLoadingState());

      Map<String, dynamic> loginData = {};
      if (email.isNotEmpty) {
        loginData["email"] = email;
      } else if (phoneNumber.isNotEmpty) {
        loginData["phoneNumber"] = phoneNumber;
      }

      DioHelper.postData(endPoint: Constants.login, data: loginData)
          .then((value) {
        loginModel = LoginModel.fromJson(value!.data);
        if (kDebugMode) {
          print("message : ${loginModel!.message}");
        }
        if (loginModel?.message == "Phone number or email is required") {
        } else if (loginModel?.message == "OTP is still valid for minutes") {
        } else {
          _secureStorage.write(
              key: 'otpExpired', value: loginModel!.otpExpiry?.toString());
          String userContact = email.isNotEmpty ? email : phoneNumber;
          _secureStorage.write(key: 'userContact', value: userContact);
          if (kDebugMode) {
            print("User contact saved: $userContact"); // Debugging log
          }
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

  DeleteAccountModel? deleteAccountModel;
  Future<void> deleteAccount() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(OtpLoadingState());

      DioHelper.delete(endPoint: Constants.deleteAccount).then((value) async {
        deleteAccountModel = DeleteAccountModel.fromJson(value!.data);

        if (deleteAccountModel?.status == true) {
          // Best-effort: notify backend and disconnect sockets before clearing data
          try {
            await ChatService().shutdown();
          } catch (e) {
            if (kDebugMode) print('Error during chat shutdown: $e');
          }

          // Clear all user data
          await _secureStorage.delete(key: 'token');
          await _secureStorage.delete(key: 'userContact');
          await _secureStorage.delete(key: 'otpExpired');
          await _secureStorage.write(key: "isUserLoggedIn", value: "false");

          // Clear constants
          Constants.token = "";
          Constants.userContact = "";

          showCustomToast(
            message: AppStrings.successfully.tr(),
            color: ColorManager.success,
          );
        } else {
          showCustomToast(
            message: deleteAccountModel?.message ?? AppStrings.error.tr(),
            color: ColorManager.lightError,
          );
        }

        emit(OtpSuccessState());
      }).catchError((error) {
        emit(OtpErrorState(error.toString()));
        print("Delete Account API Error: ${error.toString()}");
        if (kDebugMode) {
          print(error.toString());
          print("******* Delete Account ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }
}
