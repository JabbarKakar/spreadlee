import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/bloc/business/invoices_bloc/invoices_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/invoices_bloc/invoices_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/values_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvoiceReleaseBankTransfer extends StatefulWidget {
  final String customerCompanyRef;
  final String customerRef;
  final String name;
  final String chatRef;
  final String chatClientRequestRef;
  final Map<String, dynamic>? companyId;
  final Map<String, dynamic>? chatCustomerCompanyRef;

  const InvoiceReleaseBankTransfer({
    super.key,
    required this.customerCompanyRef,
    required this.customerRef,
    required this.name,
    required this.chatRef,
    required this.chatClientRequestRef,
    this.companyId,
    this.chatCustomerCompanyRef,
  });

  @override
  State<InvoiceReleaseBankTransfer> createState() =>
      _InvoiceReleaseBankTransferState();
}

class _InvoiceReleaseBankTransferState
    extends State<InvoiceReleaseBankTransfer> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vatController = TextEditingController();

  String _amount = '0';
  String _vat = '0';
  final String _description = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _vatController.addListener(_onVatChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_amountController.text.isNotEmpty) {
      setState(() {
        _amount = _amountController.text;
      });
    } else {
      setState(() {
        _amount = '0';
      });
    }
  }

  void _onVatChanged() {
    if (_vatController.text.isNotEmpty) {
      double vatValue = double.tryParse(_vatController.text) ?? 0;
      if (vatValue > 100) {
        _vatController.text = '100';
        vatValue = 100;
      }
      setState(() {
        _vat = vatValue.toString();
      });
    } else {
      setState(() {
        _vat = '0';
      });
    }
  }

  double _calculateTotal() {
    double amount = double.tryParse(_amount) ?? 0;
    double vatPercentage = double.tryParse(_vat) ?? 0;
    return amount + (amount * vatPercentage / 100);
  }

  double _calculateGrandTotal() {
    return _calculateTotal();
  }

  Future<void> _submitInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final invoiceData = {
        'invoice_customer_company_ref': widget.customerCompanyRef,
        'invoice_customer_ref': widget.customerRef,
        'invoice_amount': _amount,
        'invoice_description': _descriptionController.text,
        'invoice_vat1': _vat,
        'invoice_status': 'Unpaid',
        'invoice_sender_name': widget.companyId?['commercialName'],
        'payment_method': 'Bank Transfer',
        'payment_status': 'Pending',
        'currency': 'SAR',
      };

      final response =
          await context.read<InvoicesBusinessCubit>().createInvoices(
                invoicesData: invoiceData,
                context: context,
              );

      if (mounted) {
        // Get the invoice data from the response
        final invoiceResponse = response?['invoice'];
        if (invoiceResponse != null) {
          // ✅ CRITICAL: Transform to backend-expected structure
          final invoiceAmount = invoiceResponse['invoice_amount'] ?? _amount;
          final vatPercentage = invoiceResponse['invoice_vat1'] ?? _vat;
          final grandTotal =
              invoiceAmount + (invoiceAmount * vatPercentage / 100);

          // Extract actual company data from widget parameters
          // First Party (Company creating the invoice)
          final companyName = widget.companyId?['companyName'] ??
              widget.companyId?['commercialName'] ??
              widget.companyId?['name'] ??
              'Company';
          final companyCommercialName = widget.companyId?['commercialName'] ??
              widget.companyId?['companyName'] ??
              widget.companyId?['name'] ??
              'Company';
          final companyCommercialNumber =
              widget.companyId?['commercialNumber']?.toString() ?? '';
          final companyVatNumber = widget.companyId?['vATNumber']?.toString() ??
              widget.companyId?['vatNumber']?.toString() ??
              '';

          // Second Party (Customer company)
          final customerCompanyData =
              widget.chatCustomerCompanyRef?['customer_companiesId'];
          final customerCompanyName = customerCompanyData?['companyName'] ??
              customerCompanyData?['commercialName'] ??
              customerCompanyData?['name'] ??
              'Customer Company';
          final customerCommercialName =
              customerCompanyData?['commercialName'] ??
                  customerCompanyData?['companyName'] ??
                  customerCompanyData?['name'] ??
                  'Customer Company';
          final customerCommercialNumber =
              customerCompanyData?['commercialNumber']?.toString() ?? '';
          final customerVatNumber =
              customerCompanyData?['vATNumber']?.toString() ??
                  customerCompanyData?['vatNumber']?.toString() ??
                  '';

          final invoiceData = {
            // ✅ ONLY send fields that match the backend schema exactly
            'invoiceId': invoiceResponse['_id'],
            'amount': invoiceAmount, // Base amount without VAT
            'grandTotal': grandTotal, // Total including VAT
            'description': invoiceResponse['invoice_description'] ??
                _descriptionController.text,
            'status':
                (invoiceResponse['invoice_status'] ?? 'Unpaid').toLowerCase(),
            'createdAt': invoiceResponse['invoice_creation_date'] ??
                DateTime.now().toIso8601String(),
            'expiresAt': invoiceResponse['payment_due_date'] ??
                DateTime.now().add(Duration(days: 30)).toIso8601String(),
            'vat': vatPercentage,
            'firstParty': {
              'name': companyCommercialName,
              'companyName': companyName,
              'commercialName': companyCommercialName,
              'commercialNumber': companyCommercialNumber,
              'vatNumber': companyVatNumber,
            },
            'secondParty': {
              'name': customerCommercialName,
              'companyName': customerCompanyName,
              'commercialName': customerCommercialName,
              'commercialNumber': customerCommercialNumber,
              'vatNumber': customerVatNumber,
            },
            'invoice_id': invoiceResponse['invoice_id'],
          };

          // Pop with the full invoice data
          Navigator.pop(context, invoiceData);
        } else {
          // If no invoice data, just pop
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Handle specific error cases
        if (errorMessage.contains('No internet connection')) {
          errorMessage = AppStrings.noInternetConnection.tr();
        } else if (errorMessage.contains('timeout')) {
          errorMessage = 'Connection timeout. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error creating invoice'),
            backgroundColor: ColorManager.lightError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.white,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: ColorManager.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: ColorManager.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.invoices.tr(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: Constants.fontFamily,
                color: ColorManager.primaryText,
                fontSize: AppSize.s16,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: BlocConsumer<InvoicesBusinessCubit, InvoicesBusinessStates>(
        listener: (context, state) {
          if (state is InvoicesBusinessErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:const Text( 'An error occurred while creating the invoice. Please try again.'),
                backgroundColor: ColorManager.lightError,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(AppSize.s16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        AppStrings.invoice.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: Constants.fontFamily,
                              fontSize: AppSize.s16,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSize.s16),

                    // 1st Party Details
                    _buildSectionHeader('1st Party Details: (company)'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Company Name:',
                        widget.companyId?['companyName'] ?? ''),
                    _buildDetailRow(
                        'Commercial Number:',
                        widget.companyId?['commercialNumber']?.toString() ??
                            ''),
                    _buildDetailRow('Commercial Name:',
                        widget.companyId?['commercialName'] ?? ''),
                    _buildDetailRow('VAT Number:',
                        widget.companyId?['vATNumber']?.toString() ?? ''),
                    const SizedBox(height: 10),

                    // 2nd Party Details
                    _buildSectionHeader('2nd Party Details:'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Company Name:',
                        widget.chatCustomerCompanyRef?['customer_companiesId']
                                ?['companyName'] ??
                            ''),
                    _buildDetailRow(
                        'Commercial Number:',
                        widget.chatCustomerCompanyRef?['customer_companiesId']
                                    ?['commercialNumber']
                                ?.toString() ??
                            ''),
                    _buildDetailRow(
                        'Commercial Name:',
                        widget.chatCustomerCompanyRef?['customer_companiesId']
                                ?['commercialName'] ??
                            ''),
                    _buildDetailRow(
                        'VAT Number:',
                        widget.chatCustomerCompanyRef?['customer_companiesId']
                                    ?['vATNumber']
                                ?.toString() ??
                            ''),

                    const SizedBox(height: 10),

                    // Service Description
                    _buildSectionHeader('Service Description:'),
                    const SizedBox(height: 10),
                    // Amount Input
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.amount}:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily: Constants.fontFamily,
                                  fontSize: AppSize.s12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: ColorManager.gray100,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(AppSize.s12),
                                    topLeft: Radius.circular(AppSize.s12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'SAR',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily: Constants.fontFamily,
                                        color: ColorManager.primaryText,
                                      ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                color: ColorManager.gray200,
                              ),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: ColorManager.gray100,
                                    borderRadius: BorderRadius.only(
                                      bottomRight: Radius.circular(AppSize.s12),
                                      topRight: Radius.circular(AppSize.s12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSize.s8),
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^[0-9]+(?:\\.[0-9]*)?')),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontFamily: Constants.fontFamily,
                                            color: ColorManager.gray400,
                                          ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: AppSize.s8),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.s16),

                    // Description Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.description.tr(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: Constants.fontFamily,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: AppSize.s8),
                        Container(
                          decoration: BoxDecoration(
                            color: ColorManager.gray100,
                            borderRadius: BorderRadius.circular(AppSize.s12),
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: AppStrings.writeHere.tr(),
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontFamily: Constants.fontFamily,
                                    color: ColorManager.gray500,
                                    fontSize: AppSize.s12,
                                  ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(AppSize.s12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.s16),

                    // VAT Input
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.vat}:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily: Constants.fontFamily,
                                  fontSize: AppSize.s12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: ColorManager.gray100,
                              borderRadius: BorderRadius.circular(AppSize.s12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSize.s8),
                            child: TextFormField(
                              controller: _vatController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^[0-9]+(?:\\.[0-9]*)?')),
                              ],
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontFamily: Constants.fontFamily,
                                      color: ColorManager.gray400,
                                    ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(
                                    left: AppSize.s8, top: AppSize.s14),
                                suffixIcon: const Icon(
                                  Icons.percent,
                                  color: ColorManager.primaryText,
                                  size: AppSize.s14,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter VAT percentage';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.s16),

                    // Totals Section
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${AppStrings.total}:',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontFamily: Constants.fontFamily,
                                      fontSize: AppSize.s12,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'SAR ${_calculateTotal().toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontFamily: Constants.fontFamily,
                                      color: ColorManager.gray500,
                                      fontSize: AppSize.s12,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.s16),

                    // Grand Total
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.grandTotal}:',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: Constants.fontFamily,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'SAR ${_calculateGrandTotal().toStringAsFixed(2)}',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: Constants.fontFamily,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 2nd Party Details
                    _buildSectionHeader('Bank Account Details'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Bank Name:', 'Riyadh Bank'),
                    _buildDetailRow('Account Name:',
                        'شركة الربط العالمي لخدمات الدعاية و الاعلان'),
                    _buildDetailRow('Account No:', '2581382949940'),
                    _buildDetailRow('IBAN:', 'SA0720000002581382949940'),
                    _buildDetailRow('SWIFT Code:', 'RIBLSARI'),
                    const SizedBox(height: 10),
                    // Bank Account Details

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitInvoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.blueLight800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSize.s8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                AppStrings.releaseInvoice.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontFamily: Constants.fontFamily,
                                      color: Colors.white,
                                      fontSize: AppSize.s16,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
