import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/domain/client_request_model.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';
import 'package:spreadlee/services/chat_service.dart';
import '../../../../data/dio_helper.dart';

class ClientRequestsCubit extends Cubit<ClientRequestsState> {
  ClientRequestsCubit() : super(ClientRequestsInitialState());
  static ClientRequestsCubit get(context) => BlocProvider.of(context);
  final FToast fToast = FToast();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initFToast(BuildContext context) {
    if (context.mounted) {
      fToast.init(context);
    }
  }

  List<ClientRequestModel> allRequests = [];

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

  Future<void> getClientRequests(BuildContext context) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ClientRequestsLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getClientRequests,
        );

        if (response?.statusCode == 200) {
          final clientRequestResponse =
              ClientRequestResponse.fromJson(response!.data);
          allRequests = clientRequestResponse.data
                  ?.map((data) => data.toDomainModel())
                  .toList() ??
              [];

          emit(ClientRequestsSuccessState(allRequests));
        } else {
          throw Exception(
              response?.data['message'] ?? 'Failed to get client requests');
        }
      } catch (error) {
        if (kDebugMode) {
          print("Get Client Requests Error: $error");
        }
        emit(ClientRequestsErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
          context: context,
        );
      }
    } else {
      showNoInternetMessage(context);
    }
  }

  Future<void> acceptRequest({
    required String requestId,
    required BuildContext context,
    required ClientRequestModel request,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ClientRequestsLoadingState());

      try {
        final response = await DioHelper.updateData(
          endPoint: '${Constants.acceptClientRequest}$requestId',
          data: {
            'chat_company_commercial_name': request.clientCommercialName ?? '',
            'chat_company_name': request.clientCompanyName ?? '',
            'chat_customer_commercial_name': request.commercialName ?? '',
            'chat_customer_company_name': request.companyName,
            'chat_customer_company_ref': {
              'customerId': request.customerId,
              'customer_companiesId': request.companyId,
            },
            'client_request_ref': {
              'customerId': request.customerId,
              'client_requestsId': request.id,
            },
            'chat_users': {
              'customerId': request.customerId,
            },
          },
        );

        if (response?.statusCode == 200) {
          final message =
              response!.data['message'] ?? 'Request accepted successfully';
          emit(ClientRequestsAcceptSuccessState(message));

          // ✅ ADD: Initialize socket and join chat room after accepting request
          try {
            final chatService =
                Provider.of<ChatService>(context, listen: false);
            await chatService.waitForSocketReady();

            // Extract chat ID from response and join the room
            if (response.data['chat'] != null &&
                response.data['chat']['_id'] != null) {
              final chatId = response.data['chat']['_id'];
              chatService.joinChatRoom(chatId);

              // ✅ ADD: Fast socket readiness check for newly created chat
              await chatService.ensureSocketReadyForChatNavigation(chatId);

              if (kDebugMode) {
                print(
                    'Socket initialized and joined chat room $chatId after accepting client request');
                print('Socket readiness ensured for chat: $chatId');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Socket initialization failed after accepting request: $e');
            }
          }

          if (context.mounted) {
            showCustomToast(
              message: message,
              color: ColorManager.success,
              context: context,
            );
          }
          await getClientRequests(context);
        } else {
          throw Exception(
              response?.data['message'] ?? 'Failed to accept request');
        }
      } catch (error) {
        if (kDebugMode) {
          print("Accept Request Error: $error");
        }
        emit(ClientRequestsAcceptErrorState(error.toString()));
        if (context.mounted) {
          showCustomToast(
            message: error.toString(),
            color: ColorManager.lightError,
            messageColor: ColorManager.white,
            context: context,
          );
        }
      }
    } else {
      if (context.mounted) {
        showNoInternetMessage(context);
      }
    }
  }

  Future<void> rejectRequest({
    required String requestId,
    required String reason,
    required BuildContext context,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ClientRequestsLoadingState());

      try {
        final response = await DioHelper.updateData(
          endPoint: '${Constants.rejectClientRequest}$requestId',
          data: {
            'rejection_reason': reason,
            'rejected_data': {
              'read': false,
              'rejection_reason': reason,
            },
          },
        );

        if (response?.statusCode == 200) {
          final message =
              response!.data['message'] ?? 'Request rejected successfully';
          emit(ClientRequestsRejectSuccessState(message));
          showCustomToast(
            message: message,
            color: ColorManager.success,
            context: context,
          );
          await getClientRequests(context);
        } else {
          throw Exception(
              response?.data['message'] ?? 'Failed to reject request');
        }
      } catch (error) {
        if (kDebugMode) {
          print("Reject Request Error: $error");
        }
        emit(ClientRequestsRejectErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
          context: context,
        );
      }
    } else {
      showNoInternetMessage(context);
    }
  }
}
