import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/core/navigation/navigation_service.dart';
import 'wallet_states.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit() : super(WalletInitialState());

  static WalletCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();

  List<InvoiceModel> invoices = [];
  int selectedTabIndex = 0;

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      if (kDebugMode) {
        print("Toast context is null, skipping toast message: $message");
      }
      return;
    }

    // Initialize FToast with context
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      child: Text(
        message,
        style: TextStyle(
          color: messageColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  void showNoInternetMessage() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorManager.lightGrey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi),
          const SizedBox(width: 12.0),
          Text(
            AppStrings.noInternetConnection.tr(),
            style: TextStyle(
              color: ColorManager.black,
              fontWeight: FontWeight.bold,
            ),
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

  Future<void> getWalletInvoices() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(WalletLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.claimInvoices,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          if (response!.data is List) {
            invoices = (response.data as List)
                .map((item) => InvoiceModel.fromJson(item))
                .toList();
          } else if (response.data is Map<String, dynamic>) {
            final responseData = response.data as Map<String, dynamic>;

            // Check if the response indicates no invoices
            if (responseData['status'] == false &&
                responseData['message'] != null) {
              invoices = [];
            } else if (responseData['data'] is List) {
              invoices = (responseData['data'] as List)
                  .map((item) => InvoiceModel.fromJson(item))
                  .toList();
            } else {
              // If no data field or data is not a list, treat as empty
              invoices = [];
            }
          } else {
            throw Exception("Unexpected response format");
          }

          if (kDebugMode) {
            print("Wallet Invoices Data: $invoices");
          }

          // Apply initial filter based on selected tab
          final filteredInvoices = getFilteredInvoices();

          if (filteredInvoices.isEmpty) {
            showCustomToast(
              message: AppStrings.noInvoices.tr(),
              color: ColorManager.lightGrey,
            );
          }

          emit(WalletSuccessState(
            invoices: invoices,
            selectedTabIndex: selectedTabIndex,
          ));
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Wallet Invoices API Error Details: $error");
        }
        emit(WalletErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  void changeTab(int index) {
    selectedTabIndex = index;
    if (state is WalletSuccessState) {
      emit((state as WalletSuccessState).copyWith(
        selectedTabIndex: index,
      ));
    }
  }

  Future<void> claimInvoices(List<String> claimStatus) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(WalletClaimLoadingState());

      try {
        final response = await DioHelper.updateData(
          endPoint: Constants.claimRequest,
          data: {
            'invoiceIds': claimStatus,
            'claim_status': '1',
          },
        );

        if (kDebugMode) {
          print("Claim Response: ${response?.data}");
        }

        if (response?.statusCode == 200) {
          final responseData = response?.data;
          if (responseData != null && responseData['status'] == true) {
            final successful = responseData['data']['successful'] as List;
            final failed = responseData['data']['failed'] as List;

            if (failed.isNotEmpty) {
              showCustomToast(
                message: 'Some claims failed to process',
                color: ColorManager.warning,
                messageColor: ColorManager.white,
              );
            } else {
              showCustomToast(
                message: 'Claims submitted successfully',
                color: ColorManager.success,
                messageColor: ColorManager.white,
              );
            }

            emit(const WalletClaimSuccessState("Claims processed"));
            await getWalletInvoices();
          } else {
            throw Exception(
                responseData?['message'] ?? "Failed to process claims");
          }
        } else {
          throw Exception("Failed to claim invoices");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Claim API Error Details: $error");
        }
        emit(WalletClaimErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  List<InvoiceModel> getFilteredInvoices() {
    switch (selectedTabIndex) {
      case 0: // My Wallet
        return invoices
            .where((invoice) =>
                invoice.invoiceStatus == 'Paid' && invoice.claim_status == null)
            .toList();
      case 1: // Under Process
        return invoices
            .where((invoice) => invoice.claim_status == '1')
            .toList();
      case 2: // Completed
        return invoices
            .where((invoice) => invoice.claim_status == '2')
            .toList();
      default:
        return invoices;
    }
  }
}
