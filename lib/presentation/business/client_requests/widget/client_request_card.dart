import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/domain/client_request_model.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_cubit.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/business/client_requests/widget/card_rejected_info.dart';
import 'package:spreadlee/presentation/business/client_requests/widget/details_info.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';

class ClientRequestCard extends StatelessWidget {
  final ClientRequestModel request;

  const ClientRequestCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.s12),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.secondaryBackground,
          boxShadow: const [
            BoxShadow(
              blurRadius: 1,
              color: ColorManager.dropShadow,
              offset: Offset(0.0, 1),
              spreadRadius: 1,
            )
          ],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorManager.primaryunderreview,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.p18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          request.companyName,
                          style: getSemiBoldStyle(
                            fontSize: 18,
                            color: ColorManager.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, h:mm ')
                              .format(request.createdAt),
                          style: getRegularStyle(
                            fontSize: 12,
                            color: ColorManager.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAccept(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        foregroundColor: ColorManager.secondaryBackground,
                        minimumSize: const Size.fromHeight(26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Accept'.tr(),
                        style: getRegularStyle(
                          color: ColorManager.secondaryBackground,
                          fontSize: AppSize.s12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.s12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: ColorManager.blueLight800,
                          width: 1,
                        ),
                        minimumSize: const Size.fromHeight(26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Reject'.tr(),
                        style: getRegularStyle(
                          color: ColorManager.blueLight800,
                          fontSize: AppSize.s12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.s12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDetailsDialog(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: ColorManager.blueLight800,
                          width: 1,
                        ),
                        minimumSize: const Size.fromHeight(26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Details'.tr(),
                        style: getRegularStyle(
                          color: ColorManager.blueLight800,
                          fontSize: AppSize.s12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAccept(BuildContext context) {
    context.read<ClientRequestsCubit>().acceptRequest(
          context: context,
          requestId: request.id,
          request: request,
        );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: CardRejectedInfo(
          request: request,
          cubit: context.read<ClientRequestsCubit>(),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: DetailsInfo(request: request),
      ),
    );
  }
}
