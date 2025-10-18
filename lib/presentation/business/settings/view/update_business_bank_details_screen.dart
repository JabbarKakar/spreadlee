import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/data/models/bank_details_model.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/customer/customer_company/widget/select_country.dart';
import 'package:spreadlee/presentation/business/settings/widget/declined_bank_reason_dialog.dart';

class UpdateBusinessBankDetailsScreen extends StatefulWidget {
  const UpdateBusinessBankDetailsScreen({super.key});

  @override
  State<UpdateBusinessBankDetailsScreen> createState() =>
      _UpdateBusinessBankDetailsScreenState();
}

class _UpdateBusinessBankDetailsScreenState
    extends State<UpdateBusinessBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedCountry = "Select Country";
  final _bankNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _swiftCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SettingCubit>().getBankDetails();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  void _populateFields(BankDetailsData data) {
    setState(() {
      selectedCountry = data.bankCountry;
      _bankNameController.text = data.bankName;
      _holderNameController.text = data.bankHolderName;
      _accountNumberController.text = data.bankAccountNumber.toString();
      _ibanController.text = data.bankIBANNumber;
      _branchNameController.text = data.bankBranchName;
      _branchCodeController.text = data.bankBranchCode.toString();
      _swiftCodeController.text = data.bankSwiftCode;
    });
  }

  void handleCountryChange(String country) {
    setState(() {
      selectedCountry = country;
    });
  }

  void _showRejectionReasonDialog(String? reason) {
    showDialog(
      context: context,
      builder: (context) => DeclinedBankReasonDialog(
        rejectionReason: reason,
      ),
    );
  }

  String _formatUpdateTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now'.tr();
          }
          return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago'
              .tr();
        }
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago'
            .tr();
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago'
            .tr();
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      return isoTime; // Return original string if parsing fails
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          fillColor: ColorManager.gray100,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required'.tr();
          }
          return null;
        },
      ),
    );
  }

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Update Bank Details'.tr(),
          style: getMediumStyle(
            fontSize: 16.0,
            color: ColorManager.primaryText,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: BlocConsumer<SettingCubit, SettingState>(
          listener: (context, state) {
            if (state is BankDetailsSuccessState) {
              _populateFields(state.bankDetails);
            } else if (state is BankDetailsErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error updating bank details')),
              );
            }
          },
          builder: (context, state) {
            if (state is BankDetailsLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BankDetailsSuccessState) {
              final bankDetails = state.bankDetails;
              final updation = bankDetails.updation;

              // Show rejection banner if rejected
              if (updation.rejected) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: ColorManager.gray400.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your bank details have been rejected'.tr(),
                                  style: getMediumStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                                if (updation.updateTime.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last updated: ${_formatUpdateTime(updation.updateTime)}'
                                        .tr(),
                                    style: getRegularStyle(
                                      fontSize: 12,
                                      color: ColorManager.gray400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showRejectionReasonDialog(
                              updation.rejectedInfo.isEmpty
                                  ? null
                                  : updation.rejectedInfo,
                            ),
                            child: Text(
                              'View Reason'.tr(),
                              style: getMediumStyle(
                                fontSize: 14,
                                color: ColorManager.blueLight800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildBankDetailsForm(),
                    ),
                  ],
                );
              }

              // Show acceptance banner if accepted
              if (updation.accepted) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: ColorManager.success.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: ColorManager.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your bank details have been accepted'.tr(),
                                  style: getMediumStyle(
                                    fontSize: 14,
                                    color: ColorManager.success,
                                  ),
                                ),
                                if (updation.updateTime.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last updated: ${_formatUpdateTime(updation.updateTime)}'
                                        .tr(),
                                    style: getRegularStyle(
                                      fontSize: 12,
                                      color: ColorManager.gray400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildBankDetailsForm(),
                    ),
                  ],
                );
              }

              // Show pending banner if updated but not yet reviewed
              if (updation.updated &&
                  !updation.accepted &&
                  !updation.rejected) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: ColorManager.warning.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pending_outlined,
                            color: ColorManager.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your bank details are pending review'.tr(),
                                  style: getMediumStyle(
                                    fontSize: 14,
                                    color: ColorManager.warning,
                                  ),
                                ),
                                if (updation.updateTime.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last updated: ${_formatUpdateTime(updation.updateTime)}'
                                        .tr(),
                                    style: getRegularStyle(
                                      fontSize: 12,
                                      color: ColorManager.gray400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildBankDetailsForm(),
                    ),
                  ],
                );
              }
            }

            return _buildBankDetailsForm();
          },
        ),
      ),
    );
  }

  Widget _buildBankDetailsForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Details'.tr(),
                style: getMediumStyle(
                  fontSize: 24.0,
                  color: ColorManager.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your bank details through which you want to receive your payment.'
                    .tr(),
                style: getRegularStyle(
                  fontSize: 15.0,
                  color: ColorManager.gray400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Country:'.tr(),
                style: getMediumStyle(
                  fontSize: 16.0,
                  color: ColorManager.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              CountryPickerWidget(
                onCountrySelected: handleCountryChange,
              ),
              const SizedBox(height: 16),
              _buildTextField(_bankNameController, 'Bank Name'.tr()),
              _buildTextField(_holderNameController, 'Holder Name'.tr()),
              _buildTextField(
                  _accountNumberController, 'Bank Account Number'.tr()),
              _buildTextField(_ibanController, 'IBAN Number'.tr()),
              _buildTextField(_branchNameController, 'Branch Name'.tr()),
              _buildTextField(_branchCodeController, 'Branch Code'.tr()),
              _buildTextField(_swiftCodeController, 'Swift Code'.tr()),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context
                          .read<SettingCubit>()
                          .updateBankDetails(
                            bank_account_number: _accountNumberController.text,
                            iban_string: _ibanController.text,
                            branch_code_string: _branchCodeController.text,
                            branch_name: _branchNameController.text,
                            country: selectedCountry,
                            holder_name: _holderNameController.text,
                            bank_name: _bankNameController.text,
                            swift_code_string: _swiftCodeController.text,
                          )
                          .then((_) {
                        Navigator.pop(context);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.blueLight800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Save Changes'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
