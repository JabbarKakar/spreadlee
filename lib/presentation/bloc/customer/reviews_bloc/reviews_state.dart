import 'package:spreadlee/domain/reviews_model.dart';

abstract class ReviewsState {}

class ReviewsInitialState extends ReviewsState {}

class ReviewsLoadingState extends ReviewsState {}

class ReviewsSuccessState extends ReviewsState {
  final ReviewsResponse reviewsResponse;

  ReviewsSuccessState(this.reviewsResponse);
}

class ReviewsErrorState extends ReviewsState {
  final String error;

  ReviewsErrorState(this.error);
}

class ReviewsEmptyState extends ReviewsState {}
