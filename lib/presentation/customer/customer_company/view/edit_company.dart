import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spreadlee/core/outside_api_call.dart';
import 'package:spreadlee/presentation/customer/customer_company/widget/brief_text_field.dart';
import 'package:spreadlee/presentation/customer/customer_company/widget/select_country.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_cubit.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_states.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';
import '../widget/text_field.dart';
import '../widget/upload_file.dart';

class EditCompany extends StatefulWidget {
  final Map<String, dynamic>? companyData;
  final String? companyId;

  const EditCompany({Key? key, this.companyData, this.companyId})
      : super(key: key);

  @override
  _EditCompanyState createState() => _EditCompanyState();
}

class _EditCompanyState extends State<EditCompany> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  String selectedCountry = "Select Country";
  final TextEditingController _companNameController = TextEditingController();
  final TextEditingController _commercialNameController = TextEditingController();
  final TextEditingController _commercialNumberController = TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _vatCertificatController = TextEditingController();
  final TextEditingController _commercialRegisterFormController =
      TextEditingController();
  final TextEditingController _eriefController = TextEditingController();

  final FocusNode _companNameFocusNode = FocusNode();
  final FocusNode _commercialNameFocusNode = FocusNode();
  final FocusNode _commercialNumberCFocusNode = FocusNode();
  final FocusNode _vatNumberFocusNode = FocusNode();
  final FocusNode _vatCertificatFocusNode = FocusNode();
  final FocusNode _commercialRegisterFormFocusNode = FocusNode();
  final FocusNode _eriefFocusNode = FocusNode();

  XFile? _vatCertificateFile;
  XFile? _commercialRegisterFormFile;

  @override
  void initState() {
    super.initState();
    context.read<CustomerCompanyCubit>().fToast.init(context);
    // Initialize fields with company data
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.companyData != null) {
      setState(() {
        // Only update fields that are present in the data
        if (widget.companyData!.containsKey('countryName')) {
          selectedCountry = widget.companyData!['countryName']?.toString() ??
              "Select Country";
        }
        if (widget.companyData!.containsKey('companyName')) {
          _companNameController.text =
              widget.companyData!['companyName']?.toString() ?? '';
        }
        if (widget.companyData!.containsKey('commercialName')) {
          _commercialNameController.text =
              widget.companyData!['commercialName']?.toString() ?? '';
        }
        if (widget.companyData!.containsKey('commercialNumber')) {
          _commercialNumberController.text =
              widget.companyData!['commercialNumber']?.toString() ?? '';
        }
        if (widget.companyData!.containsKey('vATNumber')) {
          _vatNumberController.text =
              widget.companyData!['vATNumber']?.toString() ?? '';
        }
        if (widget.companyData!.containsKey('brief')) {
          _eriefController.text =
              widget.companyData!['brief']?.toString() ?? '';
        }

        // Set file names if they exist
        if (widget.companyData!.containsKey('vATCertificate') &&
            widget.companyData!['vATCertificate'] != null) {
          _vatCertificatController.text =
              widget.companyData!['vATCertificate'].toString().split('/').last;
        }
        if (widget.companyData!.containsKey('comRegForm') &&
            widget.companyData!['comRegForm'] != null) {
          _commercialRegisterFormController.text =
              widget.companyData!['comRegForm'].toString().split('/').last;
        }
      });
    }
  }

  void handleCountryChange(String country) {
    setState(() {
      selectedCountry = country;
    });
  }

  @override
  void dispose() {
    // Don't forget to dispose of your controllers and focus nodes
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
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    var cubit = CustomerCompanyCubit.get(context);
    return Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: ColorManager.white,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.black,
                size: 24.0,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: const Text(AppStrings.editCompany),
        ),
        body: BlocConsumer<CustomerCompanyCubit, CustomerCompanyStates>(
            listener: (context, state) {
          if (state is CustomerCompanySuccessState) {
            if (cubit.customerCompanyModel?.message ==
                "Customer company updated successfully") {
              cubit.showCustomToast(
                message: AppStrings.company_updated_success.tr(),
                color: ColorManager.lightGreen,
              );
              Navigator.pushReplacementNamed(
                context,
                Routes.customerCompanyRoute,
              );
            }
          } else if (state is CustomerCompanyErrorState) {
            if (cubit.customerCompanyModel?.message ==
                "Company ID is required") {
              cubit.showCustomToast(
                message: AppStrings.company_id_required.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.customerCompanyModel?.message ==
                "Company not found") {
              cubit.showCustomToast(
                message: AppStrings.company_not_found.tr(),
                color: ColorManager.lightError,
              );
            } else {
              cubit.showCustomToast(
                message: AppStrings.error_creating_company.tr(),
                color: ColorManager.lightError,
                messageColor: ColorManager.white,
              );
            }
          }
        }, builder: (context, state) {
          return SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            AppStrings.country.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CountryPickerWidget(
                            onCountrySelected: handleCountryChange,
                            validator: (value) {
                              if (selectedCountry == "Select Country") {
                                return AppStrings.requiredField.tr();
                              }
                              return null;
                            }),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.companyName.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomTextField(
                          controller: _companNameController,
                          focusNode: _companNameFocusNode,
                          keyboardType: TextInputType.text,
                          labelText: AppStrings.companyName.tr(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.requiredField.tr();
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // _detectInputType(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.commericalName.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomTextField(
                          controller: _commercialNameController,
                          focusNode: _commercialNameFocusNode,
                          keyboardType: TextInputType.text,
                          labelText: AppStrings.commericalName.tr(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.requiredField.tr();
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // _detectInputType(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.commericalNumber.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomTextField(
                          controller: _commercialNumberController,
                          focusNode: _commercialNumberCFocusNode,
                          keyboardType: TextInputType.number,
                          labelText: AppStrings.commericalNumber.tr(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.requiredField.tr();
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // _detectInputType(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.vatNumber.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomTextField(
                          controller: _vatNumberController,
                          focusNode: _vatNumberFocusNode,
                          keyboardType: TextInputType.number,
                          labelText: AppStrings.vatNumber.tr(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.requiredField.tr();
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // _detectInputType(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.vatCertificate.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomFilePicker(
                            controller: _vatCertificatController,
                            focusNode: _vatCertificatFocusNode,
                            labelText: AppStrings.vatCertificate.tr(),
                            onFileSelected: (filePath) {
                              print("Selected file path: $filePath");
                              if (filePath.isNotEmpty &&
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
                            }),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.requesterForm.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomFilePicker(
                            controller: _commercialRegisterFormController,
                            focusNode: _commercialRegisterFormFocusNode,
                            labelText: AppStrings.requesterForm.tr(),
                            onFileSelected: (filePath) {
                              print("Selected file path: $filePath");
                              if (filePath.isNotEmpty &&
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
                            }),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 10),
                          child: Text(
                            AppStrings.breif.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CustomBriefTextField(
                          controller: _eriefController,
                          focusNode: _eriefFocusNode,
                          keyboardType: TextInputType.text,
                          labelText: AppStrings.breif.tr(),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: FutureBuilder(
                                  future: Future.value(false),
                                  builder:
                                      (context, AsyncSnapshot<bool> snapshot) {
                                    if (snapshot.hasData) {
                                      return InkWell(
                                        onTap: () {
                                          if (snapshot.data.toString() ==
                                              "false") {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              cubit.EditCompany(
                                                  companyId:
                                                      widget.companyId ?? '',
                                                  countryName: selectedCountry,
                                                  companyName:
                                                      _companNameController
                                                          .text,
                                                  commercialName:
                                                      _commercialNameController
                                                          .text,
                                                  commercialNumber:
                                                      _commercialNumberController
                                                          .text,
                                                  vATNumber:
                                                      _vatNumberController.text,
                                                  vATCertificate:
                                                      _vatCertificateFile!,
                                                  comRegForm:
                                                      _commercialRegisterFormFile!,
                                                  brief: _eriefController.text);
                                            }
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: AppStrings.vpnDetect.tr(),
                                                backgroundColor:
                                                    ColorManager.lightGrey);
                                          }
                                        },
                                        child: state
                                                is CustomerCompanyLoadingState
                                            ? Container(
                                                width: 360,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color:
                                                      ColorManager.blueLight800,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                      color: ColorManager
                                                          .blueLight800,
                                                      width: 1.0),
                                                ),
                                                alignment: Alignment.center,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    backgroundColor:
                                                        ColorManager
                                                            .blueLight800,
                                                    color: ColorManager.white,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                width: 360,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color:
                                                      ColorManager.blueLight800,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                      color: ColorManager
                                                          .blueLight800,
                                                      width: 1.0),
                                                ),
                                                alignment: Alignment.center,
                                                child: Center(
                                                  child: Text(
                                                    AppStrings.edit.tr(),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      );
                                    } else {
                                      return CircularProgressIndicator(
                                        color: ColorManager.lightGreen,
                                        backgroundColor: ColorManager.white,
                                      );
                                    }
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ));
        }));
  }
}
