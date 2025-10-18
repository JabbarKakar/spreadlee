import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';

import '../../../resources/routes_manager.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentPasswordController.text == _newPasswordController.text) {
        _showErrorDialog('Current and new passwords should not be the same.');
        return;
      }

      context.read<SettingCubit>().changePassword(
            oldPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.white,
      appBar: AppBar(
        backgroundColor: ColorManager.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorManager.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: getMediumStyle(
            color: ColorManager.black,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocConsumer<SettingCubit, SettingState>(
        listener: (context, state) {
          if (state is CreateSettingSuccessState) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Password changed successfully'),
                backgroundColor: ColorManager.success,
              ),
            );
          } else if (state is CreateSettingErrorState) {
            _showErrorDialog(state.error);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.p16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current password:',
                            style: getMediumStyle(
                              color: ColorManager.black,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppSize.s6),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: !_showCurrentPassword,
                            decoration: InputDecoration(
                              hintText: 'Enter Current Password',
                              filled: true,
                              fillColor: ColorManager.gray100,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSize.s12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showCurrentPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: ColorManager.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showCurrentPassword =
                                        !_showCurrentPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your current password';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'\S+')),
                            ],
                          ),
                          const SizedBox(height: AppSize.s12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, Routes.forgotPasswordRoute);
                              },
                              child: Text(
                                'Forgot Password?',
                                style: getMediumStyle(
                                  color: ColorManager.blueLight800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSize.s12),
                          Text(
                            'New password:',
                            style: getMediumStyle(
                              color: ColorManager.black,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppSize.s6),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: !_showNewPassword,
                            decoration: InputDecoration(
                              hintText: 'Enter New Password',
                              filled: true,
                              fillColor: ColorManager.gray100,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSize.s12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: ColorManager.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showNewPassword = !_showNewPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter a new password';
                              }
                              if (value!.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'\S+')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppPadding.p16),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppSize.s40,
                    child: ElevatedButton(
                      onPressed: state is CreateSettingLoadingState
                          ? null
                          : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.s8),
                        ),
                      ),
                      child: state is CreateSettingLoadingState
                          ? CircularProgressIndicator(
                              color: ColorManager.white,
                            )
                          : Text(
                              'Change',
                              style: getMediumStyle(
                                color: ColorManager.white,
                                fontSize: 16,
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
    );
  }
}
