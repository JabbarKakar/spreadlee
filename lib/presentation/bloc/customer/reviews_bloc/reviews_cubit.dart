import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/reviews_model.dart';
import 'package:spreadlee/presentation/bloc/customer/reviews_bloc/reviews_state.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit() : super(ReviewsInitialState());

  static ReviewsCubit get(context) => BlocProvider.of(context);
  FToast fToast = FToast();

  showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s10),
        color: color,
      ),
      child: Text(
        message,
        style: getBoldStyle(color: messageColor),
      ),
    );
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  showNoInternetMessage() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s10),
        color: ColorManager.lightGrey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi),
          const SizedBox(width: 12.0),
          Text(
            AppStrings.noInternetConnection.tr(),
            style: getBoldStyle(color: ColorManager.black),
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

  ReviewsResponse? reviewsResponse;

  Future<void> addReview({
    required String description,
    required String rating,
    required String title,
    required String companyId,
    required BuildContext context,
  }) async {
    // Initialize toast if not already initialized
    fToast.init(context);

    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ReviewsLoadingState());

      try {
        final data = {
          "description": description,
          "rating": rating,
          "title": title,
          "companyId": companyId,
        };

        final response = await DioHelper.postData(
          endPoint: Constants.addReview,
          data: data,
        );

        if (response?.data != null && response?.data['message'] != null) {
          showCustomToast(
            message: AppStrings.successfully.tr(),
            color: ColorManager.success,
            messageColor: ColorManager.white,
          );

          // Create a success response for the add review operation
          final successResponse = ReviewsResponse(
            success: true,
            averageRating: 0.0,
            reviews: [],
          );

          emit(ReviewsSuccessState(successResponse));
          return;
        } else {
          throw Exception("Failed to add review");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Add Review API Error: $error");
        }
        emit(ReviewsErrorState(error.toString()));

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

  Future<void> getReviews(String userId) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ReviewsLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: '${Constants.getReviews}/$userId',
        );

        if (response != null) {
          try {
            reviewsResponse = ReviewsResponse.fromJson(response.data ?? {});
            if (reviewsResponse?.success == true) {
              if (reviewsResponse?.reviews.isEmpty ?? true) {
                emit(ReviewsEmptyState());
              } else {
                emit(ReviewsSuccessState(reviewsResponse!));
              }
            } else {
              emit(ReviewsErrorState('Failed to load reviews'));
            }
          } catch (e) {
            emit(ReviewsErrorState("Error parsing response: ${e.toString()}"));
            if (kDebugMode) {
              print("Reviews Parse Error: ${e.toString()}");
            }
          }
        } else {
          emit(ReviewsErrorState("No response from server"));
        }
      } catch (error) {
        emit(ReviewsErrorState(error.toString()));
        if (kDebugMode) {
          print("Reviews API Error: ${error.toString()}");
        }
      }
    } else {
      showNoInternetMessage();
    }
  }
}
