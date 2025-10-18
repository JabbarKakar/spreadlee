import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/domain/customer_company_model.dart';
import 'package:spreadlee/domain/invoice_update_event.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/customer/invoices/service/invoice_download_service.dart';
import 'package:spreadlee/presentation/customer/invoices/service/invoice_payment_service.dart';
import 'package:spreadlee/presentation/customer/invoices/widget/payment_option_selection.dart';
import 'package:spreadlee/presentation/customer/payment_method/widget/hyperpay_payment.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_cubit.dart';
import 'package:spreadlee/data/models/card_model.dart';
import 'package:spreadlee/services/invoice_update_service.dart';
import 'package:spreadlee/config/invoice_update_config.dart';
import 'dart:async';

import '../../../bloc/customer/invoices_bloc/invoices_cubit.dart';
import '../../../resources/routes_manager.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({Key? key, required this.invoice})
      : super(key: key);

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isButtonVisible = true;
  bool _isProcessingPayment = false;

  // Real-time invoice update service
  final InvoiceUpdateService _invoiceUpdateService = InvoiceUpdateService();
  StreamSubscription<InvoiceUpdateEvent>? _invoiceUpdateSubscription;
  StreamSubscription<InvoiceModel>? _invoiceStatusSubscription;
  StreamSubscription<InvoiceModel>? _paymentCompletedSubscription;

  // Local invoice data that can be updated in real-time
  late InvoiceModel _currentInvoice;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
    _calculateRemainingTime();
    _startTimer();
    _initializeRealTimeUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _invoiceUpdateSubscription?.cancel();
    _invoiceStatusSubscription?.cancel();
    _paymentCompletedSubscription?.cancel();
    super.dispose();
  }

  /// Initialize real-time invoice updates
  Future<void> _initializeRealTimeUpdates() async {
    try {
      // Check if configuration is valid
      if (!InvoiceUpdateConfig.isConfigured) {
        print(
            'Configuration is incomplete. Cannot initialize real-time updates.');
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

      // Listen for updates specific to this invoice
      _invoiceUpdateService.addInvoiceListener(
        (_currentInvoice.invoiceId).toString(),
        _handleInvoiceUpdate,
      );

      if (kDebugMode) {
        print('Real-time invoice updates initialized successfully');
      }
    } catch (e) {
      // Show user-friendly error message
      if (mounted) {
        print('Real-time invoice updates failed to initialize');
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
    if (event.invoiceId == _currentInvoice.invoiceId ||
        event.invoiceId == _currentInvoice.id) {
      _updateInvoiceData(event.invoice);
    }
  }

  /// Handle invoice updates (for addInvoiceListener)
  void _handleInvoiceUpdate(InvoiceModel updatedInvoice) {
    setState(() {
      // Preserve original company details if the updated invoice has empty company details
      _currentInvoice =
          _preserveCompanyDetails(_currentInvoice, updatedInvoice);
    });

    // Update UI state
    _calculateRemainingTime();
    _updateButtonVisibility();
  }

  /// Handle invoice status changes
  void _handleInvoiceStatusChange(InvoiceModel updatedInvoice) {
    // Check if this is our invoice
    if (_currentInvoice.invoiceId == updatedInvoice.invoiceId ||
        _currentInvoice.id == updatedInvoice.id) {
      setState(() {
        // Preserve original company details if the updated invoice has empty company details
        _currentInvoice =
            _preserveCompanyDetails(_currentInvoice, updatedInvoice);
      });

      // Show status change notification
      // _showStatusChangeNotification(updatedInvoice.invoiceStatus);

      // Recalculate remaining time and button visibility
      _calculateRemainingTime();
      _updateButtonVisibility();
    }
  }

  /// Handle payment completion
  void _handlePaymentCompleted(InvoiceModel paidInvoice) {
    // Check if this is our invoice
    if (_currentInvoice.invoiceId == paidInvoice.invoiceId ||
        _currentInvoice.id == paidInvoice.id) {
      setState(() {
        // Preserve original company details if the updated invoice has empty company details
        _currentInvoice = _preserveCompanyDetails(_currentInvoice, paidInvoice);
      });

      // // Show payment success notification
      // _showPaymentSuccessNotification(paidInvoice);

      // Update UI state
      _calculateRemainingTime();
      _updateButtonVisibility();

      // // Navigate to review page after successful payment
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
            _preserveCompanyDetails(_currentInvoice, updatedInvoice);
      });

      // Update UI state
      _calculateRemainingTime();
      _updateButtonVisibility();
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
  //             'Payment completed successfully for invoice #${invoice.invoice_id}'),
  //         backgroundColor: Colors.green,
  //         duration: const Duration(seconds: 5),
  //       ),
  //     );
  //   }
  // }

  // /// Navigate to review page after successful payment
  // void _navigateToReviewAfterPayment() {
  //   // Wait a moment for the user to see the success message
  //   Future.delayed(const Duration(seconds: 2), () {
  //     if (mounted) {
  //       Navigator.pushNamed(context, Routes.addReviewRoute, arguments: {
  //         'influencerDoc':
  //             _convertToCompanyData(_currentInvoice.invoiceCompanyRef),
  //         'customerCompany': _convertToCustomerCompanyDataModel(
  //             _currentInvoice.invoiceCustomerCompanyRef),
  //       });
  //     }
  //   });
  // }

  /// Update button visibility based on current invoice status
  void _updateButtonVisibility() {
    setState(() {
      _isButtonVisible =
          _currentInvoice.invoiceStatus.toLowerCase() == 'unpaid';
    });
  }

  void _calculateRemainingTime() {
    final createdAt = _currentInvoice.createdAt;
    if (createdAt != null) {
      try {
        final createdAtDate = DateTime.parse(createdAt);
        final deadline = createdAtDate.add(const Duration(hours: 48));
        final now = DateTime.now();

        if (deadline.isAfter(now)) {
          _remainingTime = deadline.difference(now);
          _isButtonVisible = true;
        } else {
          _remainingTime = Duration.zero;
          _isButtonVisible = false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing createdAt date: $e');
        }
        _remainingTime = Duration.zero;
        _isButtonVisible = false;
      }
    } else {
      _remainingTime = Duration.zero;
      _isButtonVisible = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateRemainingTime();
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _handlePayInvoice() async {
    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get saved cards
      final paymentCubit = context.read<PaymentCubit>();
      await paymentCubit.getCards(context: context);
      final cards = paymentCubit.cards;

      // Show payment method selection
      final selectedMethod = await _showPaymentMethodSelection(cards);

      if (selectedMethod != null) {
        await _processPayment(selectedMethod, cards);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Payment error: $e');
      }

      // Provide more specific error messages
      String errorMessage = 'Payment failed';
      if (e.toString().contains('Failed to get checkout ID')) {
        errorMessage = 'Unable to initialize payment. Please try again.';
      } else if (e.toString().contains('Payment processing failed')) {
        errorMessage =
            'Payment processing error. Please check your payment method.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Payment failed: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
          content: Text('Payment failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<PaymentMethod?> _showPaymentMethodSelection(
      List<CardModel> cards) async {
    return showModalBottomSheet<PaymentMethod>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return PaymentOptionSelection(
          cards: cards,
          onPaymentMethodSelected: (method) {
            Navigator.pop(context, method);
          },
        );
      },
    );
  }

  Future<void> _processPayment(
      PaymentMethod paymentMethod, List<CardModel> cards) async {
    try {
      // Prepare checkout
      final checkoutResponse = await InvoicePaymentService.prepareCheckout(
        paymentMethod: paymentMethod,
        invoice: _currentInvoice,
        savedCards: cards,
      );

      if (checkoutResponse['id'] == null) {
        throw Exception('Failed to get checkout ID');
      }

      final checkoutId = checkoutResponse['id'];
      final InvoiceModel invoice = _currentInvoice;
      // Process payment
      await InvoicePaymentService.processPayment(
        paymentMethod: paymentMethod,
        checkoutId: checkoutId,
        invoice: _currentInvoice,
        context: context,
        onSuccess: (message) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
          // Update invoice status to paid
          // You would typically call an API to update the invoice status
          final result = await context.read<InvoicesCubit>().updateInvoices(
                invoiceId: _currentInvoice.id,
                invoice_status: 'Paid', // Change status to paid
                invoice_amount: _currentInvoice.invoiceAmount.toString(),
                context: context,
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
                      content: const Text('Invoice has been paid successfully'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            // _navigateToReviewAfterPayment();
                          },
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
                content: const Text('update failed - no response from server'),
                backgroundColor: ColorManager.lightError,
              ),
            );
          }
        },
        onError: (error) {
          // Provide more specific error messages based on the error content
          String errorMessage = error;
          if (error.contains('Payment is pending')) {
            errorMessage =
                'Payment is being processed. Please wait for confirmation.';
          } else if (error.contains('acquirer code')) {
            errorMessage =
                'Payment declined by bank. Please try a different payment method.';
          } else if (error.contains('Network') ||
              error.contains('connection')) {
            errorMessage =
                'Network error. Please check your internet connection and try again.';
          } else if (error.contains('timeout')) {
            errorMessage = 'Payment timeout. Please try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

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
      default:
        return 'Invoice status: $status';
    }
  }

  InvoiceCompanyRef? _convertToCompanyData(
      InvoiceCompanyRef invoiceCompanyRef) {
    return InvoiceCompanyRef(
      id: invoiceCompanyRef.id,
      companyName: invoiceCompanyRef.companyName,
      commercialName: invoiceCompanyRef.commercialName,
      commercialNumber:
          int.tryParse(invoiceCompanyRef.commercialNumber?.toString() ?? '0'),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentCubit(),
      child: Scaffold(
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
                invoice: _currentInvoice,
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
                    color: _getStatusColor(_currentInvoice.invoiceStatus),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    _getStatusMessage(_currentInvoice.invoiceStatus),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Invoice ID: ${_currentInvoice.invoice_id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1st Party Details
                      _buildSectionHeader('1st Party Details: (company)'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Company Name:',
                          _currentInvoice.invoiceCompanyRef.companyName),
                      _buildDetailRow(
                          'Commercial Number:',
                          _currentInvoice
                              .getFirstPartyCommercialNumberAsString()),
                      _buildDetailRow('Commercial Name:',
                          _currentInvoice.invoiceCompanyRef.commercialName),
                      _buildDetailRow('VAT Number:',
                          _currentInvoice.invoiceCompanyRef.vATNumber ?? '0'),
                      const SizedBox(height: 10),

                      // 2nd Party Details
                      _buildSectionHeader('2nd Party Details:'),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          'Company Name:',
                          _currentInvoice
                              .invoiceCustomerCompanyRef.companyName),
                      _buildDetailRow(
                          'Commercial Number:',
                          _currentInvoice
                              .getSecondPartyCommercialNumberAsString()),
                      _buildDetailRow(
                          'Commercial Name:',
                          _currentInvoice
                              .invoiceCustomerCompanyRef.commercialName),
                      _buildDetailRow(
                          'VAT Number:',
                          _currentInvoice.invoiceCustomerCompanyRef.vATNumber ??
                              '0'),
                      const SizedBox(height: 10),

                      // Service Description
                      _buildSectionHeader('Service Description:'),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          'Description', _currentInvoice.invoiceDescription),
                      _buildDetailRow('Amount:',
                          '${_currentInvoice.currency ?? 'SAR'} ${_currentInvoice.invoiceAmount.toStringAsFixed(2)}'),
                      _buildDetailRow(
                          'VAT:', '${_currentInvoice.invoiceVat1}%'),
                      _buildDetailRow('Total:',
                          '${_currentInvoice.currency ?? 'SAR'} ${_currentInvoice.invoiceTotal.toStringAsFixed(2)}'),

                      const SizedBox(height: 4),
                      const Divider(thickness: 1),
                      const SizedBox(height: 2),
                      _buildDetailRow(
                        'Grand total:',
                        '${_currentInvoice.currency ?? 'SAR'} ${_currentInvoice.invoiceGrandTotal.toStringAsFixed(3)}',
                      ),
                      const SizedBox(height: 24),

                      // Timer and Pay Button at the bottom
                      if (_isButtonVisible &&
                          _currentInvoice.invoiceStatus == 'Unpaid')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessingPayment
                                      ? null
                                      : _handlePayInvoice,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorManager.blueLight800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isProcessingPayment
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Processing...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Pay Invoice: ${_formatDuration(_remainingTime)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
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
      ),
    );
  }
}
