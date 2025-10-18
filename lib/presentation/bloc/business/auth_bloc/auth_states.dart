abstract class BusinessAuthState {}

class BusinessAuthInitialState extends BusinessAuthState {}

class BusinessAuthLoadingState extends BusinessAuthState {}

class BusinessAuthSuccessState extends BusinessAuthState {
  final String token;

  BusinessAuthSuccessState(this.token);
}

class BusinessAuthErrorState extends BusinessAuthState {
  final String error;

  BusinessAuthErrorState(this.error);
}
