import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_states.dart';
import 'package:spreadlee/presentation/business/client_requests/widget/client_request_card.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';
import 'package:spreadlee/presentation/widgets/empty_list_text.dart';
import 'package:spreadlee/services/chat_service.dart';

class ClientRequestsPage extends StatefulWidget {
  const ClientRequestsPage({super.key});

  @override
  State<ClientRequestsPage> createState() => _ClientRequestsPageState();
}

class _ClientRequestsPageState extends State<ClientRequestsPage> {
  @override
  void initState() {
    super.initState();

    // ✅ ADD: Initialize socket when client requests page loads
    () async {
      try {
        final chatService = Provider.of<ChatService>(context, listen: false);
        await chatService.waitForSocketReady();
        if (kDebugMode) {
          print('Socket initialized on client requests page');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Socket initialization failed on client requests page: $e');
        }
      }
    }();

    // Load client requests when page initializes
    context.read<ClientRequestsCubit>().getClientRequests(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.secondaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: ColorManager.primaryText,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.companyHomeRoute),
        ),
        title: Text(
          'Client Requests'.tr(),
          style: getMediumStyle(
            color: ColorManager.primaryText,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
          builder: (context, state) {
            if (state is ClientRequestsLoadingState) {
              return const Center(
                child: SizedBox(
                  width: AppSize.s25,
                  height: AppSize.s25,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is ClientRequestsErrorState) {
              return Center(
                child: Text(
                  state.message,
                  style: getRegularStyle(color: ColorManager.error),
                ),
              );
            }

            if (state is ClientRequestsSuccessState) {
              final requests = state.requests;

              return Container(
                padding: const EdgeInsets.all(AppPadding.p16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppPadding.p16),
                        child: Text(
                          'Search Results: ${requests.length}',
                          style: getRegularStyle(
                            color: ColorManager.gray500,
                            fontSize: AppSize.s12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: requests.isEmpty
                          ? EmptyListText(
                              text: 'No Client Requests here'.tr(),
                              grey400: false,
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.vertical,
                              itemCount: requests.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSize.s6),
                              itemBuilder: (context, index) {
                                final request = requests[index];
                                return ClientRequestCard(
                                  key: ValueKey('request_${request.id}'),
                                  request: request,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
