import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/domain/invoice_model.dart';

import '../../../bloc/business/invoices_bloc/invoices_cubit.dart';
import '../../../bloc/business/invoices_bloc/invoices_states.dart';

class InvoicesBusinessScreen extends StatefulWidget {
  const InvoicesBusinessScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesBusinessScreen> createState() => _InvoicesBusinessScreenState();
}

class _InvoicesBusinessScreenState extends State<InvoicesBusinessScreen> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'unpaid':
        return Colors.red; // Orange
      case 'expired':
        return ColorManager.lightGrey; // Red
      case 'under review':
        return ColorManager.primaryunderreview; // Blue
      default:
        return ColorManager.lightGrey;
    }
  }

  void _navigateToInvoiceDetails(InvoiceModel invoice) {
    final routeName = invoice.payment_method == 'Bank Transfer'
        ? Routes.invoiceDetailsBankTransferBusinessRoute
        : Routes.invoiceDetailsBusinessRoute;

    Navigator.pushNamed(
      context,
      routeName,
      arguments: {'invoice': invoice},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvoicesBusinessCubit()..getInvoices(),
      child: Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(
                context, Routes.companyHomeRoute),
          ),
          title: Text(
            AppStrings.invoices.tr(),
            style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins'),
          ),
        ),
        body: BlocBuilder<InvoicesBusinessCubit, InvoicesBusinessStates>(
          builder: (context, state) {
            if (state is InvoicesBusinessLoadingState) {
              return Center(
                child: CircularProgressIndicator(
                  color: ColorManager.blueLight800,
                ),
              );
            } else if (state is InvoicesBusinessSuccessState) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.invoices.length,
                itemBuilder: (context, index) {
                  final invoice = state.invoices[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorManager.custombordercard,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _navigateToInvoiceDetails(invoice),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                            fontFamily: 'Poppins'),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Commercial Name: ${invoice.invoiceCompanyRef.commercialName}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black87,
                                            fontFamily: 'Poppins'),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('EEEE, MMM d, yyyy, HH:mm')
                                            .format(
                                                invoice.invoiceCreationDate),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            invoice.invoiceStatus),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        invoice.invoiceStatus,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${invoice.currency ?? 'SAR'} ${invoice.invoiceGrandTotal.toStringAsFixed(3)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                          fontFamily: 'Poppins'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else if (state is InvoicesBusinessErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: ColorManager.lightError,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
