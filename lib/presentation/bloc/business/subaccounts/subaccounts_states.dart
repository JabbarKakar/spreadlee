import 'package:equatable/equatable.dart';
import 'package:spreadlee/domain/subaccount_model.dart';

abstract class SubaccountsState extends Equatable {
  const SubaccountsState();

  @override
  List<Object?> get props => [];
}

class SubaccountsInitialState extends SubaccountsState {}

class SubaccountsLoadingState extends SubaccountsState {}

class SubaccountsSuccessState extends SubaccountsState {
  final List<SubaccountModel> subaccounts;

  const SubaccountsSuccessState(this.subaccounts);

  @override
  List<Object?> get props => [subaccounts];
}

class SubaccountsErrorState extends SubaccountsState {
  final String message;

  const SubaccountsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class SubaccountsDeleteState extends SubaccountsState {
  final String message;

  const SubaccountsDeleteState(this.message);
}

class SubaccountsDeleteSuccessState extends SubaccountsState {
  final String message;

  const SubaccountsDeleteSuccessState(this.message);
}

class SubaccountsDeleteErrorState extends SubaccountsState {
  final String message;

  const SubaccountsDeleteErrorState(this.message);
}

class SubaccountsCreateState extends SubaccountsState {
  final String message;

  const SubaccountsCreateState(this.message);
}

class SubaccountsCreateSuccessState extends SubaccountsState {
  final String message;

  const SubaccountsCreateSuccessState(this.message);
}

class SubaccountsCreateErrorState extends SubaccountsState {
  final String message;

  const SubaccountsCreateErrorState(this.message);
}

class SubaccountsUpdateState extends SubaccountsState {
  final String message;

  const SubaccountsUpdateState(this.message);
}

class SubaccountsUpdateSuccessState extends SubaccountsState {
  final String message;

  const SubaccountsUpdateSuccessState(this.message);
}

class SubaccountsUpdateErrorState extends SubaccountsState {
  final String message;

  const SubaccountsUpdateErrorState(this.message);
}
