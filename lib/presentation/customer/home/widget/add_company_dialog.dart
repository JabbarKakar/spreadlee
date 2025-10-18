import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../bloc/customer/customer_company_bloc/customer_company_cubit.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_states.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';
import '../../customer_company/widget/select_country.dart';

class AddCompanyDialog extends StatefulWidget {
  const AddCompanyDialog({Key? key}) : super(key: key);

  static Future<bool> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider<CustomerCompanyCubit>(
        create: (context) => CustomerCompanyCubit(),
        child: Dialog(
          backgroundColor: ColorManager.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: const AddCompanyDialog(),
          ),
        ),
      ),
    ).then((value) => value ?? false);
  }

  @override
  State<AddCompanyDialog> createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends State<AddCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companNameController = TextEditingController();
  final _commercialNameController = TextEditingController();
  final _commercialNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _vatCertificatController = TextEditingController();
  final _commercialRegisterFormController = TextEditingController();
  final _eriefController = TextEditingController();

  final _companNameFocusNode = FocusNode();
  final _commercialNameFocusNode = FocusNode();
  final _commercialNumberCFocusNode = FocusNode();
  final _vatNumberFocusNode = FocusNode();
  final _vatCertificatFocusNode = FocusNode();
  final _commercialRegisterFormFocusNode = FocusNode();
  final _eriefFocusNode = FocusNode();

  String selectedCountry = "Select Country";
  XFile? _vatCertificateFile;
  XFile? _commercialRegisterFormFile;

  void handleCountryChange(String country) {
    setState(() {
      selectedCountry = country;
    });
  }

  @override
  void dispose() {
    _companNameController.dispose();
    _commercialNameController.dispose();
    _commercialNumberController.dispose();
    _vatNumberController.dispose();
    _vatCertificatController.dispose();
    _commercialRegisterFormController.dispose();
    _eriefController.dispose();

    _companNameFocusNode.dispose();
    _commercialNameFocusNode.dispose();
    _commercialNumberCFocusNode.dispose();
    _vatNumberFocusNode.dispose();
    _vatCertificatFocusNode.dispose();
    _commercialRegisterFormFocusNode.dispose();
    _eriefFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Please fill this form',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.black54),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 20),
            BlocConsumer<CustomerCompanyCubit, CustomerCompanyStates>(
              listener: (context, state) {
                if (state is CustomerCompanySuccessState) {
                  Navigator.pop(context, true);
                  Fluttertoast.showToast(
                    msg: "Company added successfully",
                    backgroundColor: ColorManager.lightGrey,
                  );
                } else if (state is CustomerCompanyErrorState) {
                  Fluttertoast.showToast(
                    msg: state.error,
                    backgroundColor: ColorManager.lightGrey,
                  );
                }
              },
              builder: (context, state) {
                final cubit = CustomerCompanyCubit.get(context);
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Country Name', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CountryPickerWidget(
                          onCountrySelected: handleCountryChange,
                          validator: (value) {
                            if (selectedCountry == "Select Country") {
                              return AppStrings.requiredField.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Company Name', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildTextField(
                          controller: _companNameController,
                          focusNode: _companNameFocusNode,
                          hintText: 'Enter Company Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Commercial Name', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildTextField(
                          controller: _commercialNameController,
                          focusNode: _commercialNameFocusNode,
                          hintText: 'Enter Commercial Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Commercial Number', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildTextField(
                          controller: _commercialNumberController,
                          focusNode: _commercialNumberCFocusNode,
                          hintText: 'Enter Commercial Number',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('VAT Number', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildTextField(
                          controller: _vatNumberController,
                          focusNode: _vatNumberFocusNode,
                          hintText: 'Enter VAT Number',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('VAT Certificate', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildUploadButton(
                          controller: _vatCertificatController,
                          onFileSelected: (filePath) {
                            if (filePath != null &&
                                filePath.isNotEmpty &&
                                File(filePath).existsSync()) {
                              setState(() {
                                _vatCertificateFile = XFile(filePath);
                                _vatCertificatController.text =
                                    filePath.split('/').last;
                              });
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Invalid file selected.");
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Commercial Registration Form', true),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildUploadButton(
                          controller: _commercialRegisterFormController,
                          onFileSelected: (filePath) {
                            if (filePath != null &&
                                filePath.isNotEmpty &&
                                File(filePath).existsSync()) {
                              setState(() {
                                _commercialRegisterFormFile = XFile(filePath);
                                _commercialRegisterFormController.text =
                                    filePath.split('/').last;
                              });
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Invalid file selected.");
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Brief about your company', false),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _eriefController,
                          focusNode: _eriefFocusNode,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write Here...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            fillColor: Colors.grey[100],
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: InkWell(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              if (_vatCertificateFile == null) {
                                Fluttertoast.showToast(
                                  msg: "Please upload VAT Certificate",
                                  backgroundColor: ColorManager.lightGrey,
                                );
                                return;
                              }
                              if (_commercialRegisterFormFile == null) {
                                Fluttertoast.showToast(
                                  msg:
                                      "Please upload Commercial Registration Form",
                                  backgroundColor: ColorManager.lightGrey,
                                );
                                return;
                              }

                              cubit.CreateCompany(
                                countryName: selectedCountry,
                                companyName: _companNameController.text,
                                commercialName: _commercialNameController.text,
                                commercialNumber:
                                    _commercialNumberController.text,
                                vATNumber: _vatNumberController.text,
                                vATCertificate: _vatCertificateFile!,
                                comRegForm: _commercialRegisterFormFile!,
                                brief: _eriefController.text,
                              );
                            }
                          },
                          child: Container(
                            width: 220,
                            height: 50,
                            decoration: BoxDecoration(
                              color: ColorManager.blueLight800,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Center(
                              child: state is CustomerCompanyLoadingState
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      AppStrings.add.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        fillColor: Colors.grey[100],
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.requiredField.tr();
        }
        return null;
      },
    );
  }

  Widget _buildUploadButton({
    required TextEditingController controller,
    required Function(String?) onFileSelected,
  }) {
    return InkWell(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          onFileSelected(result.files.single.path);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.text.isEmpty ? 'Upload File' : controller.text,
              style: TextStyle(
                color:
                    controller.text.isEmpty ? Colors.grey[400] : Colors.black,
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorManager.blueLight800.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upload_rounded,
                color: ColorManager.blueLight800,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
