import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/domain/customer_company_model.dart';
import 'package:spreadlee/presentation/bloc/customer/customer_company_bloc/customer_company_states.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constant.dart';
import '../../../../data/dio_helper.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';

class CustomerCompanyCubit extends Cubit<CustomerCompanyStates> {
  CustomerCompanyCubit() : super(CustomerCompanyInitState());
  static CustomerCompanyCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();
  bool isSecure = true;
  void changeIsSecure() {
    isSecure = !isSecure;
    emit(CustomerCompanyChangeIsSecureState());
  }

  List<CustomerCompanyDataModel> allCustomers = [];

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

  CustomerCompanyModel? customerCompanyModel;
  Future<void> getCustomerCompanyData() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CustomerCompanyLoadingState());

      DioHelper.getData(
        endPoint: Constants.customerCompany,
      ).then((value) {
        customerCompanyModel = CustomerCompanyModel.fromJson(value!.data);
        allCustomers = customerCompanyModel!.data ?? [];

        if (kDebugMode) {
          print("Customer Company Data: ${customerCompanyModel!.toJson()}");
        }

        emit(CustomerCompanySuccessState(customerCompanyModel!));
      }).catchError((error) {
        emit(CustomerCompanyErrorState(error.toString()));
        if (kDebugMode) {
          print("Customer Home API Error: ${error.toString()}");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> CreateCompany({
    required String countryName,
    required String companyName,
    required String commercialName,
    required String commercialNumber,
    required String vATNumber,
    required XFile vATCertificate,
    required XFile comRegForm,
    required String brief,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CustomerCompanyLoadingState());

      // Check if files exist
      if (!File(vATCertificate.path).existsSync()) {
        print(
            "Error: VAT Certificate file does not exist at ${vATCertificate.path}");
        return;
      }
      if (!File(comRegForm.path).existsSync()) {
        print(
            "Error: Commercial Register Form file does not exist at ${comRegForm.path}");
        return;
      }

      FormData formData = FormData.fromMap({
        "countryName": countryName,
        "companyName": companyName,
        "commercialName": commercialName,
        "commercialNumber": commercialNumber,
        "vATNumber": vATNumber,
        "vATCertificate": await MultipartFile.fromFile(
            File(vATCertificate.path).path,
            filename: vATCertificate.name),
        "comRegForm": await MultipartFile.fromFile(File(comRegForm.path).path,
            filename: comRegForm.name),
        "brief": brief,
      });

      DioHelper.postDataWithFiles(
              endPoint: Constants.createCustomerCompany, data: formData)
          .then((value) {
        customerCompanyModel = CustomerCompanyModel.fromJson(value!.data);
        print("Response: ${customerCompanyModel!.message}");

        emit(CustomerCompanySuccessState(customerCompanyModel!));
      }).catchError((error) {
        emit(CustomerCompanyErrorState(error.toString()));
        print("API Error: ${error.toString()}");
      });
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> EditCompany(
      {required String countryName,
      required String companyName,
      required String commercialName,
      required String commercialNumber,
      required String vATNumber,
      required XFile vATCertificate,
      required XFile comRegForm,
      required String brief,
      required String companyId}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CustomerCompanyLoadingState());

      // Construct FormData
      FormData formData = FormData.fromMap({
        "countryName": countryName,
        "companyName": companyName,
        "commercialName": commercialName,
        "commercialNumber": commercialNumber,
        "vATNumber": vATNumber,
        "vATCertificate": await MultipartFile.fromFile(vATCertificate.path,
            filename: vATCertificate.name),
        "comRegForm": await MultipartFile.fromFile(comRegForm.path,
            filename: comRegForm.name),
        "brief": brief,
      });

      DioHelper.updateDataWithFiles(
              endPoint: "${Constants.editCustomerCountry}/$companyId",
              data: formData)
          .then((value) {
        customerCompanyModel = CustomerCompanyModel.fromJson(value!.data);
        if (kDebugMode) {
          print("message : ${customerCompanyModel!.message}");
        }
        emit(CustomerCompanySuccessState(customerCompanyModel!));
      }).catchError((error) {
        emit(CustomerCompanyErrorState(error.toString()));
        if (kDebugMode) {
          print("API Error: ${error.toString()}");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }
}
