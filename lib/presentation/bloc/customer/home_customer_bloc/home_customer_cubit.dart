import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/add_customer_country_model.dart';
import 'package:spreadlee/domain/customer_home_model.dart';
import 'package:spreadlee/presentation/bloc/customer/home_customer_bloc/home_customer_states.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/style_manager.dart';
import '../../../resources/value_manager.dart';

class HomeCubit extends Cubit<HomeStates> {
  HomeCubit() : super(HomeInitState());
  static HomeCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();
  bool isSecure = true;
  void changeIsSecure() {
    isSecure = !isSecure;
    emit(HomeChangeIsSecureState());
  }

  List<CustomerData> allCustomers = [];
  List<CustomerData> filteredCustomers = [];

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

  CustomerCountryModel? customerCountryModel;
  Future<void> addCustomerCountry({required String customer_country}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      // Don't emit loading state here to avoid showing loading on home screen
      // The loading will be handled by getCustomerHomeData

      DioHelper.updateData(endPoint: Constants.addCustomerCountry, data: {
        'customer_country': customer_country,
      }).then((value) {
        if (value != null) {
          customerCountryModel = CustomerCountryModel.fromJson(value.data);
          if (kDebugMode) {
            print("message : ${customerCountryModel!.message}");
          }

          if (customerCountryModel?.message ==
              "customer_country updated successfully") {
            // Success - don't emit any state, let getCustomerHomeData handle it
            if (kDebugMode) {
              print("Country updated successfully");
            }
          } else if (customerCountryModel?.message ==
              "Unauthorized: No user ID found") {
            emit(HomeErrorState("Unauthorized: No user ID found"));
          } else if (customerCountryModel?.message ==
              "customer_country must be a string") {
            emit(HomeErrorState("customer_country must be a string"));
          }
        } else {
          emit(HomeErrorState("Failed to update customer country"));
        }
      }).catchError((error) {
        emit(HomeErrorState(error.toString()));
        if (kDebugMode) {
          print("Update Country API Error: ${error.toString()}");
          print("******* Update Country ERROR ******");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  CustomerHomeModel? customerHomeModel;
  Future<void> getCustomerHomeData(
      {String? marketing_fields, bool isRefreshing = false}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(isRefreshing ? HomeRefreshingState() : HomeLoadingState());

      Map<String, dynamic> requestData = {"marketing_fields": marketing_fields};

      DioHelper.getData(endPoint: Constants.getAllComp_Infl, query: requestData)
          .then((value) {
        if (value != null) {
          try {
            customerHomeModel = CustomerHomeModel.fromJson(value.data);
            if (customerHomeModel?.status == true) {
              allCustomers = customerHomeModel!.data ?? [];
              filteredCustomers = allCustomers;
              emit(HomeSuccessState(customerHomeModel!));
            } else {
              emit(
                  HomeErrorState(customerHomeModel?.message ?? "Server error"));
            }
          } catch (e) {
            emit(HomeErrorState("Error parsing response: ${e.toString()}"));
          }
        } else {
          emit(HomeErrorState("No response from server"));
        }
      }).catchError((error) {
        emit(HomeErrorState(error.toString()));
        if (kDebugMode) {
          print("Customer Home API Error: ${error.toString()}");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  // Function to filter customers based on search input
  void filterCustomers(String query) {
    if (query.isEmpty) {
      filteredCustomers =
          customerHomeModel?.data ?? []; // Reset to all customers
    } else {
      filteredCustomers = customerHomeModel?.data
              ?.where((customer) =>
                  (customer.publicName
                          ?.toLowerCase()
                          .contains(query.toLowerCase()) ??
                      false) ||
                  (customer.commercialName
                          ?.toLowerCase()
                          .contains(query.toLowerCase()) ??
                      false))
              .toList() ??
          [];
    }

    emit(HomeSuccessState(customerHomeModel!)); // Emit to trigger UI update
  }

  Future<void> filterCustomerHomeData(
      {String? country_code, List? cities, String? role}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(HomeLoadingState());

      Map<String, dynamic> queryParams = {};
      if (country_code != null) queryParams["country_code"] = country_code;
      if (cities != null && cities.isNotEmpty) queryParams["cities"] = cities;
      if (role != null) queryParams["role"] = role;

      DioHelper.getData(endPoint: Constants.homeFilter, query: queryParams)
          .then((value) {
        customerHomeModel = CustomerHomeModel.fromJson(value!.data);

        if (kDebugMode) {
          print("Filter Customer Data: ${customerHomeModel!.toJson()}");
        }

        emit(HomeSuccessState(customerHomeModel!));
      }).catchError((error) {
        emit(HomeErrorState(error.toString()));
        if (kDebugMode) {
          print("Customer Home API Error: ${error.toString()}");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> searchCustomerHomeData({
    String? search,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(HomeLoadingState());

      Map<String, dynamic> queryParams = {"search": search};

      DioHelper.getData(endPoint: Constants.homeSearch, query: queryParams)
          .then((value) {
        customerHomeModel = CustomerHomeModel.fromJson(value!.data);

        if (kDebugMode) {
          print("Search Customer Data: ${customerHomeModel!.toJson()}");
        }

        emit(HomeSuccessState(customerHomeModel!));
      }).catchError((error) {
        emit(HomeErrorState(error.toString()));
        if (kDebugMode) {
          print("Customer Home API Error: ${error.toString()}");
        }
      });
    } else {
      showNoInternetMessage();
    }
  }
}
