import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/customer/invoices_bloc/invoices_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/invoices_bloc/invoices_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/domain/invoice_model.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
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
        ? Routes.invoiceDetailsBankTransfer
        : Routes.invoiceDetails;

    Navigator.pushNamed(
      context,
      routeName,
      arguments: {'invoice': invoice},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvoicesCubit()..getInvoices(),
      child: Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(
                context, Routes.customerHomeRoute),
          ),
          title: Text(
            AppStrings.invoices.tr(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: BlocBuilder<InvoicesCubit, InvoicesStates>(
          builder: (context, state) {
            if (state is InvoicesLoadingState) {
              return Center(
                child: CircularProgressIndicator(
                  color: ColorManager.blueLight800,
                ),
              );
            } else if (state is InvoicesSuccessState) {
              // Sort invoices by creation date (newest first)
              final sortedInvoices = List<InvoiceModel>.from(state.invoices)
                ..sort((a, b) =>
                    b.invoiceCreationDate.compareTo(a.invoiceCreationDate));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = sortedInvoices[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorManager.pricetagYellow,
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
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Commercial Name: ${invoice.invoiceCompanyRef.commercialName}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('EEEE, MMM d, yyyy, HH:mm')
                                            .format(
                                                invoice.invoiceCreationDate),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
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
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
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
            } else if (state is InvoicesErrorState) {
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
