import 'package:equatable/equatable.dart';
import 'package:spreadlee/domain/invoice_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitialState extends WalletState {}

class WalletLoadingState extends WalletState {}

class WalletSuccessState extends WalletState {
  final List<InvoiceModel> invoices;
  final int selectedTabIndex;

  const WalletSuccessState({
    required this.invoices,
    this.selectedTabIndex = 0,
  });

  @override
  List<Object?> get props => [invoices, selectedTabIndex];

  WalletSuccessState copyWith({
    List<InvoiceModel>? invoices,
    int? selectedTabIndex,
  }) {
    return WalletSuccessState(
      invoices: invoices ?? this.invoices,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

class WalletErrorState extends WalletState {
  final String message;

  const WalletErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletClaimLoadingState extends WalletState {}

class WalletClaimSuccessState extends WalletState {
  final String message;

  const WalletClaimSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletClaimErrorState extends WalletState {
  final String message;

  const WalletClaimErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
