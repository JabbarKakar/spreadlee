import 'package:spreadlee/domain/invoice_model.dart';

abstract class InvoicesBusinessStates {}

class InvoicesBusinessInitialState extends InvoicesBusinessStates {}

class InvoicesBusinessLoadingState extends InvoicesBusinessStates {}

class InvoicesBusinessSuccessState extends InvoicesBusinessStates {
  final List<InvoiceModel> invoices;

  InvoicesBusinessSuccessState(this.invoices);
}

class InvoicesBusinessErrorState extends InvoicesBusinessStates {
  final String error;

  InvoicesBusinessErrorState(this.error);
}

// Download States
class InvoiceDownloadBusinessLoadingState extends InvoicesBusinessStates {}

class InvoiceDownloadBusinessProgressState extends InvoicesBusinessStates {
  final double progress;
  InvoiceDownloadBusinessProgressState(this.progress);
}

class InvoiceDownloadBusinessSuccessState extends InvoicesBusinessStates {
  final String filePath;
  InvoiceDownloadBusinessSuccessState(this.filePath);
}

class InvoiceDownloadBusinessErrorState extends InvoicesBusinessStates {
  final String error;
  InvoiceDownloadBusinessErrorState(this.error);
}
