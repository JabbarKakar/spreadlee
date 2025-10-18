import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/tax_invoice_model.dart';
import 'package:spreadlee/presentation/bloc/business/tax_invoices_bloc/tax_invoices.states.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

class TaxInvoicesCubit extends Cubit<TaxInvoicesStates> {
  TaxInvoicesCubit() : super(TaxInvoicesInitialState());

  static TaxInvoicesCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
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

  Future<void> getTaxInvoices() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(TaxInvoicesLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getTaxInvoices,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final taxInvoiceResponse =
              TaxInvoiceResponse.fromJson(response!.data);

          if (taxInvoiceResponse.data?.isEmpty ?? true) {
            emit(TaxInvoicesEmptyState());
            showCustomToast(
              message: AppStrings.noInvoices.tr(),
              color: ColorManager.lightGrey,
            );
          } else {
            emit(TaxInvoicesSuccessState(taxInvoiceResponse));
          }
        } else {
          emit(TaxInvoicesEmptyState());
        }
      } catch (error) {
        if (kDebugMode) {
          print("Tax Invoices API Error Details: $error");
        }
        emit(TaxInvoicesErrorState(error.toString()));
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
}
