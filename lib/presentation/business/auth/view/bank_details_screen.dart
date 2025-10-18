import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/input_formatters.dart';
import 'package:spreadlee/presentation/bloc/business/auth_bloc/auth_cubit.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';

import '../../../customer/customer_company/widget/select_country.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';
import '../../../widgets/registration_success_dialog.dart';

class BankDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;
  const BankDetailsScreen({Key? key, required this.registrationData})
      : super(key: key);

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
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

  void handleCountryChange(String country) {
    setState(() {
      selectedCountry = country;
    });
  }

  @override
  Widget build(BuildContext context) {
    var cubit = AuthCubit.get(context);
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: BlocConsumer<AuthCubit, LoginStates>(listener: (context, state) {
        if (state is RegistrationSuccessState) {
          if (cubit.loginModel?.message ==
              "Company user successfully created") {
            // Show success dialog instead of direct navigation
            RegistrationSuccessDialog.show(
              context,
              onOkPressed: () {
                Navigator.pushReplacementNamed(
                    context, Routes.logincompanyRoute);
              },
            );
          } else if (cubit.loginModel?.message == "User Already Exists") {
            cubit.showCustomToast(
              message: "User Already Exists",
              color: ColorManager.lightError,
            );
          } else if (cubit.loginModel?.message ==
              "You have a pending request for approval") {
            cubit.showCustomToast(
              message: "You have a pending request for approval",
              color: ColorManager.lightError,
            );
          } else if (cubit.loginModel?.message == "All fields are required") {
            cubit.showCustomToast(
              message: AppStrings.otpStillValid.tr(),
              color: ColorManager.lightError,
            );
          } else {
            // Handle other successful registration messages
            RegistrationSuccessDialog.show(
              context,
              onOkPressed: () {
                Navigator.pushReplacementNamed(
                    context, Routes.logincompanyRoute);
              },
            );
          }
        }
        if (state is RegistrationErrorState) {
          cubit.showCustomToast(
              message: AppStrings.errorOnSendOtp.tr(),
              color: ColorManager.lightError,
              messageColor: ColorManager.white);
        }
      }, builder: (context, state) {
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Bank Details',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your bank details through which you want to recieve your payment.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFBFC6CC),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Country:'),
              CountryPickerWidget(
                onCountrySelected: handleCountryChange,
              ),
              const SizedBox(height: 18),
              _buildLabel('Bank name:'),
              _buildTextField(_bankNameController, 'Enter Bank Name',
                  inputFormatters: [AnyCharactersFormatter()]),
              _buildLabel('Holder Name:'),
              _buildTextField(_holderNameController, 'Enter Holder Name',
                  inputFormatters: [AnyCharactersFormatter()]),
              _buildLabel('Bank Account Number:'),
              _buildTextField(_accountNumberController, 'Enter Account Number',
                  inputFormatters: [EnglishNumbersOnlyFormatter()],
                  keyboardType: TextInputType.number),
              _buildLabel('IBAN Number:'),
              _buildTextField(_ibanController, 'Enter IBAN Number',
                  inputFormatters: [AnyCharactersFormatter()]),
              _buildLabel('Branch Name:'),
              _buildTextField(_branchNameController, 'Enter Branch Name',
                  inputFormatters: [AnyCharactersFormatter()]),
              _buildLabel('Branch Code:'),
              _buildTextField(_branchCodeController, 'Enter Branch Code',
                  inputFormatters: [AnyCharactersFormatter()]),
              _buildLabel('Swift Code:'),
              _buildTextField(_swiftCodeController, 'Enter Swift Code',
                  inputFormatters: [AnyCharactersFormatter()]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
                  child: FutureBuilder(
                      future: Future.value(false),
                      builder: (context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasData) {
                          return InkWell(
                            onTap: () {
                              if (snapshot.data.toString() == "false") {
                                if (_formKey.currentState!.validate()) {
                                  final allData = {
                                    ...widget.registrationData,
                                    'bankCountry': selectedCountry,
                                    'bankName': _bankNameController.text,
                                    'bankHolderName':
                                        _holderNameController.text,
                                    'bankAccountNumber':
                                        _accountNumberController.text,
                                    'bankIBANNumber': _ibanController.text,
                                    'bankBranchName':
                                        _branchNameController.text,
                                    'bankBranchCode':
                                        _branchCodeController.text,
                                    'bankSwiftCode': _swiftCodeController.text,
                                    // add any other bank fields here
                                  };
                                  cubit.registerBusiness(
                                      registrationData: allData);
                                }
                              } else {
                                Fluttertoast.showToast(
                                    msg: AppStrings.vpnDetect.tr(),
                                    backgroundColor: ColorManager.lightGrey);
                              }
                            },
                            child: state is RegistrationLoadingState
                                ? Center(
                                    child: CircularProgressIndicator(
                                      backgroundColor:
                                          ColorManager.blueLight800,
                                      color: ColorManager.white,
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: ColorManager.blueLight800,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                          color: ColorManager.blueLight800,
                                          width: 1.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Center(
                                      child: Text(
                                        'Confirm',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String hint,
      {List<TextInputFormatter>? inputFormatters,
      TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFBFC6CC),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
