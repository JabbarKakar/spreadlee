import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/core/di.dart';
import 'package:spreadlee/core/app_prefs.dart';
import 'package:spreadlee/presentation/bloc/business/auth_bloc/auth_cubit.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/services/chat_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final AppPreferences _appPreferences = instance<AppPreferences>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var cubit = AuthCubit.get(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, LoginStates>(
        listener: (context, state) async {
          if (state is ForgotPasswordSuccessState) {
            if (cubit.loginModel?.message ==
                "Password reset successful. New password has been sent to your email.") {
              try {
                await ChatService().shutdown();
              } catch (e) {
                // best-effort
              }
              await _secureStorage.delete(key: 'token');
              await _secureStorage.delete(key: 'role');
              _secureStorage.write(key: "isUserLoggedIn", value: "false");
              Navigator.pushReplacementNamed(context, Routes.logincompanyRoute);
            } else if (cubit.loginModel?.message ==
                "Username and email are required") {
              cubit.showCustomToast(
                message: "Username and email are required",
                color: ColorManager.lightError,
              );
            } else if (cubit.loginModel?.message ==
                "User not found with provided username and email") {
              cubit.showCustomToast(
                message: "User not found with provided username and email",
                color: ColorManager.lightError,
              );
            }
          } else if (state is ForgotPasswordErrorState) {
            context.read<AuthCubit>().showCustomToast(
                  message: state.message,
                  color: ColorManager.lightError,
                );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24.0),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          AppStrings.forgotPassword.tr(),
                          style: const TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppStrings.enterEmailUsername.tr(),
                          style: const TextStyle(
                            fontSize: 11.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          AppStrings.email.tr(),
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: AppStrings.enterEmail.tr(),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12.0,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  const BorderSide(color: ColorManager.error),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.pleaseEnterEmail.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14.0),
                        Text(
                          AppStrings.username.tr(),
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: AppStrings.enterUsername.tr(),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12.0,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  const BorderSide(color: ColorManager.error),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.pleaseEnterUsername.tr();
                            }
                            return null;
                          },
                        ),
                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 10.0),
                              child: InkWell(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().forgotPassword(
                                          email: _emailController.text,
                                          username: _usernameController.text,
                                        );
                                  }
                                },
                                child: state is ForgotPasswordLoadingState
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
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border: Border.all(
                                              color: ColorManager.blueLight800,
                                              width: 1.0),
                                        ),
                                        alignment: Alignment.center,
                                        child: Center(
                                          child: Text(
                                            AppStrings.sendOtp.tr(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        )
                      ],
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
