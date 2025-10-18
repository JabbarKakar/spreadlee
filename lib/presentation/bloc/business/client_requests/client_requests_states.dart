import 'package:equatable/equatable.dart';
import 'package:spreadlee/domain/client_request_model.dart';

abstract class ClientRequestsState extends Equatable {
  const ClientRequestsState();

  @override
  List<Object?> get props => [];
}

class ClientRequestsInitialState extends ClientRequestsState {}

class ClientRequestsLoadingState extends ClientRequestsState {}

class ClientRequestsSuccessState extends ClientRequestsState {
  final List<ClientRequestModel> requests;

  const ClientRequestsSuccessState(this.requests);

  @override
  List<Object?> get props => [requests];
}

class ClientRequestsErrorState extends ClientRequestsState {
  final String message;

  const ClientRequestsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientRequestsAcceptSuccessState extends ClientRequestsState {
  final String message;

  const ClientRequestsAcceptSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientRequestsAcceptErrorState extends ClientRequestsState {
  final String message;

  const ClientRequestsAcceptErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientRequestsRejectSuccessState extends ClientRequestsState {
  final String message;

  const ClientRequestsRejectSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientRequestsRejectErrorState extends ClientRequestsState {
  final String message;

  const ClientRequestsRejectErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
