import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/tickets_model.dart';
import 'package:spreadlee/presentation/bloc/business/tickets_bloc/tickets_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';

class TicketsBusinessCubit extends Cubit<TicketsBusinessState> {
  TicketsBusinessCubit() : super(TicketsBusinessInitialState());

  static TicketsBusinessCubit get(context) => BlocProvider.of(context);
  FToast? fToast;

  void initFToast(BuildContext context) {
    fToast = FToast();
    fToast?.init(context);
  }

  showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    if (fToast == null) {
      if (kDebugMode) {
        print("Toast not initialized. Message was: $message");
      }
      return;
    }

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

    fToast?.showToast(
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

    fToast?.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  Future<void> getTickets() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(TicketsBusinessLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getTickets,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final ticketsResponse = TicketsResponse.fromJson(response!.data);

          if (ticketsResponse.data == null || ticketsResponse.data!.isEmpty) {
            emit(TicketsBusinessEmptyState());
            showCustomToast(
              message: "No tickets found",
              color: ColorManager.lightGrey,
            );
          } else {
            emit(TicketsBusinessSuccessState(ticketsResponse.data!));
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Tickets API Error Details: $error");
        }
        emit(TicketsBusinessErrorState(error.toString()));
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

  Future<void> createTicket({
    required String title,
    required String description,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateTicketBusinessLoadingState());

      try {
        final response = await DioHelper.postData(
          endPoint: Constants.createTicket,
          data: {
            'title': title,
            'description': description,
          },
        );

        if (response?.statusCode == 201) {
          final ticket = TicketData.fromJson(response!.data['data']);
          emit(CreateTicketBusinessSuccessState(ticket));
          showCustomToast(
            message: "Ticket created successfully",
            color: ColorManager.lightGrey,
          );
        } else {
          throw Exception("Failed to create ticket");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Create Ticket API Error: $error");
        }
        emit(CreateTicketBusinessErrorState(error.toString()));
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
