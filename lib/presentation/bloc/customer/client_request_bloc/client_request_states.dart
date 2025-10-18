import 'package:spreadlee/domain/rejected_request_model.dart';

abstract class ClientRequestStates {}

class ClientRequestInitState extends ClientRequestStates {}

class ClientRequestLoadingState extends ClientRequestStates {}

class ClientRequestSuccessState extends ClientRequestStates {}

class ClientRequestErrorState extends ClientRequestStates {
  final String error;
  ClientRequestErrorState(this.error);
}

// Add Rejected Requests States
class RejectedRequestsLoadingState extends ClientRequestStates {}

class RejectedRequestsSuccessState extends ClientRequestStates {
  final List<RejectedRequestData> rejectedRequests;
  RejectedRequestsSuccessState(this.rejectedRequests);
}

class RejectedRequestsEmptyState extends ClientRequestStates {}

class RejectedRequestsErrorState extends ClientRequestStates {
  final String error;
  RejectedRequestsErrorState(this.error);
}
