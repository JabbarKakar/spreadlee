abstract class LoginStates {}

class LoginInitState extends LoginStates {}
class LoginChangeIsSecureState extends LoginStates{}
class LoginSuccessState extends LoginStates{}
class LoginLoadingState extends LoginStates{}
class LoginErrorState extends LoginStates{
  final String error;
  LoginErrorState(this.error);
}
