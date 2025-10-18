import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/localStoreList.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/widgets/custom_button.dart';
import 'package:spreadlee/presentation/widgets/custom_alert_dialog.dart';

class EditServicesScreen extends StatefulWidget {
  const EditServicesScreen({super.key});

  @override
  State<EditServicesScreen> createState() => _EditServicesScreenState();
}

class _EditServicesScreenState extends State<EditServicesScreen> {
  List<String> selectedServices = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _showServiceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Services'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setState) => ListView.builder(
              shrinkWrap: true,
              itemCount: companyServices.length,
              itemBuilder: (context, index) {
                final service = companyServices[index];
                final isSelected = selectedServices.contains(service);
                return CheckboxListTile(
                  title: Text(service),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedServices.add(service);
                      } else {
                        selectedServices.remove(service);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('Done'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.secondaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: ColorManager.primaryText,
            size: 24.0,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Services'.tr(),
          style: getMediumStyle(
            fontSize: 16.0,
            color: ColorManager.primaryText,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Marketing Fields:'.tr(),
                      style: getMediumStyle(
                        fontSize: 12.0,
                        color: ColorManager.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _showServiceSelectionDialog,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ColorManager.gray100,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: ColorManager.gray100,
                            width: 0.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: selectedServices.isEmpty
                                    ? Text(
                                        'Select Services'.tr(),
                                        style: getRegularStyle(
                                          color: ColorManager.gray400,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 6.0,
                                        runSpacing: 6.0,
                                        children: selectedServices
                                            .map(
                                              (service) => Container(
                                                decoration: BoxDecoration(
                                                  color: ColorManager.gray300,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          25.0),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 2.0),
                                                child: Text(
                                                  service,
                                                  style: getRegularStyle(
                                                    fontSize: 12.0,
                                                    color: ColorManager.black,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: ColorManager.gray400,
                                size: 20.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocConsumer<SettingCubit, SettingState>(
                listener: (context, state) {
                  if (state is SettingSuccessState) {
                    // Update selected services from state if needed
                    if (state.settings.isNotEmpty) {
                      // Assuming the first setting contains the services
                      // You'll need to adjust this based on your actual data structure
                      setState(() {
                        // Update selectedServices based on state data
                      });
                    }
                  } else if (state is SettingErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error updating services')),
                    );
                  }
                },
                builder: (context, state) {
                  return CustomButton(
                    onPressed: () async {
                      if (isLoading) return;
                      setState(() => isLoading = true);

                      try {
                        await context.read<SettingCubit>().editServices(
                              marketing_fields: selectedServices,
                            );

                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => CustomAlertDialog(
                              message:
                                  'Your services have been updated successfully.'
                                      .tr(),
                              onConfirm: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(
                                    context); // Return to previous screen
                              },
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error updating services')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
                    text: isLoading ? 'Updating...'.tr() : 'Update'.tr(),
                    isLoading: isLoading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
