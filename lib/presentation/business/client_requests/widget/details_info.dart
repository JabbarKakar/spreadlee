import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/domain/client_request_model.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_cubit.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';
import 'package:spreadlee/presentation/business/client_requests/widget/card_rejected_info.dart';

class DetailsInfo extends StatelessWidget {
  final ClientRequestModel request;

  const DetailsInfo({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorManager.secondaryBackground,
            borderRadius: BorderRadius.circular(AppSize.s12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.p14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.p8),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: ColorManager.secondaryBackground,
                        size: AppSize.s2,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Details'.tr(),
                          style: getRegularStyle(
                            color: ColorManager.primaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close_rounded,
                          color: ColorManager.primaryText,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDetailSection(
                  label: 'Country Name'.tr(),
                  value: request.countryName ?? '-',
                ),
                const SizedBox(height: 12),
                _buildDetailSection(
                  label: 'Company Name'.tr(),
                  value: request.companyName,
                ),
                const SizedBox(height: 12),
                _buildDetailSection(
                  label: 'Commercial Name'.tr(),
                  value: request.commercialName ?? '-',
                ),
                const SizedBox(height: 12),
                _buildDetailSection(
                  label: 'Commercial Number'.tr(),
                  value: request.commercialNumber?.toString() ?? '-',
                ),
                const SizedBox(height: 12),
                _buildDetailSection(
                  label: 'Brief'.tr(),
                  value: request.brief ?? '-',
                ),
                const SizedBox(height: 12),
                _buildDetailSection(
                  label: 'VAT Number'.tr(),
                  value: request.vatNumber?.toString() ?? '-',
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(top: AppPadding.p8),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
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
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: ColorManager.blueLight800,
                              width: 1,
                            ),
                            minimumSize: const Size.fromHeight(30),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAccept(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.blueLight800,
                            foregroundColor: ColorManager.secondaryBackground,
                            minimumSize: const Size.fromHeight(AppSize.s30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSize.s8),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getSemiBoldStyle(
            color: ColorManager.primaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSize.s4),
        Text(
          value,
          style: getRegularStyle(
            color: ColorManager.primaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _handleAccept(BuildContext context) {
    context.read<ClientRequestsCubit>().acceptRequest(
          requestId: request.id,
          request: request,
          context: context,
        );
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: AlertDialog(
          content: Text('Request has been accepted successfully'.tr()),
        ),
      ),
    );
  }
}
