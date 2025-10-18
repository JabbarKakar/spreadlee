import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/otp_model.dart';
import 'package:spreadlee/domain/rejected_request_model.dart';
import 'package:spreadlee/presentation/bloc/customer/client_request_bloc/client_request_states.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';
import 'dart:convert';

class ClientRequestCubit extends Cubit<ClientRequestStates> {
  ClientRequestCubit() : super(ClientRequestInitState());

  static ClientRequestCubit get(context) => BlocProvider.of(context);
  FToast? fToast;

  void initFToast(BuildContext context) {
    fToast = FToast();
    fToast?.init(context);
  }

  bool isSecure = true;
  void changeIsSecure() {
    isSecure = !isSecure;
    emit(ClientRequestSuccessState());
  }

  showCustomToast(
      {required String message,
      required Color color,
      Color messageColor = Colors.black}) {
    if (fToast == null) {
      if (kDebugMode) {
        print("Toast not initialized. Message was: $message");
      }
      return;
    }

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

    fToast?.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  showNoInternetMessage() {
    if (fToast == null) {
      if (kDebugMode) {
        print(
            "Toast not initialized. No internet connection message not shown.");
      }
      return;
    }

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

    fToast?.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  OtpModel? clientRequestModel;
  Future<void> clientRequest(
      {required String customer_companyId, required String client}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ClientRequestLoadingState());

      Map<String, dynamic> clientRequestData = {
        "company": {
          "customer_companyId": customer_companyId,
        },
        "client": client,
      };

      DioHelper.postData(
              endPoint: Constants.createClientRequest, data: clientRequestData)
          .then((value) async {
        clientRequestModel = OtpModel.fromJson(value!.data);

        if (clientRequestModel?.message == "Missing required fields") {
        } else if (clientRequestModel?.message ==
            "A request for this client and company already exists") {
        } else if (clientRequestModel?.message ==
            "Error creating client request:") {
        } else if (clientRequestModel?.message == "Internal server error") {
        } else {}

        emit(ClientRequestSuccessState());
      }).catchError((error) {
        emit(ClientRequestErrorState(error.toString()));
        print("Client Request API Error: \${error.toString()}");
        if (kDebugMode) {
          print(error.toString());
          print("******* Client Request ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  RejectedRequestModel? rejectedRequestModel;
  List<RejectedRequestData> rejectedRequests = [];

  Future<void> getRejectedRequests() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(RejectedRequestsLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.rejectedCustomerRequest,
        );

        if (kDebugMode) {
          print("Raw Response Type: ${response?.data.runtimeType}");
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          Map<String, dynamic> jsonData;

          // Handle string response
          if (response!.data is String) {
            try {
              if (kDebugMode) {
                print("Attempting to parse string response");
              }
              jsonData = Map<String, dynamic>.from(
                  jsonDecode(response.data as String));
              if (kDebugMode) {
                print("Parsed JSON Data: $jsonData");
              }
            } catch (e) {
              if (kDebugMode) {
                print("JSON Parse Error: $e");
                print("Response string content: ${response.data}");
              }
              throw Exception("Failed to parse response string as JSON: $e");
            }
          } else if (response.data is Map<String, dynamic>) {
            if (kDebugMode) {
              print("Response is already a Map");
            }
            jsonData = response.data;
          } else {
            if (kDebugMode) {
              print("Unexpected response type: ${response.data.runtimeType}");
            }
            throw Exception("Unexpected response format");
          }

          if (kDebugMode) {
            print("Final JSON Data before model parsing: $jsonData");
          }

          rejectedRequestModel = RejectedRequestModel.fromJson(jsonData);
          rejectedRequests = rejectedRequestModel?.data ?? [];

          if (kDebugMode && rejectedRequestModel != null) {
            print("Rejected Requests Data: ${rejectedRequestModel!.toJson()}");
          }

          if (rejectedRequests.isEmpty) {
            emit(RejectedRequestsEmptyState());
            if (fToast != null) {
              showCustomToast(
                message: AppStrings.noRejectedRequests.tr(),
                color: ColorManager.lightGrey,
              );
            }
          } else {
            emit(RejectedRequestsSuccessState(rejectedRequests));
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Rejected Requests API Error Details: $error");
          print("Stack trace: ${StackTrace.current}");
        }
        emit(RejectedRequestsErrorState(error.toString()));
        if (fToast != null) {
          showCustomToast(
            message: AppStrings.error.tr(),
            color: ColorManager.lightError,
            messageColor: ColorManager.white,
          );
        }
      }
    } else {
      showNoInternetMessage();
    }
  }
}
