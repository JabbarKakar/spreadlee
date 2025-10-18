import 'package:flutter/material.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/values_manager.dart';
import 'package:intl/intl.dart';

class TaxInvoiceContainer extends StatelessWidget {
  const TaxInvoiceContainer({
    super.key,
    required this.invoiceId,
    required this.name,
    required this.date,
    required this.appFeeVat,
    this.onTap,
  });

  final String? invoiceId;
  final String? name;
  final String? date;
  final String? appFeeVat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.s12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.s12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorManager.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: AppSize.s24,
                color: ColorManager.dropShadow,
                offset: Offset(0, AppSize.s12),
                spreadRadius: AppSize.s4,
              )
            ],
            borderRadius: BorderRadius.circular(AppSize.s12),
            border: Border.all(
              color: ColorManager.custombordercard,
              width: AppSize.s1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.p18),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.taxInvoiceId}: ${invoiceId ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: Constants.fontFamily,
                              fontSize: AppSize.s12,
                            ),
                      ),
                      const SizedBox(height: AppSize.s4),
                      Text(
                        '${AppStrings.taxInvoiceCommercialName}: ${name ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: Constants.fontFamily,
                              fontSize: AppSize.s12,
                            ),
                      ),
                      const SizedBox(height: AppSize.s4),
                      Text(
                        date != null
                            ? DateFormat('EEEE, MMMM d, HH:mm').format(
                                DateTime.parse(date!),
                              )
                            : AppStrings.taxInvoiceNoDate,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: Constants.fontFamily,
                              fontSize: AppSize.s12,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSize.s12),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.taxInvoiceAppFeeVat,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: Constants.fontFamily,
                            fontSize: AppSize.s12,
                          ),
                    ),
                    const SizedBox(height: AppSize.s2),
                    Text(
                      'SAR ${appFeeVat ?? '0.00'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: Constants.fontFamily,
                            fontSize: AppSize.s14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
