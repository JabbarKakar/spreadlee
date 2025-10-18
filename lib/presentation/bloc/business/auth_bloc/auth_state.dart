part of 'auth_cubit.dart';

abstract class LoginStates {}

class LoginInitState extends LoginStates {}

class LoginChangeIsSecureState extends LoginStates {}

class LoginLoadingState extends LoginStates {}

class LoginSuccessState extends LoginStates {}

class LoginErrorState extends LoginStates {
  final String error;
  LoginErrorState(this.error);
}

// OTP States
class OtpLoadingState extends LoginStates {}

class OtpSuccessState extends LoginStates {}

class OtpErrorState extends LoginStates {
  final String error;
  OtpErrorState(this.error);
}

class OtpResendLoadingState extends LoginStates {}

class OtpResendSuccessState extends LoginStates {}

class OtpResendErrorState extends LoginStates {
  final String error;
  OtpResendErrorState(this.error);
}

class ForgotPasswordLoadingState extends LoginStates {}

class ForgotPasswordSuccessState extends LoginStates {}

class ForgotPasswordErrorState extends LoginStates {
  final String message;
  ForgotPasswordErrorState(this.message);
}

class RegistrationLoadingState extends LoginStates {}
class RegistrationSuccessState extends LoginStates {}
class RegistrationErrorState extends LoginStates {
  final String error;
  RegistrationErrorState(this.error);
}