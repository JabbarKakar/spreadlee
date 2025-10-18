abstract class OtpStates {}

class OtpInitState extends OtpStates {}
class OtpChangeIsSecureState extends OtpStates{}
class OtpSuccessState extends OtpStates{}
class OtpLoadingState extends OtpStates{}
class OtpErrorState extends OtpStates{
  final String error;
  OtpErrorState(this.error);
}

class OtpResendInitState extends OtpStates {}
class OtpResendChangeIsSecureState extends OtpStates{}
class OtpResendSuccessState extends OtpStates{}
class OtpResendLoadingState extends OtpStates{}
class OtpResendErrorState extends OtpStates{
  final String error;
  OtpResendErrorState(this.error);
}
