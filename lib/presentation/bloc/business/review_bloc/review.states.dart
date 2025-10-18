import 'package:spreadlee/domain/reviews_model.dart';

abstract class ReviewStates {}

class ReviewInitialState extends ReviewStates {}

class ReviewLoadingState extends ReviewStates {}

class ReviewSuccessState extends ReviewStates {
  final ReviewsResponse reviewsResponse;

  ReviewSuccessState(this.reviewsResponse);
}

class ReviewEmptyState extends ReviewStates {}

class ReviewErrorState extends ReviewStates {
  final String error;

  ReviewErrorState(this.error);
}
