import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/app_prefs.dart';
import 'package:spreadlee/core/di.dart';
import 'package:spreadlee/core/input_formatters.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/customer/login/widget/login_header.dart';
import 'package:spreadlee/presentation/customer/login/widget/country_code_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:spreadlee/presentation/widgets/custom_file_picker.dart';
import '../../../../presentation/widget/select_country_widget.dart';
import 'package:spreadlee/presentation/resources/localStoreList.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../../../policy_and_terms/policy_and_terms.dart';
import '../../../resources/routes_manager.dart';
import '../../../resources/string_manager.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppPreferences _appPreferences = instance<AppPreferences>();
  final _fullNameController = TextEditingController();
  final _publicNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _commercialNameController = TextEditingController();
  final _commercialNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final TextEditingController _vatCertificatController =
      TextEditingController();
  final FocusNode _vatCertificatFocusNode = FocusNode();
  XFile? _vatCertificateFile;

// Commercial Registration Form
  final TextEditingController _commercialRegisterFormController =
      TextEditingController();
  final FocusNode _commercialRegisterFormFocusNode = FocusNode();
  XFile? _commercialRegistrationFile;

// Pricing & Details
  final TextEditingController _pricingDetailsController =
      TextEditingController();
  final FocusNode _pricingDetailsFocusNode = FocusNode();
  XFile? _pricingDetailsFile;
  final _phoneNumberController = TextEditingController();
  String _selectedCountryCode = '+966';
  String _selectedCountry = '';
  String? _selectedPriceTag;
  bool _commercialNameError = false;
  final bool _pricingDetailsError = false;
  bool _countryCityError = false;
  bool _phoneNumberError = false;
  bool _phoneLengthError = false;
  bool _emailError = false;
  bool _confirmEmailError = false;
  bool _emailDoesntMatchError = false;
  int _errCounter = 0;
  List<SelectedCountry> _selectedCountries = [];

  final List<String> _marketingFields = companyServices;

  List<String> _selectedMarketingFields = [];

  final List<String> _priceTags = PricesTag;

  @override
  void dispose() {
    _fullNameController.dispose();
    _publicNameController.dispose();
    _companyNameController.dispose();
    _commercialNameController.dispose();
    _commercialNumberController.dispose();
    _vatNumberController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _vatCertificatController.dispose();
    _vatCertificatFocusNode.dispose();
    _commercialRegisterFormFocusNode.dispose();
    _pricingDetailsFocusNode.dispose();
    _commercialRegisterFormController.dispose();
    _pricingDetailsController.dispose();
    _phoneNumberController.dispose();

    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _errCounter = 0;
      _commercialNameError = _commercialNameController.text.isEmpty;
      _countryCityError = _selectedCountry.isEmpty;
      _phoneNumberError = _phoneNumberController.text.trim().isEmpty;
      _emailError =
          _emailController.text.isEmpty || !_emailController.text.contains('@');
      _confirmEmailError = _confirmEmailController.text.isEmpty;
      _emailDoesntMatchError =
          _emailController.text != _confirmEmailController.text;

      if (_commercialNameError) _errCounter++;
      if (_pricingDetailsError) _errCounter++;
      if (_countryCityError) _errCounter++;
      if (_phoneNumberError) _errCounter++;
      if (_emailError) _errCounter++;
      if (_confirmEmailError || _emailDoesntMatchError) _errCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoginHeaderWidget(),
                    const SizedBox(height: 24.0),
                    const Text(
                      'As Company',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Basic Information
                    _buildTextField(
                      label: 'Company Name: *',
                      controller: _companyNameController,
                      hintText: 'Enter Company Name',
                      isRequired: true,
                      inputFormatters: [AnyCharactersFormatter()],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Commercial Name: *',
                      controller: _commercialNameController,
                      hintText: 'Enter Commercial Name',
                      isRequired: true,
                      hasError: _commercialNameError,
                      inputFormatters: [AnyCharactersFormatter()],
                    ),
                    if (_commercialNameError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please enter commercial name.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Commercial Number: *',
                      controller: _commercialNumberController,
                      hintText: 'Enter Commercial Number',
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [EnglishNumbersOnlyFormatter()],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'VAT Number: *',
                      controller: _vatNumberController,
                      hintText: 'Enter VAT Number',
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [EnglishNumbersOnlyFormatter()],
                    ),

                    // Document Upload
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _countryCityError
                              ? Colors.red
                              : Colors.transparent,
                        ),
                      ),
                      child: CustomFilePicker(
                        controller: _vatCertificatController,
                        focusNode: _vatCertificatFocusNode,
                        labelText: 'Vat Certificate',
                        pdfOnly: true,
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
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _commercialNameError
                              ? Colors.red
                              : Colors.transparent,
                        ),
                      ),
                      child: CustomFilePicker(
                        controller: _commercialRegisterFormController,
                        focusNode: _commercialRegisterFormFocusNode,
                        labelText: 'Commercial Registration Form',
                        pdfOnly: true,
                        onFileSelected: (filePath) {
                          print("Selected file path: $filePath");
                          if (filePath.isNotEmpty &&
                              File(filePath).existsSync()) {
                            setState(() {
                              _commercialRegistrationFile = XFile(filePath);
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _pricingDetailsError
                              ? Colors.red
                              : Colors.transparent,
                        ),
                      ),
                      child: CustomFilePicker(
                        controller: _pricingDetailsController,
                        focusNode: _pricingDetailsFocusNode,
                        labelText: 'Pricing & Details',
                        pdfOnly: true,
                        onFileSelected: (filePath) {
                          print("Selected file path: $filePath");
                          if (filePath.isNotEmpty &&
                              File(filePath).existsSync()) {
                            setState(() {
                              _pricingDetailsFile = XFile(filePath);
                              _pricingDetailsController.text =
                                  filePath.split('/').last;
                            });
                          } else {
                            Fluttertoast.showToast(
                                msg: "Invalid file selected.");
                          }
                        },
                      ),
                    ),
                    if (_pricingDetailsError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please upload pricing & details.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Location Selection
                    const SizedBox(height: 16),
                    const Text(
                      'Country & City (multiple select): *',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _countryCityError
                              ? Colors.red
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          _selectedCountry.isEmpty
                              ? 'Select Country & City'
                              : _selectedCountry,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          final result =
                              await showModalBottomSheet<List<SelectedCountry>>(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) {
                              return SelectCountryWidget(
                                initialSelectedCountries: _selectedCountries,
                                onSelectionDone: (selectedCountries) {
                                  setState(() {
                                    _selectedCountries = selectedCountries;
                                    if (selectedCountries.isNotEmpty) {
                                      _selectedCountry = selectedCountries
                                          .map((country) => country.countryName)
                                          .join(', ');
                                    } else {
                                      _selectedCountry = '';
                                    }
                                  });
                                },
                              );
                            },
                          );

                          if (result != null) {
                            setState(() {
                              _selectedCountries = result;
                              if (result.isNotEmpty) {
                                _selectedCountry = result
                                    .map((country) => country.countryName)
                                    .join(', ');
                              } else {
                                _selectedCountry = '';
                              }
                            });
                          }
                        },
                      ),
                    ),
                    if (_countryCityError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select country and city.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Phone Number
                    const SizedBox(height: 16),
                    const Text(
                      'Phone Number: *',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    CountryCodeTextField(
                      initialCountryCode: _selectedCountryCode,
                      phoneLengthError: _phoneLengthError,
                      enterPhoneError: _phoneNumberError,
                      onChange: (value) {
                        setState(() {
                          _phoneNumberError = false;
                          _phoneLengthError = false;
                        });
                      },
                      updateMaskLength: (maskLength) {
                        // Optionally handle mask length if needed
                      },
                      controller: _phoneNumberController,
                    ),

                    // Email Fields
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email: *',
                      controller: _emailController,
                      hintText: 'Enter Email',
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                      hasError: _emailError,
                    ),
                    if (_emailError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please enter email address.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Confirm Email: *',
                      controller: _confirmEmailController,
                      hintText: 'Confirm Email',
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                      hasError: _confirmEmailError || _emailDoesntMatchError,
                    ),
                    if (_confirmEmailError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please enter confirmation email.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_emailDoesntMatchError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'The email does not match.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Marketing Fields
                    const SizedBox(height: 16),
                    const Text(
                      'Marketing Fields: *',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MultiSelectDialogField<String>(
                        items: _marketingFields
                            .map((e) => MultiSelectItem<String>(e, e))
                            .toList(),
                        title: const Text("Select Services"),
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.white,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        buttonIcon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                        buttonText: Text(
                          "Select Services",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        onConfirm: (results) {
                          setState(() {
                            _selectedMarketingFields = results;
                          });
                        },
                        chipDisplay: MultiSelectChipDisplay(
                          chipColor: Colors.grey[300],
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide.none,
                          ),
                          alignment: Alignment.topLeft,
                        ),
                      ),
                    ),

                    // Price Range
                    const SizedBox(height: 16),
                    const Text(
                      'Price Range:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          _selectedPriceTag ?? 'Select Price Range',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text(
                                  "Select Price Range",
                                  style: TextStyle(fontSize: 16),
                                ),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _priceTags.length,
                                    itemBuilder: (context, index) {
                                      final price = _priceTags[index];
                                      return RadioListTile<String>(
                                        title: Text(
                                          price,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        value: price,
                                        groupValue: _selectedPriceTag,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedPriceTag = value;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          _validateForm();
                          if (_errCounter == 0) {
                            // "Convert" (or "serialize") "_selectedCountries" (a list of "SelectedCountry" objects) into a "plain" (encodable) list (a "List<Map<String, dynamic>>").
                            final List<Map<String, dynamic>> countries =
                                _selectedCountries
                                    .map((country) => {
                                          "country_code": country.countryCode,
                                          "country_name": country.countryName,
                                          "cities": country
                                              .cities, // (or "city_names": country.cities, if "cities" is a "List<String>")
                                        })
                                    .toList();

                            // (Optional) "Extract" "country_names" (or "city_names") (for example, "country_names" is a "List<String>" of "countryName"s).
                            final List<String> countryNames = _selectedCountries
                                .map((country) => country.countryName)
                                .toList();
                            final List<String> cityNames = _selectedCountries
                                .expand((country) => country.cities)
                                .toList();

                            // Convert files to MultipartFile using the same structure as customer_company_cubit
                            MultipartFile? vatCertificateFile;
                            MultipartFile? commercialRegistrationFile;
                            MultipartFile? pricingDetailsFile;

                            if (_vatCertificateFile != null) {
                              vatCertificateFile = await MultipartFile.fromFile(
                                File(_vatCertificateFile!.path).path,
                                filename: _vatCertificateFile!.name,
                              );
                            }

                            if (_commercialRegistrationFile != null) {
                              commercialRegistrationFile =
                                  await MultipartFile.fromFile(
                                File(_commercialRegistrationFile!.path).path,
                                filename: _commercialRegistrationFile!.name,
                              );
                            }

                            if (_pricingDetailsFile != null) {
                              pricingDetailsFile = await MultipartFile.fromFile(
                                File(_pricingDetailsFile!.path).path,
                                filename: _pricingDetailsFile!.name,
                              );
                            }

                            // Construct phone number from country code and phone number
                            final phoneNumber =
                                _phoneNumberController.text.trim().isNotEmpty
                                    ? (_selectedCountryCode +
                                        _phoneNumberController.text
                                            .trim()
                                            .replaceAll(RegExp(r'[^0-9]'), ''))
                                    : '';

                            final registrationData = {
                              "companyName": _companyNameController.text,
                              "commercialName": _commercialNameController.text,
                              "commercialNumber":
                                  _commercialNumberController.text,
                              'role': 'company',
                              "vatNumber": _vatNumberController.text,
                              "vATCertificate": vatCertificateFile,
                              "comRegForm": commercialRegistrationFile,
                              "pricingDetails": pricingDetailsFile,
                              "countries": countries,
                              "country_names": countryNames,
                              "city_names": cityNames,
                              "isApproved": false,
                              "marketing_fields": _selectedMarketingFields,
                              "selectedPriceTag": _selectedPriceTag,
                              "email": _emailController.text,
                              "phoneNumber": phoneNumber,
                            };

                            // "Pass" (or "send") "registrationData" (or "formData") (for example, via "Navigator.pushNamed" (or "AuthCubit"'s "register" (or "submit"))).
                            Navigator.pushNamed(
                                context, Routes.bankDetailsRoute,
                                arguments: registrationData);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.blueLight800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, Routes.logincompanyRoute);
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: ColorManager.blueLight800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.byLoggingIn.tr(),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              bool isArabic =
                                  _appPreferences.getAppLanguage() == 'ar';
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PolicyAndTerms(
                                    documentType: isArabic
                                        ? DocumentType.policyArabic
                                        : DocumentType.policyEnglish,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              AppStrings.privatPolicy.tr(),
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ColorManager.blueLight800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
    TextInputType? keyboardType,
    bool hasError = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? ' *' : ''}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red : Colors.transparent,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    if (keyboardType == TextInputType.emailAddress &&
                        !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
