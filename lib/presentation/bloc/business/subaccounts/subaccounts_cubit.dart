import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/domain/subaccount_model.dart';
import 'package:spreadlee/presentation/bloc/business/subaccounts/subaccounts_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import '../../../../data/dio_helper.dart';
import '../../../resources/string_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';

class SubaccountsCubit extends Cubit<SubaccountsState> {
  SubaccountsCubit() : super(SubaccountsInitialState());
  static SubaccountsCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();

  void initFToast(BuildContext context) {
    fToast.init(context);
  }

  bool isSecure = true;
  void changeIsSecure() {
    isSecure = !isSecure;
    emit(SubaccountsInitialState());
  }

  List<SubaccountModel> allSubaccounts = [];

  showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
    required BuildContext context,
  }) {
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s8),
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

  showNoInternetMessage(BuildContext context) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s8),
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

    fToast.init(context);
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  SubaccountModel? subaccountModel;
  Future<void> getSubaccounts(BuildContext context) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(SubaccountsLoadingState());

      DioHelper.getData(
        endPoint: Constants.getSubaccounts,
      ).then((value) {
        subaccountModel = SubaccountModel.fromJson(value!.data);
        allSubaccounts = subaccountModel?.data
                ?.map((data) => SubaccountModel(
                      status: subaccountModel?.status,
                      message: subaccountModel?.message,
                      data: [data],
                    ))
                .toList() ??
            [];

        if (kDebugMode) {
          print("Subaccount Data: ${subaccountModel!.toJson()}");
        }

        emit(SubaccountsSuccessState(allSubaccounts));
      }).catchError((error) {
        emit(SubaccountsErrorState(error.toString()));
        if (kDebugMode) {
          print("Customer Home API Error: ${error.toString()}");
        }
      });
    } else {
      showNoInternetMessage(context);
    }
  }

  Future<bool> createSubaccount({
    required String username,
    required String passwordGen,
    required String phoneNumber,
    required BuildContext context,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(SubaccountsLoadingState());

      try {
        if (kDebugMode) {
          print(
              "Creating subaccount with data: {username: $username, phoneNumber: $phoneNumber}");
        }

        final response = await DioHelper.postData(
          endPoint: Constants.createSubaccount,
          data: {
            'username': username,
            'passwordGen': passwordGen,
            'phoneNumber': phoneNumber,
          },
        );

        final responseData = response!.data;

        if (responseData['status'] == false) {
          throw Exception(
              responseData['message'] ?? "Failed to create subaccount");
        }

        if (response.statusCode == 201 || response.statusCode == 200) {
          final subaccount = SubaccountModel(
            status: responseData['status'],
            message: responseData['message'],
            data: [Data.fromJson(responseData['data'])],
          );

          if (kDebugMode) {
            print("Parsed subaccount: ${subaccount.toJson()}");
          }

          emit(SubaccountsCreateSuccessState(subaccount.message ?? ""));
          showCustomToast(
            message: "Subaccount created successfully",
            color: ColorManager.success,
            context: context,
          );
          await getSubaccounts(context);
          return true;
        } else {
          throw Exception(
              responseData['message'] ?? "Failed to create subaccount");
        }
      } catch (error) {
        emit(SubaccountsCreateErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.alertError500,
          messageColor: ColorManager.white,
          context: context,
        );
        return false;
      }
    } else {
      showNoInternetMessage(context);
      return false;
    }
  }

  Future<void> deleteSubaccount({
    required String id,
    required BuildContext context,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(SubaccountsLoadingState());

      try {
        final response = await DioHelper.delete(
            endPoint: '${Constants.deleteSubaccount}$id');
        final responseData = response!.data;

        if (responseData['status'] == true) {
          showCustomToast(
            message:
                responseData['message'] ?? "Subaccount deleted successfully",
            color: ColorManager.success,
            context: context,
          );
          await getSubaccounts(context);
          emit(SubaccountsDeleteSuccessState(responseData['message'] ?? ""));
        } else {
          showCustomToast(
            message: responseData['message'] ?? AppStrings.error.tr(),
            color: ColorManager.lightError,
            context: context,
          );
          emit(SubaccountsDeleteErrorState(responseData['message'] ?? ""));
        }
      } catch (error) {
        emit(SubaccountsDeleteErrorState(error.toString()));
        if (kDebugMode) {
          print("Delete Account API Error: ${error.toString()}");
          print(error.toString());
          print("******* Delete Account ERROR ******");
        }
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          context: context,
        );
      }
    } else {
      showNoInternetMessage(context);
    }
  }

  Future<void> updateSubaccount({
    required String id,
    required String password,
    required String phoneNumber,
    required BuildContext context,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(SubaccountsLoadingState());

      try {
        final response = await DioHelper.updateData(
          endPoint: '${Constants.updateSubaccount}$id',
          data: {
            'password': password,
            'phoneNumber': phoneNumber,
          },
        );

        if (response?.statusCode == 200) {
          emit(SubaccountsUpdateSuccessState(response!.data['message']));
          // Refresh the subaccounts list after successful update
          await getSubaccounts(context);
        } else {
          throw Exception("All fields are required");
        }
      } catch (error) {
        emit(SubaccountsUpdateErrorState(error.toString()));
        showCustomToast(
          message: subaccountModel?.message ?? AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
          context: context,
        );
      }
    } else {
      showNoInternetMessage(context);
    }
  }
}
