import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/models/card_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';
import 'package:spreadlee/presentation/resources/strings_manager.dart';


import '../../../../data/dio_helper.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_state.dart'
    as presentation_state;
import 'package:spreadlee/data/remote/hyperpay/hyperpay_registration_api.dart';

class PaymentCubit extends Cubit<presentation_state.PaymentState> {
  PaymentCubit() : super(const presentation_state.PaymentInitial());
  static PaymentCubit get(context) => BlocProvider.of(context);
  final FToast fToast = FToast();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isClosed = false;
  List<CardModel> cards = [];

  @override
  void emit(presentation_state.PaymentState state) {
    if (!_isClosed) {
      super.emit(state);
    } else {
      print('Attempted to emit state after cubit was closed: $state');
    }
  }

  @override
  Future<void> close() {
    _isClosed = true;
    return super.close();
  }

  void initFToast(BuildContext context) {
    if (context.mounted) {
      fToast.init(context);
    }
  }

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
    required BuildContext context,
  }) {
    if (!context.mounted) return;

    try {
      fToast.init(context);

      Widget toast = Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p8, vertical: AppPadding.p14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.s0),
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
    } catch (e) {
      if (kDebugMode) {
        print('Toast error: $e');
      }
    }
  }

  void showNoInternetMessage(BuildContext context) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p10, vertical: AppPadding.p14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s0),
        color: ColorManager.lightGrey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi),
          const SizedBox(width: AppSize.s12),
          Text(
            'No internet connection'.tr(),
            style: getBoldStyle(color: ColorManager.black),
          ),
        ],
      ),
    );

    fToast.init(context);
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  Future<void> prepareCardRegistration({
    required String cardType,
    required BuildContext context,
  }) async {
    try {
      // Check internet connectivity
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        emit(const presentation_state.CardRegistrationLoading());

        if (kDebugMode) {
          print("🔹 Preparing card registration for type: $cardType");
          print("🔹 Endpoint: ${Constants.prepareCardRegistration}");
          print("🔹 Request data: {\"cardType\": \"$cardType\"}");
        }

        // Prepare checkout registration
        final response = await DioHelper.postData(
          endPoint: Constants.prepareCardRegistration,
          data: {"cardType": cardType},
        );

        if (response == null) {
          if (kDebugMode) {
            print("❌ Response is null");
          }
          emit(const presentation_state.CardRegistrationError(
              message: 'Server response was null'));
          return;
        }

        if (response.data == null) {
          if (kDebugMode) {
            print("❌ Response data is null");
          }
          emit(const presentation_state.CardRegistrationError(
              message: 'Server response data was null'));
          return;
        }

        if (response.data is! Map) {
          if (kDebugMode) {
            print("❌ Response data is not a Map: ${response.data.runtimeType}");
          }
          emit(const presentation_state.CardRegistrationError(
              message: 'Invalid server response format'));
          return;
        }

        final responseData = response.data as Map;
        if (!responseData.containsKey('checkoutId')) {
          if (kDebugMode) {
            print("❌ Response missing checkoutId key");
            print("Available keys: ${responseData.keys.toList()}");
          }
          emit(const presentation_state.CardRegistrationError(
              message: 'Invalid server response format'));
          return;
        }

        final checkoutId = responseData['checkoutId'];
        if (checkoutId == null) {
          if (kDebugMode) {
            print("❌ checkoutId is null");
          }
          emit(const presentation_state.CardRegistrationError(
              message: 'Checkout ID is missing from response'));
          return;
        }

        if (responseData['status'] != true) {
          if (kDebugMode) {
            print("❌ status is not true: ${responseData['status']}");
          }
          emit(presentation_state.CardRegistrationError(
              message: responseData['message'] ?? 'Registration failed'));
          return;
        }

        // If we get here, we have a valid response
        if (kDebugMode) {
          print("✅ Valid response received");
          print("✅ checkoutId: $checkoutId");
          print("✅ checkoutId type: ${checkoutId.runtimeType}");
          print("✅ cardType: $cardType");
          print("✅ cardType type: ${cardType.runtimeType}");
        }

        // Ensure both values are non-null strings
        final String safeCheckoutId = checkoutId.toString();
        final String safeCardType = cardType.toString();

        emit(presentation_state.CardRegistrationSuccess(
          checkoutId: safeCheckoutId,
          cardType: safeCardType,
        ));
      } else {
        showNoInternetMessage(context);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("❌ Error in prepareCardRegistration:");
        print("Error: $e");
        print("Stack trace: $stackTrace");
      }
      emit(presentation_state.CardRegistrationError(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>?> saveCardMongo({
    required String cardType,
    required String bin_country,
    required String card_last4,
    required String holder_name,
    required String expiry_month,
    required String expiry_year,
    required String card_bin,
    required String registrationId,
    required BuildContext context,
  }) async {
    try {
      // Check internet connectivity
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        emit(const presentation_state.CardSavedLoading());

        final response = await DioHelper.postData(
          endPoint: Constants.saveCard,
          data: {
            "bin_country": bin_country,
            "cardType": cardType,
            "card_last4": card_last4,
            "holder_name": holder_name,
            "expiry_month": expiry_month,
            "expiry_year": expiry_year,
            "card_bin": card_bin,
            "registrationId": registrationId,
          },
        );

        if (response!.data['message'] == 'Payment method saved successfully') {
          emit(presentation_state.CardSavedSuccess(
              message: response.data['message']));
          return response.data;
        } else {
          emit(presentation_state.CardSavedError(
              message: response.data['message']));
          return null;
        }
      } else {
        showNoInternetMessage(context);
        return null;
      }
    } catch (e) {
      emit(presentation_state.CardSavedError(message: e.toString()));
      return null;
    }
  }




  Future<void> getCards({required BuildContext context}) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(const presentation_state.CardSavedLoading());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getCards,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          if (response!.data is List) {
            cards = (response.data as List)
                .map((item) => CardModel.fromJson(item))
                .toList();
          } else if (response.data is Map<String, dynamic>) {
            if (response.data['data'] is List) {
              cards = (response.data['data'] as List)
                  .map((item) => CardModel.fromJson(item))
                  .toList();
            } else {
              throw Exception("Invalid response format: data is not a list");
            }
          } else {
            throw Exception("Unexpected response format");
          }

          if (kDebugMode) {
            print("Cards Data: $cards");
          }

          if (cards.isEmpty) {
            showCustomToast(
              context: context,
              message: AppStrings.noCards.tr(),
              color: ColorManager.lightGrey,
            );
          }

          emit(const presentation_state.CardSavedSuccess(
              message: 'Cards loaded successfully'));
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Cards API Error Details: $error");
        }
        emit(presentation_state.CardSavedError(message: error.toString()));
        showCustomToast(
          context: context,
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage(context);
    }
  }


Future<void> deleteCard({required String cardId, required BuildContext context}) async {
   final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(const presentation_state.CardSavedLoading());

  try {
    final response = await DioHelper.delete(
      endPoint: Constants.deleteCard + cardId,
    );
    if (response!.data['message'] == 'Payment method deleted successfully') {
      emit(presentation_state.CardSavedSuccess(
          message: response.data['message']));
      return response.data;
    } else {
      emit(presentation_state.CardSavedError(
          message: response.data['message']));
      return;
    }
  } catch (e) {
      emit(presentation_state.CardSavedError(message: e.toString()));
      return;
    }
  } else {
    showNoInternetMessage(context);
  }
}




Future<void> setDefaultCard({required String cardId, required BuildContext context}) async {
  final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
  try {
    final response = await DioHelper.updateData(
      endPoint: Constants.setDefaultCard + cardId,
      data: {},
    );
    if (response!.data['message'] == 'Payment method set as default successfully') {
      emit(presentation_state.CardSavedSuccess(
          message: response.data['message']));
      return response.data;
    } else {
      emit(presentation_state.CardSavedError(
          message: response.data['message']));
      return;
    }
  } catch (e) {
    emit(presentation_state.CardSavedError(message: e.toString()));
    return;
  }
  } else {
    showNoInternetMessage(context);
  }
}


  Future<Map<String, dynamic>?> checkRegistrationStatus({
    required String checkoutId,
    required String cardType,
  }) async {
    try {
      final response = await HyperPayRegistrationApi.getRegistrationStatus(
        checkoutId: checkoutId,
        cardType: cardType,
      );
      return response;
    } catch (e) {
      emit(presentation_state.CardRegistrationError(message: e.toString()));
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkPaymentStatus({
    required String checkoutId,
    required String cardType,
  }) async {
    try {
      final response = await HyperPayRegistrationApi.getPaymentStatus(
        checkoutId: checkoutId,
        cardType: cardType,
      );
      return response;
    } catch (e) {
      emit(presentation_state.CardRegistrationError(message: e.toString()));
      return null;
    }
  }

  Future<String?> getPaymentWidgetsScript(String checkoutId) async {
    try {
      final response = await HyperPayRegistrationApi.getPaymentWidgets(
        checkoutId: checkoutId,
      );
      return response['script'];
    } catch (e) {
      emit(presentation_state.CardRegistrationError(message: e.toString()));
      return null;
    }
  }

  Future<String?> getPciIframeHtml(String checkoutId) async {
    try {
      final response = await HyperPayRegistrationApi.getPciIframe(
        checkoutId: checkoutId,
      );
      return response['html'];
    } catch (e) {
      emit(presentation_state.CardRegistrationError(message: e.toString()));
      return null;
    }
  }

  Future<void> registerCard({
    required String checkoutId,
    required String entityId,
    required BuildContext context,
  }) async {
    if (_isClosed) {
      print('Cannot register card: cubit is closed');
      return;
    }

    try {
      // Check internet connectivity
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        if (!_isClosed) {
          emit(const presentation_state.CardSavedLoading());
        }

        final registrationStatus = await checkRegistrationStatus(
          checkoutId: checkoutId,
          cardType: entityId,
        );

        if (registrationStatus != null) {
          final result = registrationStatus['result'] as Map<String, dynamic>;
          final card = registrationStatus['card'] as Map<String, dynamic>;

          if (result['code'] == '000.000.000') {
            print("Saving card with data: $card");

            // Save card data directly to database
            final response = await DioHelper.postData(
              endPoint: Constants.saveCard,
              data: {
                "bin_country": card['binCountry'] ?? '',
                "cardType": card['type'] ?? entityId,
                "card_last4": card['last4Digits'] ?? '',
                "holder_name": card['holder'] ?? '',
                "expiry_month": card['expiryMonth'] ?? '',
                "expiry_year": card['expiryYear'] ?? '',
                "card_bin": card['bin'] ?? '',
                "registrationId": registrationStatus['id'] ?? '',
              },
            );

            if (response != null &&
                response.data['message'] ==
                    'Payment method saved successfully') {
              emit(presentation_state.CardSavedSuccess(
                message: response.data['message'],
              ));
              emit(presentation_state.CardRegistrationSuccess(
                checkoutId: checkoutId,
                cardType: entityId,
              ));
            } else {
              emit(presentation_state.CardSavedError(
                message:
                    response?.data['message'] ?? 'Failed to save card details',
              ));
            }
          } else {
            emit(presentation_state.CardRegistrationError(
              message: result['description'] ?? 'Registration failed',
            ));
          }
        } else {
          emit(const presentation_state.CardRegistrationError(
            message: 'Invalid registration status',
          ));
        }
      } else {
        if (context.mounted) {
          showNoInternetMessage(context);
        }
      }
    } catch (e) {
      if (!_isClosed) {
        emit(presentation_state.CardRegistrationError(message: e.toString()));
      }
    }
  }
}
