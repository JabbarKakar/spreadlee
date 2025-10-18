import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/bloc/business/tax_invoices_bloc/tax_invoices_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/tax_invoices_bloc/tax_invoices.states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/values_manager.dart';
import 'package:spreadlee/presentation/widgets/empty_list_text.dart';
import 'package:spreadlee/presentation/widgets/loading_indicator.dart';
import '../../../resources/routes_manager.dart';
import '../widget/tax_invoice_container.dart';
import 'tax_invoice_info_view.dart';

class TaxInvoicesView extends StatefulWidget {
  const TaxInvoicesView({super.key});

  @override
  State<TaxInvoicesView> createState() => _TaxInvoicesViewState();
}

class _TaxInvoicesViewState extends State<TaxInvoicesView> {
  @override
  void initState() {
    super.initState();
    context.read<TaxInvoicesCubit>().getTaxInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: ColorManager.black,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.companyHomeRoute),
        ),
        title: Text(
          AppStrings.taxInvoicesTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: Constants.fontFamily,
                color: ColorManager.black,
                fontSize: AppSize.s16,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<TaxInvoicesCubit, TaxInvoicesStates>(
          builder: (context, state) {
            if (state is TaxInvoicesLoadingState) {
              return const Center(child: LoadingIndicator());
            }

            if (state is TaxInvoicesEmptyState) {
              return const EmptyListText(
                text: AppStrings.taxInvoicesEmpty,
                grey400: false,
              );
            }

            if (state is TaxInvoicesSuccessState) {
              final invoices = state.taxInvoiceResponse.data ?? [];
              if (invoices.isEmpty) {
                return const EmptyListText(
                  text: AppStrings.taxInvoicesEmpty,
                  grey400: false,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: AppPadding.p24,
                ),
                itemCount: invoices.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSize.s12),
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.p16,
                    ),
                    child: TaxInvoiceContainer(
                      invoiceId: invoice.invoice_id?.toString(),
                      name: invoice.buyer?.companyName,
                      date: invoice.invoice_creation_date,
                      appFeeVat: invoice.invoice_total?.toStringAsFixed(2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaxInvoiceInfoView(
                              invoice: invoice,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }

            if (state is TaxInvoicesErrorState) {
              return Center(
                child: Text(
                  state.error,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorManager.error,
                      ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
