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
import 'package:spreadlee/presentation/resources/string_manager.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';
import 'login_customer_states.dart';

class LoginCubit extends Cubit<LoginStates> {
  LoginCubit() : super(LoginInitState());
  static LoginCubit get(context) => BlocProvider.of(context);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  FToast fToast = FToast();
  bool isSecure = true;
  void changeIsSecure() {
    isSecure = !isSecure;
    emit(LoginChangeIsSecureState());
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

  LoginModel? loginModel;
  Future<void> login(
      {required String email, required String phoneNumber}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(LoginLoadingState());

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
        } else if (loginModel?.message ==
            "Your account has been requested for deletion. Please contact support if you wishto reactivate your account.") {
        } else {
          _secureStorage.write(
              key: 'otpExpired', value: loginModel!.otpExpiry?.toString());
          String userContact = email.isNotEmpty ? email : phoneNumber;
          _secureStorage.write(key: 'userContact', value: userContact);

          // Store the actual user contact in the login model for OTP screen
          // The API returns identifier field, so we use that
          if (email.isNotEmpty) {
            loginModel!.data!.email = email;
            loginModel!.data!.identifier =
                email; // Also store in identifier for consistency
          } else {
            loginModel!.data!.phoneNumber = phoneNumber;
            loginModel!.data!.identifier =
                phoneNumber; // Also store in identifier for consistency
          }

          if (kDebugMode) {
            print("User contact saved: $userContact"); // Debugging log
            print(
                "Login model updated with contact: ${loginModel!.data!.toJson()}");
          }
        }

        emit(LoginSuccessState());
      }).catchError((error) {
        emit(LoginErrorState(error.toString()));
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
}
