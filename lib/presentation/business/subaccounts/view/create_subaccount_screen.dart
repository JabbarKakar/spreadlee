import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/bloc/business/subaccounts/subaccounts_cubit.dart';
import 'package:spreadlee/presentation/customer/login/widget/country_code_text_field.dart';

class CreateSubaccountScreen extends StatefulWidget {
  const CreateSubaccountScreen({super.key});

  @override
  State<CreateSubaccountScreen> createState() => _CreateSubaccountScreenState();
}

class _CreateSubaccountScreenState extends State<CreateSubaccountScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _selectedCountryCode = '+966';
  bool _passwordVisibility = false;
  bool _usernameError = false;
  bool _passwordError = false;
  bool _phoneError = false;
  bool _hasSpace = false;
  bool _passwordLengthError = false;
  bool _phoneLengthError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<SubaccountsCubit>().initFToast(context);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _usernameError = _usernameController.text.isEmpty;
      _passwordError = _passwordController.text.isEmpty;
      _phoneError = _phoneNumberController.text.trim().isEmpty;
      _hasSpace = RegExp(r'\s').hasMatch(_usernameController.text);
      _passwordLengthError = _passwordController.text.isNotEmpty &&
          _passwordController.text.length < 8;
      _phoneLengthError = _phoneNumberController.text.isNotEmpty &&
          _phoneNumberController.text.length < 7;
    });
  }

  Future<void> _handleCreate() async {


    _validateForm();

    if (_usernameError ||
        _passwordError ||
        _phoneError ||
        _hasSpace ||
        _passwordLengthError ||
        _phoneLengthError) {
 
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print("Calling createSubaccount in cubit");
      }
      // Construct phone number from country code and phone number
      final phoneNumber = _phoneNumberController.text.trim().isNotEmpty
          ? (_selectedCountryCode +
              _phoneNumberController.text
                  .trim()
                  .replaceAll(RegExp(r'[^0-9]'), ''))
          : '';

      final result = await context.read<SubaccountsCubit>().createSubaccount(
            username: _usernameController.text,
            passwordGen: _passwordController.text,
            phoneNumber: phoneNumber,
            context: context,
          );

      if (mounted && result == true) {

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in _handleCreate: $e");
      }
      if (mounted) {
        String errorMessage = e.toString();
        // Remove "Exception: " prefix if it exists
        if (errorMessage.startsWith("Exception: ")) {
          errorMessage = errorMessage.substring(11);
        }

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(errorMessage),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 24.0,
          ),
        ),
        title: Text(
          'SubAccounts',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Subaccount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 32.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Enter username, phone number and password',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.gray400,
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username: *',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            decoration: BoxDecoration(
                              color: ColorManager.gray100,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: _usernameError || _hasSpace
                                    ? ColorManager.alertError500
                                    : ColorManager.gray50,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Username',
                                      hintStyle:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: ColorManager.gray500,
                                        fontSize: 14.0,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 12.0,
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp('[a-zA-Z0-9]'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_usernameError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                'Please enter username.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorManager.alertError500,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          if (_hasSpace)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                'Username should not contain spaces.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorManager.alertError500,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number: *',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          CountryCodeTextField(
                            initialCountryCode: _selectedCountryCode,
                            phoneLengthError: _phoneLengthError,
                            enterPhoneError: _phoneError,
                            onChange: (value) {
                              setState(() {
                                _phoneError = false;
                                _phoneLengthError = false;
                              });
                            },
                            updateMaskLength: (maskLength) {
                              // Optionally handle mask length if needed
                            },
                            controller: _phoneNumberController,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password: *',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            decoration: BoxDecoration(
                              color: ColorManager.gray100,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: _passwordError || _passwordLengthError
                                    ? ColorManager.alertError500
                                    : ColorManager.gray50,
                                width: 1.0,
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisibility,
                              decoration: InputDecoration(
                                hintText: 'Enter Password',
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: ColorManager.gray500,
                                  fontSize: 14.0,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisibility =
                                          !_passwordVisibility;
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
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp('\\S+')),
                              ],
                            ),
                          ),
                          if (_passwordError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                'Please enter password.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorManager.alertError500,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          if (_passwordLengthError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                'Password should be at least 8 characters.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorManager.alertError500,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.blueLight800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Create',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
