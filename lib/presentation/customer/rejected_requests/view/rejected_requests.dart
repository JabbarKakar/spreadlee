import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/customer/client_request_bloc/client_request_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/client_request_bloc/client_request_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
class RejectedRequestsScreen extends StatelessWidget {
  const RejectedRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = ClientRequestCubit();
        cubit.initFToast(context);
        cubit.getRejectedRequests();
        return cubit;
      },
      child: Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(
                    context, Routes.customerHomeRoute),
          ),
          title: Text(
            AppStrings.rejectedRequest.tr(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: BlocBuilder<ClientRequestCubit, ClientRequestStates>(
          builder: (context, state) {
            if (state is RejectedRequestsLoadingState) {
              return Center(
                child: CircularProgressIndicator(
                  color: ColorManager.blueLight800,
                ),
              );
            } else if (state is RejectedRequestsSuccessState) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.rejectedRequests.length,
                itemBuilder: (context, index) {
                  final request = state.rejectedRequests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 44.0,
                        height: 44.0,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.network(
                          request.client?.photoUrl ??
                              'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/spread-lee-xf1i5z/assets/gnm1dhgwv47f/profile.png',
                          width: 56.0,
                          height: 56.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        request.client?.companyName ?? 'Unknown Company',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Padding(
                          //   padding: EdgeInsets.only(top: 4),
                          //   child: Text(
                          //     request.client?.commercialName ?? '',
                          //     style: TextStyle(
                          //       fontSize: 14,
                          //       color: Colors.grey[600],
                          //     ),
                          //   ),
                          // ),
                          Text(
                            request.client?.status ?? 'Rejected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Rejection Reason',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Text(
                                  request.rejectionReason ??
                                      request.rejectedData?.reason ??
                                      'No reason provided',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        color: ColorManager.blueLight800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.blueLight800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Show reason',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else if (state is RejectedRequestsEmptyState) {
              return Center(
                child: Text(
                  'No rejected requests found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              );
            } else if (state is RejectedRequestsErrorState) {
              return Center(
                child: Text(
                  state.error,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
