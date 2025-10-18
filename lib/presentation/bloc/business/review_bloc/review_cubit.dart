import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/reviews_model.dart';
import 'package:spreadlee/presentation/bloc/business/review_bloc/review.states.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';

import '../../../resources/color_manager.dart';

class ReviewCompanyCubit extends Cubit<ReviewStates> {
  ReviewCompanyCubit() : super(ReviewInitialState());

  static ReviewCompanyCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();

  List<ReviewModel> reviews = [];

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      child: Text(
        message,
        style: TextStyle(
          color: messageColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  void showNoInternetMessage() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorManager.lightGrey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi),
          const SizedBox(width: 12.0),
          Text(
            AppStrings.noInternetConnection.tr(),
            style: TextStyle(
              color: ColorManager.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  Future<void> getReviews() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ReviewLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getReviewCompany,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final reviewsResponse = ReviewsResponse.fromJson(response!.data);

          if (reviewsResponse.reviews.isEmpty) {
            emit(ReviewEmptyState());
            showCustomToast(
              message: AppStrings.noReviews.tr(),
              color: ColorManager.lightGrey,
            );
          } else {
            emit(ReviewSuccessState(reviewsResponse));
          }
        } else {
          emit(ReviewEmptyState());
        }
      } catch (error) {
        if (kDebugMode) {
          print("Reviews API Error Details: $error");
        }
        emit(ReviewErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }
}
