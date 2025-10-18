import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/business/settings/widget/settings_contact_cards_widget.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../bloc/customer/otp_customer_bloc/otp_customer_cubit.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.secondaryBackground,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24.0,
          ),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.companyHomeRoute),
        ),
        title: Text(
          'Settings'.tr(),
          style: getMediumStyle(
            fontSize: 16.0,
            color: ColorManager.primaryText,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.editBusinessProfilePhotoRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.photo_camera,
                        color: ColorManager.blueLight800),
                    text: 'Add/Edit Photo',
                  ),
                ),
                const SizedBox(height: 8),
                // Bank Details
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.updateBusinessBankDetailsRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.account_balance,
                        color: ColorManager.blueLight800),
                    text: 'Update Bank Details',
                  ),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.changePasswordRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.lock, color: ColorManager.blueLight800),
                    text: 'Change Password',
                  ),
                ),

                const SizedBox(height: 8),
                // Contact Information
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.editBusinessContactRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.email, color: ColorManager.blueLight800),
                    text: 'Update Email & Phone Number',
                  ),
                ),
                const SizedBox(height: 8),
                // VAT Information
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.editBusinessVATRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.receipt_long,
                        color: ColorManager.blueLight800),
                    text: 'Edit VAT Information',
                  ),
                ),
                const SizedBox(height: 8),
                // Services
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.editServicesRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.miscellaneous_services,
                        color: ColorManager.blueLight800),
                    text: 'Update Services',
                  ),
                ),
                const SizedBox(height: 8),
                // Services
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.updateTagPriceRoute,
                  ),
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.price_change,
                        color: ColorManager.blueLight800),
                    text: 'Update Price Tag',
                  ),
                ),
                const SizedBox(height: 8),
                // Delete Account
                InkWell(
                  onTap: () async {
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_remove_rounded,
                                size: 50,
                                color: ColorManager.blueLight800,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Are you sure you want to Delete Your Account Permanently?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ColorManager.blueLight800,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.all(24),
                        );
                      },
                    );

                    if (confirm == true) {
                      await context.read<OtpCubit>().deleteAccount();
                      Navigator.pushNamedAndRemoveUntil(
                          context, Routes.logincompanyRoute, (route) => false);
                    }
                  },
                  child: SettingsContactCardsWidget(
                    icon: Icon(Icons.delete_forever,
                        color: ColorManager.blueLight800),
                    text: 'Delete Account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
