import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/domain/customer_company_model.dart';
import 'package:spreadlee/domain/invoice_update_event.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/customer/invoices/service/invoice_download_service.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/bloc/customer/invoices_bloc/invoices_cubit.dart';
import 'package:spreadlee/services/invoice_update_service.dart';
import 'package:spreadlee/config/invoice_update_config.dart';
import 'dart:async';

class InvoiceDetailsBankTransferScreen extends StatefulWidget {
  const InvoiceDetailsBankTransferScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceDetailsBankTransferScreen> createState() =>
      _InvoiceDetailsBankTransferScreenState();
}

class _InvoiceDetailsBankTransferScreenState
    extends State<InvoiceDetailsBankTransferScreen> {
  // Real-time invoice update service
  final InvoiceUpdateService _invoiceUpdateService = InvoiceUpdateService();
  StreamSubscription<InvoiceUpdateEvent>? _invoiceUpdateSubscription;
  StreamSubscription<InvoiceModel>? _invoiceStatusSubscription;
  StreamSubscription<InvoiceModel>? _paymentCompletedSubscription;

  // Local invoice data that can be updated in real-time
  InvoiceModel? _currentInvoice;

  @override
  void initState() {
    super.initState();
    _initializeRealTimeUpdates();
  }

  @override
  void dispose() {
    _invoiceUpdateSubscription?.cancel();
    _invoiceStatusSubscription?.cancel();
    _paymentCompletedSubscription?.cancel();
    super.dispose();
  }

  /// Initialize real-time invoice updates
  Future<void> _initializeRealTimeUpdates() async {
    try {
      if (kDebugMode) {
        print('=== Initializing Real-time Invoice Updates ===');
        print('Config Status: ${InvoiceUpdateConfig.configurationStatus}');
        print('Socket Base URL: ${InvoiceUpdateConfig.socketBaseUrl}');
        print(
            'User Token: ${InvoiceUpdateConfig.userToken.isNotEmpty ? '***${InvoiceUpdateConfig.userToken.substring(InvoiceUpdateConfig.userToken.length - 4)}' : 'EMPTY'}');
        print('User ID: ${InvoiceUpdateConfig.userId}');
        print('User Role: ${InvoiceUpdateConfig.userRole}');
      }

      // Check if configuration is valid
      if (!InvoiceUpdateConfig.isConfigured) {
        if (kDebugMode) {
          print(
              'Configuration is incomplete. Cannot initialize real-time updates.');
          print('Missing: ${InvoiceUpdateConfig.configurationStatus}');
        }
        return;
      }

      await _invoiceUpdateService.initialize(
        baseUrl: InvoiceUpdateConfig.socketBaseUrl,
        token: InvoiceUpdateConfig.userToken,
        userId: InvoiceUpdateConfig.userId,
        userRole: InvoiceUpdateConfig.userRole,
      );

      // Set up listeners for real-time updates
      _setupInvoiceUpdateListeners();

      if (kDebugMode) {
        print('Real-time invoice updates initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize real-time updates: $e');
        print('This means invoice status changes will not be real-time.');
        print('Please check your login status and try again.');
      }

      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
            content:  Text(
                'Real-time updates unavailable. Invoice status may not update immediately.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Set up listeners for real-time invoice updates
  void _setupInvoiceUpdateListeners() {
    // Listen for general invoice updates
    _invoiceUpdateSubscription =
        _invoiceUpdateService.invoiceUpdateStream.listen(
      (event) {
        _handleInvoiceUpdateEvent(event);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to invoice updates: $error');
        }
      },
    );

    // Listen for invoice status changes
    _invoiceStatusSubscription =
        _invoiceUpdateService.invoiceStatusChangedStream.listen(
      (invoice) {
        _handleInvoiceStatusChange(invoice);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to invoice status changes: $error');
        }
      },
    );

    // Listen for payment completion
    _paymentCompletedSubscription =
        _invoiceUpdateService.paymentCompletedStream.listen(
      (invoice) {
        _handlePaymentCompleted(invoice);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to payment completion: $error');
        }
      },
    );
  }

  /// Handle invoice update events
  void _handleInvoiceUpdateEvent(InvoiceUpdateEvent event) {
    if (kDebugMode) {
      print('=== Received Invoice Update Event ===');
      print('Invoice ID: ${event.invoiceId}');
      print('Payment Completed: ${event.paymentCompleted}');
    }

    // Check if this update is for our invoice
    if (_currentInvoice != null &&
        (event.invoiceId == _currentInvoice!.invoiceId ||
            event.invoiceId == _currentInvoice!.id)) {
      _updateInvoiceData(event.invoice);
    }
  }

  /// Handle invoice status changes
  void _handleInvoiceStatusChange(InvoiceModel updatedInvoice) {
    if (kDebugMode) {
      print('=== Invoice Status Changed ===');
      print('Invoice ID: ${updatedInvoice.invoiceId}');
      print('New Status: ${updatedInvoice.invoiceStatus}');
    }

    // Check if this is our invoice
    if (_currentInvoice != null &&
        (_currentInvoice!.invoiceId == updatedInvoice.invoiceId ||
            _currentInvoice!.id == updatedInvoice.id)) {
      setState(() {
        // Preserve original company details if the updated invoice has empty company details
        _currentInvoice =
            _preserveCompanyDetails(_currentInvoice!, updatedInvoice);
      });

      // Show status change notification
      // _showStatusChangeNotification(updatedInvoice.invoiceStatus);
    }
  }

  /// Handle payment completion
  void _handlePaymentCompleted(InvoiceModel paidInvoice) {
    if (kDebugMode) {
      print('=== Payment Completed ===');
      print('Invoice ID: ${paidInvoice.invoiceId}');
      print('Status: ${paidInvoice.invoiceStatus}');
    }

    // Check if this is our invoice
    if (_currentInvoice != null &&
        (_currentInvoice!.invoiceId == paidInvoice.invoiceId ||
            _currentInvoice!.id == paidInvoice.id)) {
      setState(() {
        // Preserve original company details if the updated invoice has empty company details
        _currentInvoice =
            _preserveCompanyDetails(_currentInvoice!, paidInvoice);
      });

      // Show payment success notification
      // _showPaymentSuccessNotification(paidInvoice);

      // Navigate to review page after successful payment
      // _navigateToReviewAfterPayment();
    }
  }

  /// Update invoice data from real-time update
  void _updateInvoiceData(Map<String, dynamic> invoiceData) {
    try {
      final updatedInvoice = InvoiceModel.fromJson(invoiceData);

      setState(() {
        // Preserve original company details if the updated invoice has empty company details
        _currentInvoice =
            _preserveCompanyDetails(_currentInvoice!, updatedInvoice);
      });

      if (kDebugMode) {
        print('Invoice data updated via WebSocket');
        print('New Status: ${updatedInvoice.invoiceStatus}');
        print('New Amount: ${updatedInvoice.invoiceAmount}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating invoice data: $e');
      }
    }
  }

  // /// Show status change notification
  // void _showStatusChangeNotification(String newStatus) {
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Invoice status updated to: $newStatus'),
  //         backgroundColor: Colors.blue,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   }
  // }

  // /// Show payment success notification
  // void _showPaymentSuccessNotification(InvoiceModel invoice) {
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //             'Payment completed successfully for invoice #${invoice.invoiceId}'),
  //         backgroundColor: Colors.green,
  //         duration: const Duration(seconds: 5),
  //       ),
  //     );
  //   }
  // }

// // Navigate to review page after successful payment
//   void _navigateToReviewAfterPayment() {
//     // Wait a moment for the user to see the success message
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         Navigator.pushNamed(context, Routes.addReviewRoute, arguments: {
//           'influencerDoc':
//               _convertToCompanyData(_currentInvoice!.invoiceCompanyRef),
//           'customerCompany': _convertToCustomerCompanyDataModel(
//               _currentInvoice!.invoiceCustomerCompanyRef),
//         });
//       }
//     });
//   }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'unpaid':
        return Colors.red; // Red
      case 'expired':
        return ColorManager.lightGrey; // Grey
      case 'under review':
        return ColorManager.primaryunderreview; // Blue
      case 'under_review':
        return ColorManager.primaryunderreview; // Blue
      default:
        return ColorManager.lightGrey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'This invoice is paid';
      case 'unpaid':
        return 'This invoice is unpaid';
      case 'expired':
        return 'This invoice has expired';
      case 'under review':
        return 'This invoice is under review';
      case 'under_review':
        return 'This invoice is under review';
      default:
        return 'Invoice status: $status';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8BA793),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayInvoice(BuildContext context) async {
    try {
      print('Starting file picker...');
      // Pick file using FilePicker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;
        print('File selected: ${file.name}, path: $filePath');

        if (filePath != null) {
          // Create MultipartFile from the selected file
          final multipartFile = await MultipartFile.fromFile(
            filePath,
            filename: file.name,
          );
          print('MultipartFile created successfully');

          // Use the current invoice
          final InvoiceModel invoice = _currentInvoice!;
          print('Invoice ID: ${invoice.id}');

          // Call the updateInvoices method from the cubit
          print('Calling updateInvoices...');
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
          final result = await context.read<InvoicesCubit>().updateInvoices(
                invoiceId: invoice.id,
                invoice_status: 'under review', // Change status to under review
                invoice_amount: invoice.invoiceAmount.toString(),
                context: context,
                bankTransferReceiptUploadedURL: multipartFile,
              );
          // Dismiss loading dialog
          Navigator.of(context, rootNavigator: true).pop();

          if (result != null) {
            await showDialog(
              context: context,
              builder: (dialogContext) {
                return Dialog(
                  elevation: 0,
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  alignment: const AlignmentDirectional(0.0, 0.0)
                      .resolve(Directionality.of(context)),
                  child: GestureDetector(
                    onTap: () => FocusScope.of(dialogContext).unfocus(),
                    child: AlertDialog(
                      title: const Text('Success'),
                      content: const Text(
                          'Invoice has been under review now you can wait for the approval on 48 hours'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            Navigator.pushReplacementNamed(context, Routes.addReviewRoute,
                arguments: {
                  'influencerDoc':
                      _convertToCompanyData(invoice.invoiceCompanyRef),
                  'customerCompany': _convertToCustomerCompanyDataModel(
                      invoice.invoiceCustomerCompanyRef),
                });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Upload failed - no response from server'),
                backgroundColor: ColorManager.lightError,
              ),
            );
          }
        } else {
          print('File path is null');
        }
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error in _handlePayInvoice: $e');
      // Dismiss loading dialog if shown
      Navigator.of(context, rootNavigator: true).pop();
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error uploading receipt'),
          backgroundColor: ColorManager.lightError,
        ),
      );
    }
  }

  InvoiceCompanyRef? _convertToCompanyData(
      InvoiceCompanyRef invoiceCompanyRef) {
    return InvoiceCompanyRef(
      id: invoiceCompanyRef.id,
      companyName: invoiceCompanyRef.companyName,
      commercialName: invoiceCompanyRef.commercialName,
      commercialNumber: int.tryParse(invoiceCompanyRef.commercialNumber?.toString()  ?? '0'),
      publicName: invoiceCompanyRef.publicName,
      vATNumber: invoiceCompanyRef.vATNumber,
      photoUrl: invoiceCompanyRef.photoUrl,
      role: invoiceCompanyRef.role,
    );
  }

  CustomerCompanyDataModel? _convertToCustomerCompanyDataModel(
      InvoiceCustomerCompanyRef invoiceCustomerCompanyRef) {
    return CustomerCompanyDataModel(
      sId: invoiceCustomerCompanyRef.id,
      companyName: invoiceCustomerCompanyRef.companyName,
      commercialName: invoiceCustomerCompanyRef.commercialName,
      commercialNumber: int.tryParse(
          invoiceCustomerCompanyRef.commercialNumber?.toString() ?? '0'),
      vATNumber: int.tryParse(invoiceCustomerCompanyRef.vATNumber ?? '0'),
    );
  }

  /// Preserve original company details when updating invoice from socket events
  /// Socket events often don't include complete company details, so we merge them
  InvoiceModel _preserveCompanyDetails(
      InvoiceModel original, InvoiceModel updated) {
    // Check if the updated invoice has empty company details
    final hasEmptyCompanyDetails =
        (updated.invoiceCompanyRef.companyName.isEmpty &&
                original.invoiceCompanyRef.companyName.isNotEmpty) ||
            (updated.invoiceCustomerCompanyRef.companyName.isEmpty &&
                original.invoiceCustomerCompanyRef.companyName.isNotEmpty);

    if (hasEmptyCompanyDetails) {
      // Create new invoice with updated data but preserved company details
      return InvoiceModel(
        id: updated.id,
        invoiceCompanyRef: updated.invoiceCompanyRef.companyName.isEmpty
            ? original.invoiceCompanyRef
            : updated.invoiceCompanyRef,
        invoiceCustomerCompanyRef:
            updated.invoiceCustomerCompanyRef.companyName.isEmpty
                ? original.invoiceCustomerCompanyRef
                : updated.invoiceCustomerCompanyRef,
        invoiceAmount: updated.invoiceAmount,
        invoiceDescription: updated.invoiceDescription,
        invoiceVat1: updated.invoiceVat1,
        invoiceAppFee: updated.invoiceAppFee,
        invoiceVat2: updated.invoiceVat2,
        invoiceTotal: updated.invoiceTotal,
        invoiceGrandTotal: updated.invoiceGrandTotal,
        vat2Amount: updated.vat2Amount,
        appFeeAmount: updated.appFeeAmount,
        invoice_total_with_app_fee: updated.invoice_total_with_app_fee,
        invoiceCreationDate: updated.invoiceCreationDate,
        invoiceCustomerRef: updated.invoiceCustomerRef,
        invoiceStatus: updated.invoiceStatus,
        invoiceSubRef: updated.invoiceSubRef,
        bankTransferReceiptStatus: updated.bankTransferReceiptStatus,
        createdAt: updated.createdAt,
        updatedAt: updated.updatedAt,
        claimCreationDate: updated.claimCreationDate,
        invoicePdf: updated.invoicePdf,
        bankTransferReceiptDate: updated.bankTransferReceiptDate,
        bankTransferReceiptUploadedURL: updated.bankTransferReceiptUploadedURL,
        taxInvoicePdf: updated.taxInvoicePdf,
        invoiceSenderName: updated.invoiceSenderName,
        taxInvoiceStatus: updated.taxInvoiceStatus,
        paymentMethod: updated.paymentMethod,
        paymentDueDate: updated.paymentDueDate,
        paymentStatus: updated.paymentStatus,
        notes: updated.notes,
        currency: updated.currency,
        bankName: updated.bankName,
        accountName: updated.accountName,
        accountNumber: updated.accountNumber,
        iban: updated.iban,
        claim_status: updated.claim_status,
        invoice_id: updated.invoice_id,
        vATNumber: updated.vATNumber,
        invoiceBankName: updated.invoiceBankName,
        invoiceAccountName: updated.invoiceAccountName,
        invoiceAccountNo: updated.invoiceAccountNo,
        invoiceAccountIban: updated.invoiceAccountIban,
        invoiceSwift: updated.invoiceSwift,
        payment_method: updated.payment_method,
      );
    }

    // Return updated invoice as-is if company details are present
    return updated;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final InvoiceModel invoice = args['invoice'];

    // Initialize current invoice if not set
    if (_currentInvoice == null) {
      _currentInvoice = invoice;
    }

    print(
        'InvoiceDetailsBankTransferScreen: invoiceStatus=${_currentInvoice!.invoiceStatus}');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invoices',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined,
                color: Colors.black, size: 20),
            onPressed: () => InvoiceDownloadService.generateAndDownloadPdf(
              context: context,
              invoice: _currentInvoice!,
              isBankTransfer: true,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 110),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentInvoice!.invoiceStatus),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _getStatusMessage(_currentInvoice!.invoiceStatus),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Invoice ID: ${_currentInvoice!.invoice_id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('1st Party Details: (company)'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Company Name:',
                        _currentInvoice!.invoiceCompanyRef.companyName),
                    _buildDetailRow(
                        'Commercial Number:',
                        _currentInvoice!
                            .getFirstPartyCommercialNumberAsString()),
                    _buildDetailRow('Commercial Name:',
                        _currentInvoice!.invoiceCompanyRef.commercialName),
                    _buildDetailRow('VAT Number:',
                        _currentInvoice!.invoiceCompanyRef.vATNumber ?? '0'),
                    const SizedBox(height: 10),

                    // 2nd Party Details
                    _buildSectionHeader('2nd Party Details:'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Company Name:',
                        _currentInvoice!.invoiceCustomerCompanyRef.companyName),
                    _buildDetailRow(
                        'Commercial Number:',
                        _currentInvoice!
                            .getSecondPartyCommercialNumberAsString()),
                    _buildDetailRow(
                        'Commercial Name:',
                        _currentInvoice!
                            .invoiceCustomerCompanyRef.commercialName),
                    _buildDetailRow(
                        'VAT Number:',
                        _currentInvoice!.invoiceCustomerCompanyRef.vATNumber ??
                            '0'),
                    const SizedBox(height: 10),

                    // Service Description
                    _buildSectionHeader('Service Description:'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Description', _currentInvoice!.invoiceDescription),
                    _buildDetailRow('Amount:',
                        '${_currentInvoice!.currency ?? 'SAR'} ${_currentInvoice!.invoiceAmount.toStringAsFixed(2)}'),
                    _buildDetailRow('VAT:', '${_currentInvoice!.invoiceVat1}%'),
                    _buildDetailRow('Total:',
                        '${_currentInvoice!.currency ?? 'SAR'} ${_currentInvoice!.invoiceTotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    const Divider(thickness: 1),
                    const SizedBox(height: 2),
                    _buildDetailRow(
                      'Grand total:',
                      '${_currentInvoice!.currency ?? 'SAR'} ${_currentInvoice!.invoiceGrandTotal.toStringAsFixed(3)}',
                    ),
                    const SizedBox(height: 10),

                    // Bank Account Details
                    _buildSectionHeader('Bank Account Details'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Bank Name', 'Riyadh Bank'),
                    _buildDetailRow('Account Name',
                        'شركة الربط العالمي لخدمات الدعاية و الاعلان'),
                    _buildDetailRow('Account No', '2581382949940'),
                    _buildDetailRow(
                        'Account No. IBAN', 'SA0720000002581382949940'),
                    _buildDetailRow('Swift Code', 'RIBLSARI'),
                    const SizedBox(height: 10),
                    if (_currentInvoice!.invoiceStatus == 'Unpaid')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _handlePayInvoice(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorManager.blueLight800,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'upload bank transfer receipt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
