import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/domain/client_request_model.dart';
import 'package:spreadlee/presentation/bloc/business/client_requests/client_requests_cubit.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';

class CardRejectedInfo extends StatefulWidget {
  final ClientRequestModel request;
  final ClientRequestsCubit cubit;

  const CardRejectedInfo({
    super.key,
    required this.request,
    required this.cubit,
  });

  @override
  State<CardRejectedInfo> createState() => _CardRejectedInfoState();
}

class _CardRejectedInfoState extends State<CardRejectedInfo> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isReadOnly = false;

  @override
  void initState() {
    super.initState();
    // Set initial text if request was previously rejected
    if (widget.request.rejectionReason != null) {
      _reasonController.text = widget.request.rejectionReason!;
      _isReadOnly = true;
      _reasonController.selection = TextSelection.collapsed(
        offset: _reasonController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: ColorManager.secondaryBackground,
                      size: 24,
                    ),
                    Expanded(
                      child: Text(
                        'Reason For Rejection'.tr(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: getRegularStyle(
                          color: ColorManager.primaryText,
                          fontSize: 14,
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
                const SizedBox(height: 24),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason:'.tr(),
                      style: getBoldStyle(
                        color: ColorManager.primaryText,
                        fontSize: AppSize.s10,
                      ),
                    ),
                    const SizedBox(height: AppSize.s6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSize.s12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSize.s12),
                        ),
                        child: TextFormField(
                          controller: _reasonController,
                          focusNode: _focusNode,
                          onChanged: (_) => setState(() {}),
                          autofocus: false,
                          readOnly: _isReadOnly,
                          maxLines: 11,
                          decoration: InputDecoration(
                            isDense: false,
                            hintText: 'Write Here...'.tr(),
                            hintStyle: getRegularStyle(
                              color: ColorManager.gray500,
                              fontSize: AppSize.s12,
                            ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: true,
                            fillColor: ColorManager.gray100,
                          ),
                          style: getRegularStyle(
                            color: ColorManager.primaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        foregroundColor: ColorManager.secondaryBackground,
                        minimumSize: const Size.fromHeight(AppSize.s40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.s6),
                        ),
                      ),
                      child: Text(
                        'OK'.tr(),
                        style: getMediumStyle(
                          color: ColorManager.secondaryBackground,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _reasonController.text.trim().isEmpty
                          ? null
                          : () => _handleReject(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        foregroundColor: ColorManager.secondaryBackground,
                        minimumSize: const Size.fromHeight(AppSize.s40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.s6),
                        ),
                        disabledBackgroundColor: ColorManager.buttonDisable,
                      ),
                      child: Text(
                        'Confirm'.tr(),
                        style: getMediumStyle(
                          color: ColorManager.secondaryBackground,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleReject(BuildContext context) {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a rejection reason'.tr()),
          backgroundColor: ColorManager.error,
        ),
      );
      return;
    }

    widget.cubit.rejectRequest(
      requestId: widget.request.id,
      reason: _reasonController.text.trim(),
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
          content: Text('Request has been rejected successfully'.tr()),
        ),
      ),
    );
  }
}
