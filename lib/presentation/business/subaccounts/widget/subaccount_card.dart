import 'package:flutter/material.dart';
import 'package:spreadlee/domain/subaccount_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/business/subaccounts/widget/change_info_dialog.dart';
import 'package:spreadlee/presentation/business/subaccounts/widget/confirm_delete_dialog.dart';

class SubaccountCard extends StatefulWidget {
  final SubaccountModel subaccount;
  final VoidCallback? onDelete;
  final Function(String phoneCode, String phoneNumber, String password)?
      onChangeInfo;
  final VoidCallback? onSwitch;

  const SubaccountCard({
    super.key,
    required this.subaccount,
    this.onDelete,
    this.onChangeInfo,
    this.onSwitch,
  });

  @override
  State<SubaccountCard> createState() => _SubaccountCardState();
}

class _SubaccountCardState extends State<SubaccountCard> {
  bool _passwordVisibility = false;

  void _showChangeInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => ChangeInfoDialog(
        subaccount: widget.subaccount,
        onSave: (phoneCode, phoneNumber, password) {
          if (widget.onChangeInfo != null) {
            widget.onChangeInfo!(phoneCode, phoneNumber, password);
          }
        },
      ),
    );
  }

  void _showConfirmDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        subaccount: widget.subaccount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onSwitch,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: ColorManager.customYellowF1D261,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24.0,
              color: ColorManager.gray200.withOpacity(0.5),
              offset: const Offset(0.0, 12.0),
              spreadRadius: 4.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorManager.black,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins'),
                      ),
                      Flexible(
                        child: Text(
                          widget.subaccount.data?.first.username ?? "",
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.black,
                              fontSize: 14.0,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        'Password: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: ColorManager.black,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins'),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _passwordVisibility
                                    ? (widget.subaccount.data?.first.passwordGen ??
                                        '')
                                    : '••••••••',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorManager.black,
                                  fontSize: 14.0,
                                  fontFamily: 'Poppins',
                                  height: 1.0,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisibility = !_passwordVisibility;
                                });
                              },
                              icon: Icon(
                                _passwordVisibility
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: ColorManager.gray400,
                                size: 20.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showConfirmDeleteDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 30.0),
                        padding: EdgeInsets.zero,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showChangeInfoDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF677BA9),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 30.0),
                        padding: EdgeInsets.zero,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            fontFamily: 'Poppins'),
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
}
