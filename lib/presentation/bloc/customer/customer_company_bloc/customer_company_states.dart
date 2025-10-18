

import '../../../../domain/customer_company_model.dart';

abstract class CustomerCompanyStates {}

class CustomerCompanyInitState extends CustomerCompanyStates {}
class CustomerCompanyChangeIsSecureState extends CustomerCompanyStates{}
class CustomerCompanySuccessState extends CustomerCompanyStates{
  final CustomerCompanyModel customerCompanyModel;

CustomerCompanySuccessState(this.customerCompanyModel);
}
class CreateCompanySuccessState extends CustomerCompanyStates{}
class CustomerCompanyLoadingState extends CustomerCompanyStates{}
class CustomerCompanyErrorState extends CustomerCompanyStates{
  final String error;
  CustomerCompanyErrorState(this.error);
}




