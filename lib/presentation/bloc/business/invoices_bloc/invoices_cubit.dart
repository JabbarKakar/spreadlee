import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/bloc/business/invoices_bloc/invoices_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';

class InvoicesBusinessCubit extends Cubit<InvoicesBusinessStates> {
  InvoicesBusinessCubit() : super(InvoicesBusinessInitialState());

  static InvoicesBusinessCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();
  BuildContext? _context;

  List<InvoiceModel> invoices = [];

  void init(BuildContext context) {
    _context = context;
    fToast.init(context);
  }

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    if (_context == null) {
      if (kDebugMode) {
        print('Warning: Context is null, cannot show toast');
      }
      return;
    }

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

      // Ensure fToast is properly initialized before showing toast
      if (fToast.context == null) {
        fToast.init(_context!);
      }

      fToast.showToast(
        child: toast,
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing toast: $e');
      }
    }
  }

  void showNoInternetMessage() {
    if (_context == null) {
      if (kDebugMode) {
        print('Warning: Context is null, cannot show no internet message');
      }
      return;
    }

    try {
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

      // Ensure fToast is properly initialized before showing toast
      if (fToast.context == null) {
        fToast.init(_context!);
      }

      fToast.showToast(
        child: toast,
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing no internet message: $e');
      }
    }
  }

  Future<void> getInvoices() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(InvoicesBusinessLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.invoicesBusiness,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
          print("Response type: ${response?.data.runtimeType}");
          if (response?.data is Map) {
            print(
                "Response data keys: ${(response?.data as Map).keys.toList()}");
          }
        }

        if (response != null && response.data != null) {
          if (response.data is List) {
            try {
              invoices = (response.data as List)
                  .map((item) => InvoiceModel.fromJson(item))
                  .toList();
            } catch (parseError) {
              if (kDebugMode) {
                print("Error parsing invoice list: $parseError");
              }
              throw Exception("Failed to parse invoice data: $parseError");
            }
          } else if (response.data is Map<String, dynamic>) {
            final responseData = response.data as Map<String, dynamic>;

            // Check if the response indicates no invoices
            if (responseData['status'] == false &&
                responseData['message'] != null) {
              invoices = [];
              try {
                showCustomToast(
                  message: AppStrings.noInvoices.tr(),
                  color: ColorManager.lightGrey,
                );
              } catch (error) {
                if (kDebugMode) {
                  print("Warning: Failed to show no invoices toast: $error");
                }
              }
            } else if (responseData['data'] is List) {
              try {
                invoices = (responseData['data'] as List)
                    .map((item) => InvoiceModel.fromJson(item))
                    .toList();
              } catch (parseError) {
                if (kDebugMode) {
                  print("Error parsing invoice data: $parseError");
                }
                throw Exception("Failed to parse invoice data: $parseError");
              }
            } else {
              // If no data field or data is not a list, treat as empty
              invoices = [];
              try {
                showCustomToast(
                  message: AppStrings.noInvoices.tr(),
                  color: ColorManager.lightGrey,
                );
              } catch (error) {
                if (kDebugMode) {
                  print("Warning: Failed to show no invoices toast: $error");
                }
              }
            }
          } else {
            throw Exception("Unexpected response format");
          }

          if (kDebugMode) {
            print("Invoices Data: $invoices");
          }

          if (invoices.isEmpty) {
            try {
              showCustomToast(
                message: AppStrings.noInvoices.tr(),
                color: ColorManager.lightGrey,
              );
            } catch (error) {
              if (kDebugMode) {
                print("Warning: Failed to show no invoices toast: $error");
              }
            }
          }

          emit(InvoicesBusinessSuccessState(invoices));
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Invoices API Error Details: $error");
          print("Error type: ${error.runtimeType}");
          if (error is Error) {
            print("Error stack trace: ${error.stackTrace}");
          }
        }
        emit(InvoicesBusinessErrorState(error.toString().isNotEmpty
            ? error.toString()
            : 'An unexpected error occurred. Please try again.'));
        try {
          showCustomToast(
            message: AppStrings.error.tr(),
            color: ColorManager.lightError,
            messageColor: ColorManager.white,
          );
        } catch (toastError) {
          if (kDebugMode) {
            print("Warning: Failed to show error toast: $toastError");
          }
        }
      }
    } else {
      try {
        showNoInternetMessage();
      } catch (error) {
        if (kDebugMode) {
          print("Warning: Failed to show no internet message: $error");
        }
      }
    }
  }

  Future<Map<String, dynamic>> invoicesData(Map<String, dynamic> data) async {
    // Create base data map
    final Map<String, dynamic> invoiceData = {
      "invoice_customer_company_ref": data['invoice_customer_company_ref'],
      "invoice_amount": data['invoice_amount'],
      "invoice_description": data['invoice_description'],
      "invoice_vat1": data['invoice_vat1'],
      "invoice_customer_ref": data['invoice_customer_ref'],
      "invoice_status": data['invoice_status'],
      "invoice_sender_name": data['invoice_sender_name'],
      "payment_method": data['payment_method'],
      "payment_status": data['payment_status'],
      "currency": data['currency'],
    };

    // Only add bank details if they exist and are not null
    if (data['invoiceBankName'] != null &&
        data['invoiceBankName'].toString().isNotEmpty) {
      invoiceData["invoiceBankName"] = data['invoiceBankName'];
    }
    if (data['invoiceAccountName'] != null &&
        data['invoiceAccountName'].toString().isNotEmpty) {
      invoiceData["invoiceAccountName"] = data['invoiceAccountName'];
    }
    if (data['invoiceAccountNo'] != null &&
        data['invoiceAccountNo'].toString().isNotEmpty) {
      invoiceData["invoiceAccountNo"] = data['invoiceAccountNo'];
    }
    if (data['invoiceAccountIban'] != null &&
        data['invoiceAccountIban'].toString().isNotEmpty) {
      invoiceData["invoiceAccountIban"] = data['invoiceAccountIban'];
    }
    if (data['invoiceSwift'] != null &&
        data['invoiceSwift'].toString().isNotEmpty) {
      invoiceData["invoiceSwift"] = data['invoiceSwift'];
    }

    return invoiceData;
  }

  Future<Map<String, dynamic>?> createInvoices({
    required Map<String, dynamic> invoicesData,
    required BuildContext context,
  }) async {
    // Initialize toast if not already initialized or if context has changed
    if (_context == null || _context != context) {
      init(context);
    }

    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(InvoicesBusinessLoadingState());

      try {
        final data = await this.invoicesData(invoicesData);

        if (kDebugMode) {
          print("Creating invoice with data: $data");
        }

        final response = await DioHelper.postData(
          endPoint: Constants.createinvoices,
          data: data,
        );

        if (kDebugMode) {
          print("Create invoice response: ${response?.data}");
        }

        if (response != null &&
            response.data != null &&
            response.data['status'] == true) {
          if (kDebugMode) {
            print(
                "Invoice created successfully, response data: ${response.data}");
            print("Response data type: ${response.data.runtimeType}");
            if (response.data is Map) {
              print("Response data keys: ${response.data.keys.toList()}");
            }
          }

          // Validate response structure
          if (response.data is! Map<String, dynamic>) {
            throw Exception(
                "Invalid response structure: expected Map but got ${response.data.runtimeType}");
          }

          // Validate required fields
          final data = response.data as Map<String, dynamic>;
          if (!data.containsKey('invoice') || data['invoice'] == null) {
            throw Exception(
                "Invalid response: missing or null 'invoice' field");
          }

          if (kDebugMode) {
            print("Invoice data validated successfully");
          }
          // Only show toast if we have a valid context
          if (_context != null) {
            try {
              final message = AppStrings.invoiceCreatedSuccessfully.tr();
              if (kDebugMode) {
                print("Success message: $message");
              }
              showCustomToast(
                message: message,
                color: ColorManager.success,
                messageColor: ColorManager.white,
              );
            } catch (toastError) {
              if (kDebugMode) {
                print("Warning: Failed to show success toast: $toastError");
              }
            }
          }

          // Refresh the invoices list after successful creation
          if (kDebugMode) {
            print("Starting to refresh invoices list...");
          }
          try {
            await getInvoices();
            if (kDebugMode) {
              print("Successfully refreshed invoices list");
            }
          } catch (refreshError) {
            if (kDebugMode) {
              print("Warning: Failed to refresh invoices list: $refreshError");
            }
            // Don't fail the invoice creation if refresh fails
          }
          if (kDebugMode) {
            print("Returning response data successfully");
          }
          return response.data;
        } else {
          if (response?.data == null) {
            throw Exception("No response data received from server");
          } else {
            throw Exception(
                "Invoice creation failed: ${response?.data['message'] ?? 'Unknown error'}");
          }
        }
      } catch (error) {
        if (kDebugMode) {
          print("Create Invoice API Error: $error");
          print("Error type: ${error.runtimeType}");
          if (error is Error) {
            print("Error stack trace: ${error.stackTrace}");
          }
        }
        emit(InvoicesBusinessErrorState(error.toString().isNotEmpty
            ? error.toString()
            : 'An unexpected error occurred while creating the invoice. Please try again.'));

        // Only show error toast if we have a valid context
        if (_context != null) {
          try {
            showCustomToast(
              message: AppStrings.error.tr(),
              color: ColorManager.lightError,
              messageColor: ColorManager.white,
            );
          } catch (toastError) {
            if (kDebugMode) {
              print("Warning: Failed to show error toast: $toastError");
            }
          }
        }
        return null;
      }
    } else {
      if (_context != null) {
        try {
          showNoInternetMessage();
        } catch (error) {
          if (kDebugMode) {
            print("Warning: Failed to show no internet message: $error");
          }
        }
      }
      return null;
    }
  }
}
