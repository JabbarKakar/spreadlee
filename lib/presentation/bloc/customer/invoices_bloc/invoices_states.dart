import 'package:spreadlee/domain/invoice_model.dart';

abstract class InvoicesStates {}

class InvoicesInitialState extends InvoicesStates {}

class InvoicesLoadingState extends InvoicesStates {}

class InvoicesSuccessState extends InvoicesStates {
  final List<InvoiceModel> invoices;

  InvoicesSuccessState(this.invoices);
}

class InvoicesErrorState extends InvoicesStates {
  final String error;

  InvoicesErrorState(this.error);
}

// Download States
class InvoiceDownloadLoadingState extends InvoicesStates {}

class InvoiceDownloadProgressState extends InvoicesStates {
  final double progress;
  InvoiceDownloadProgressState(this.progress);
}

class InvoiceDownloadSuccessState extends InvoicesStates {
  final String filePath;
  InvoiceDownloadSuccessState(this.filePath);
}

class InvoiceDownloadErrorState extends InvoicesStates {
  final String error;
  InvoiceDownloadErrorState(this.error);
}
