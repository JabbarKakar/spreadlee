import 'package:spreadlee/domain/tax_invoice_model.dart';

abstract class TaxInvoicesStates {}

class TaxInvoicesInitialState extends TaxInvoicesStates {}

class TaxInvoicesLoadingState extends TaxInvoicesStates {}

class TaxInvoicesSuccessState extends TaxInvoicesStates {
  final TaxInvoiceResponse taxInvoiceResponse;

  TaxInvoicesSuccessState(this.taxInvoiceResponse);
}

class TaxInvoicesEmptyState extends TaxInvoicesStates {}

class TaxInvoicesErrorState extends TaxInvoicesStates {
  final String error;

  TaxInvoicesErrorState(this.error);
}
