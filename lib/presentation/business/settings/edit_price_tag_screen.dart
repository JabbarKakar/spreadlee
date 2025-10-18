import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/widgets/custom_alert_dialog.dart';
import 'package:spreadlee/presentation/widgets/custom_button.dart';

class EditPriceTagScreen extends StatefulWidget {
  const EditPriceTagScreen({super.key});

  @override
  State<EditPriceTagScreen> createState() => _EditPriceTagScreenState();
}

class _EditPriceTagScreenState extends State<EditPriceTagScreen> {
  String selectedPriceTag = '';

  @override
  void initState() {
    super.initState();
    context.read<SettingCubit>().getPriceTag();
  }

  void _showPriceTagSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_price_tag'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceTagOption('High Price'),
            _buildPriceTagOption('Moderate Price'),
            _buildPriceTagOption('Low Price'),
            _buildPriceTagOption('Special Offers'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTagOption(String priceTag) {
    return RadioListTile<String>(
      title: Text(priceTag),
      value: priceTag,
      groupValue: selectedPriceTag,
      onChanged: (value) {
        setState(() {
          selectedPriceTag = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  Color _getPriceTagColor(String priceTag) {
    switch (priceTag) {
      case 'High Price':
        return ColorManager.lightError;
      case 'Moderate Price':
        return ColorManager.primary;
      case 'Low Price':
        return ColorManager.success;
      case 'Special Offers':
        return ColorManager.warning;
      default:
        return ColorManager.lightGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'edit_price_tag'.tr(),
          style: getMediumStyle(
            fontSize: 16,
            color: ColorManager.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColorManager.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorManager.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<SettingCubit, SettingState>(
        listener: (context, state) {
          if (state is ContactInfoSuccessState) {
            setState(() {
              selectedPriceTag = state.data.priceTag;
            });
          } else if (state is ContactInfoErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Error updating price tag'),
                backgroundColor: ColorManager.lightError,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'select_price_tag'.tr(),
                  style: getMediumStyle(
                    fontSize: 16,
                    color: ColorManager.black,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _showPriceTagSelectionDialog(context),
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorManager.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorManager.lightGrey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedPriceTag.isEmpty
                                ? 'select_price_tag'.tr()
                                : selectedPriceTag,
                            style: getRegularStyle(
                              fontSize: 12,
                              color: selectedPriceTag.isEmpty
                                  ? ColorManager.lightGrey
                                  : ColorManager.black,
                            ),
                          ),
                        ),
                        if (selectedPriceTag.isNotEmpty)
                          IconButton(
                            padding: const EdgeInsets.only(bottom: 10),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedPriceTag = '';
                              });
                            },
                          ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: ColorManager.lightGrey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                CustomButton(
                  onPressed: () {
                    if (state is ContactInfoLoadingState) return;

                    context
                        .read<SettingCubit>()
                        .editPriceTag(
                          price_tag: selectedPriceTag,
                        )
                        .then((_) {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => CustomAlertDialog(
                            message: selectedPriceTag.isEmpty
                                ? 'price_tag_removed_successfully'.tr()
                                : 'price_tag_updated_successfully'.tr(),
                            onConfirm: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(
                                  context); // Return to previous screen
                            },
                          ),
                        );
                      }
                    }).catchError((e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                            content: const Text('Error updating price tag'),
                            backgroundColor: ColorManager.lightError,
                          ),
                        );
                      }
                    });
                  },
                  text: 'update'.tr(),
                  isLoading: state is ContactInfoLoadingState,
                ),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
