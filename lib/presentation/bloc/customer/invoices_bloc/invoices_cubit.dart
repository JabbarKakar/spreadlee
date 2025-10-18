import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/bloc/customer/invoices_bloc/invoices_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';

class InvoicesCubit extends Cubit<InvoicesStates> {
  InvoicesCubit() : super(InvoicesInitialState());

  static InvoicesCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();

  List<InvoiceModel> invoices = [];

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print("Error showing toast: $e");
      }
    }
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

  Future<void> getInvoices() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(InvoicesLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.invoices,
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
              showCustomToast(
                message: AppStrings.noInvoices.tr(),
                color: ColorManager.lightGrey,
              );
            } else if (responseData['data'] is List) {
              invoices = (responseData['data'] as List)
                  .map((item) => InvoiceModel.fromJson(item))
                  .toList();
            } else {
              // If no data field or data is not a list, treat as empty
              invoices = [];
              showCustomToast(
                message: AppStrings.noInvoices.tr(),
                color: ColorManager.lightGrey,
              );
            }
          } else {
            throw Exception("Unexpected response format");
          }

          if (kDebugMode) {
            print("Invoices Data: $invoices");
          }

          if (invoices.isEmpty &&
              !response.data.toString().contains('status')) {
            showCustomToast(
              message: AppStrings.noInvoices.tr(),
              color: ColorManager.lightGrey,
            );
          }

          emit(InvoicesSuccessState(invoices));
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Invoices API Error Details: $error");
        }
        emit(InvoicesErrorState(error.toString().isNotEmpty
            ? error.toString()
            : 'An unexpected error occurred. Please try again.'));
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

  Future<Map<String, dynamic>?> updateInvoices({
    required String invoiceId,
    required String invoice_status,
    required String invoice_amount,
    required BuildContext context,
    MultipartFile? bankTransferReceiptUploadedURL,
  }) async {
    // Initialize toast if not already initialized
    fToast.init(context);

    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(InvoicesLoadingState());

      try {
        // Create the data map for update
        final Map<String, dynamic> updateData = {
          "invoice_status": invoice_status,
          "invoice_amount": invoice_amount,
        };

        // Add bank transfer specific fields when uploading receipt
        if (bankTransferReceiptUploadedURL != null) {
          updateData["bankTransferReceiptUploadedURL"] =
              bankTransferReceiptUploadedURL;
          updateData["bankTransferReceiptDate"] =
              DateTime.now().toIso8601String();
          updateData["bankTransferReceiptStatus"] = "Uploaded";
          updateData["payment_method"] = "Bank Transfer";
          updateData["payment_status"] = "Pending";

          // Debug: Print the additional fields being sent
          if (kDebugMode) {
            print("Bank Transfer Fields Added:");
            print(
                "- bankTransferReceiptDate: ${updateData["bankTransferReceiptDate"]}");
            print(
                "- bankTransferReceiptStatus: ${updateData["bankTransferReceiptStatus"]}");
            print("- payment_method: ${updateData["payment_method"]}");
            print("- payment_status: ${updateData["payment_status"]}");
          }
        }

        final formData = FormData.fromMap(updateData);

        // Debug: print the FormData fields and files
        if (kDebugMode) {
          print("=== UPDATE INVOICE REQUEST ===");
          print("Invoice ID: $invoiceId");
          print("Endpoint: ${Constants.updateInvoics}/$invoiceId");
          print("FormData Fields:");
          for (var field in formData.fields) {
            print('  ${field.key} = ${field.value}');
          }
          print("FormData Files:");
          for (var file in formData.files) {
            print('  ${file.key} = ${file.value.filename}');
          }
          print("===============================");
        }

        // Try PUT request (which is what updateDataWithFiles uses)
        Response? response;
        try {
          response = await DioHelper.updateDataWithFiles(
            endPoint: "${Constants.updateInvoics}/$invoiceId",
            data: formData,
          );
        } catch (putError) {
          if (kDebugMode) {
            print("PUT request failed: $putError");
            print("Trying alternative field names...");
          }

          // Try with alternative field names that might be expected by the backend
          final Map<String, dynamic> alternativeData = {
            "invoice_status": invoice_status,
            "invoice_amount": invoice_amount,
          };

          if (bankTransferReceiptUploadedURL != null) {
            alternativeData["receipt_file"] = bankTransferReceiptUploadedURL;
            alternativeData["receipt_upload_date"] =
                DateTime.now().toIso8601String();
            alternativeData["receipt_status"] = "Uploaded";
            alternativeData["payment_method"] = "Bank Transfer";
            alternativeData["payment_status"] = "Pending";
          }

          final alternativeFormData = FormData.fromMap(alternativeData);

          if (kDebugMode) {
            print("Trying alternative field names:");
            for (var field in alternativeFormData.fields) {
              print('  ${field.key} = ${field.value}');
            }
          }

          response = await DioHelper.updateDataWithFiles(
            endPoint: "${Constants.updateInvoics}/$invoiceId",
            data: alternativeFormData,
          );
        }

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          final responseData = response!.data;
          if (responseData['status'] == true) {
            if (kDebugMode) {
              print("✅ Invoice update successful!");
              print("Updated invoice data: ${responseData}");
            }

            showCustomToast(
              message: AppStrings.successfully.tr(),
              color: ColorManager.success,
              messageColor: ColorManager.white,
            );

            // Refresh the invoices list
            await getInvoices();

            // Verify the update was successful by checking the updated invoice
            if (bankTransferReceiptUploadedURL != null) {
              await _verifyBankTransferUpdate(invoiceId);
            }

            emit(InvoicesSuccessState(invoices));
            return responseData;
          } else {
            if (kDebugMode) {
              print("❌ Invoice update failed - status: false");
              print("Error message: ${responseData['message']}");
            }
            throw Exception(
                responseData['message'] ?? "Failed to update invoice");
          }
        } else {
          if (kDebugMode) {
            print(
                "❌ Invoice update failed - HTTP status: ${response?.statusCode}");
            print("Response body: ${response?.data}");
          }
          throw Exception(
              "Failed to update invoice - Status: ${response?.statusCode}");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Update Invoice API Error: $error");
        }
        emit(InvoicesErrorState(error.toString().isNotEmpty
            ? error.toString()
            : 'An unexpected error occurred while updating the invoice. Please try again.'));

        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
        return null;
      }
    } else {
      showNoInternetMessage();
      return null;
    }
  }

  /// Verify that the bank transfer update was successful
  Future<void> _verifyBankTransferUpdate(String invoiceId) async {
    try {
      // Find the updated invoice in the list
      final updatedInvoice = invoices.firstWhere(
        (invoice) => invoice.id == invoiceId,
        orElse: () => throw Exception('Invoice not found'),
      );

      if (kDebugMode) {
        print("=== BANK TRANSFER UPDATE VERIFICATION ===");
        print("Invoice ID: ${updatedInvoice.id}");
        print("Invoice Status: ${updatedInvoice.invoiceStatus}");
        print(
            "Bank Transfer Receipt Status: ${updatedInvoice.bankTransferReceiptStatus}");
        print(
            "Bank Transfer Receipt Date: ${updatedInvoice.bankTransferReceiptDate}");
        print(
            "Bank Transfer Receipt URL: ${updatedInvoice.bankTransferReceiptUploadedURL}");
        print("Payment Method: ${updatedInvoice.paymentMethod}");
        print("Payment Status: ${updatedInvoice.paymentStatus}");
        print("==========================================");
      }

      // Check if the bank transfer fields were properly updated
      if (updatedInvoice.bankTransferReceiptUploadedURL != null &&
          updatedInvoice.bankTransferReceiptUploadedURL!.isNotEmpty) {
        if (kDebugMode) {
          print("✅ Bank transfer receipt URL was successfully updated");
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Bank transfer receipt URL was not updated");
        }
      }

      if (updatedInvoice.bankTransferReceiptDate != null) {
        if (kDebugMode) {
          print("✅ Bank transfer receipt date was successfully updated");
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Bank transfer receipt date was not updated");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error verifying bank transfer update: $e");
      }
    }
  }
}
