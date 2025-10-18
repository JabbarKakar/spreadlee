import 'package:spreadlee/domain/customer_home_model.dart';

abstract class HomeStates {}

class HomeInitState extends HomeStates {}

class HomeChangeIsSecureState extends HomeStates {}

class HomeSuccessState extends HomeStates {
  final CustomerHomeModel customerHomeModel;

  HomeSuccessState(this.customerHomeModel);
}

class HomeLoadingState extends HomeStates {}

class HomeRefreshingState extends HomeStates {}

class HomeErrorState extends HomeStates {
  final String error;
  HomeErrorState(this.error);
}

class HomeFilteredState extends HomeStates {
  final List<CustomerHomeModel> filteredCustomers;
  HomeFilteredState(this.filteredCustomers);
}
