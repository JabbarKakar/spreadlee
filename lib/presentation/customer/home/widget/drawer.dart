import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/core/languages_manager.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/bloc/customer/otp_customer_bloc/otp_customer_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/chat_manager_service.dart';
import 'package:spreadlee/services/chat_socket_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/services/user_status_manager.dart';
import 'package:spreadlee/core/navigation/navigation_service.dart';

import '../../../policy_and_terms/policy_and_terms.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _selectedLanguage = 'en';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String get selectedLanguage => _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  void _loadSelectedLanguage() async {
    String? currentLanguage = await _secureStorage.read(key: 'prefsKeyLang');

    setState(() {
      _selectedLanguage = currentLanguage ?? 'en'; // Default to 'en' if null
    });

    if (currentLanguage == 'ar') {
      await context.setLocale(ARABIC_LOCALE);
    } else if (currentLanguage == 'en') {
      await context.setLocale(ENGLISH_LOCALE);
    }
  }

  void setAppLanguage(BuildContext context, String languageCode) async {
    await _secureStorage.write(key: 'prefsKeyLang', value: languageCode);

    if (languageCode == 'ar') {
      await context.setLocale(ARABIC_LOCALE);
    } else if (languageCode == 'en') {
      await context.setLocale(ENGLISH_LOCALE);
    }

    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: ColorManager.blueLight800,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  alignment: _selectedLanguage == 'ar'
                      ? Alignment.topLeft
                      : Alignment.topRight,
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                _buildDrawerItem(context, Icons.home_filled,
                    AppStrings.home.tr(), Routes.customerHomeRoute),
                _buildDrawerItem(context, Icons.chat, AppStrings.my_chat.tr(),
                    Routes.chatCustomerRoute),
                _buildDrawerItem(
                    context,
                    Icons.notifications,
                    AppStrings.notifications.tr(),
                    Routes.notificationSettingsRoute),
                _buildDrawerItem(
                    context,
                    Icons.edit_note,
                    AppStrings.addEditCompany.tr(),
                    Routes.customerCompanyRoute),
                _buildDrawerItem(
                    context,
                    Icons.cancel,
                    AppStrings.rejectedRequest.tr(),
                    Routes.rejectedRequestsRoute),
                _buildDrawerItem(context, Icons.wallet,
                    AppStrings.paymentMethod.tr(), Routes.paymentMethodRoute),
                _buildDrawerItem(context, Icons.receipt,
                    AppStrings.invoices.tr(), Routes.invoicesRoute),
                _buildDrawerItem(context, Icons.phone,
                    AppStrings.contactUs.tr(), Routes.contactUsRoute),
                _buildDrawerItem(context, Icons.policy,
                    AppStrings.privacyPolicy.tr(), Routes.privacyPolicyRoute),
                _buildDrawerItem(
                    context,
                    Icons.local_police,
                    AppStrings.termsConditions.tr(),
                    Routes.termsAndConditionsRoute),
                _buildDrawerItem(
                  context,
                  Icons.logout,
                  AppStrings.logout.tr(),
                  Routes.loginCustomerRoute,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 40),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_remove_sharp,
                                  size: 50,
                                  color: ColorManager.blueLight800,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Are you sure you want to Delete Your Account Permanently?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                        ),
                                        onPressed: () {
                                          if (context.mounted) {
                                            Navigator.of(context).pop(true);
                                          }
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Poppins',
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
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                        ),
                                        onPressed: () {
                                          if (context.mounted) {
                                            Navigator.of(context).pop(false);
                                          }
                                        },
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Poppins'),
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
                        // Clear cached user contact when deleting account
                        await _secureStorage.delete(key: 'userContact');
                        Constants.userContact = "";
                        Navigator.pushNamedAndRemoveUntil(context,
                            Routes.loginCustomerRoute, (route) => false);
                      }
                    },
                    child: Text(
                      AppStrings.deleteAccount.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLanguageButton(
                          context, AppStrings.english.tr(), 'en'),
                      _buildLanguageButton(
                          context, AppStrings.arabic.tr(), 'ar'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        Navigator.pop(context);

        if (title == AppStrings.logout.tr()) {
          // Gracefully notify backend and stop all socket services before clearing storage
          try {
            if (kDebugMode)
              print('Logout: starting graceful shutdown of socket services');

            // Primary chat service shutdown (sends user_offline, clears listeners, disconnects)
            try {
              await ChatService().shutdown();
            } catch (e) {
              if (kDebugMode) print('Error during ChatService.shutdown(): $e');
            }

            // Ensure the ChatService will not be re-initialized accidentally
            try {
              ChatService().suspend();
            } catch (e) {
              if (kDebugMode) print('Error suspending ChatService: $e');
            }

            // Stop and dispose higher-level chat manager and socket implementations
            try {
              ChatManagerService().dispose();
            } catch (e) {
              if (kDebugMode) print('Error disposing ChatManagerService: $e');
            }

            try {
              ChatSocketService().dispose();
            } catch (e) {
              if (kDebugMode) print('Error disposing ChatSocketService: $e');
            }

            // Stop the generic socket service reconnection attempts and disconnect
            try {
              // Use the suspend() API to ensure no reconnection attempts or
              // accidental re-initialization after logout.
              SocketService().suspend();
            } catch (e) {
              if (kDebugMode) print('Error suspending SocketService: $e');
            }

            // Ensure user status manager disconnects
            try {
              UserStatusManager().disconnect();
            } catch (e) {
              if (kDebugMode)
                print('Error disconnecting UserStatusManager: $e');
            }

            if (kDebugMode) print('Logout: socket services shutdown completed');
          } catch (e) {
            if (kDebugMode)
              print('Unexpected error during logout shutdown: $e');
          }

          await _secureStorage.delete(key: 'token');
          await _secureStorage.delete(key: 'role');
          await _secureStorage.delete(key: 'subMainAccount');
          await _secureStorage.delete(key: 'username');
          await _secureStorage.delete(key: 'photoUrl');
          await _secureStorage.delete(key: 'commercialName');
          await _secureStorage.delete(key: 'publicName');
          await _secureStorage.delete(key: 'userId');
          await _secureStorage.delete(key: 'phoneNumber');
          await _secureStorage.delete(key: 'userContact');
          await _secureStorage.write(key: "isUserLoggedIn", value: "false");

          // Clear constants
          Constants.token = "";
          Constants.role = "";
          Constants.subMainAccount = "";
          Constants.username = "";
          Constants.photoUrl = "";
          Constants.commercialName = "";
          Constants.publicName = "";
          Constants.userId = "";
          Constants.userContact = ""; // Clear cached user contact

          // Use mounted check before navigating after async work. If the
          // local context is no longer mounted (drawer popped), fall back to
          // the global navigator key so we still navigate to the login screen.
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, Routes.loginCustomerRoute, (route) => false);
          } else if (NavigationService.navigatorKey.currentState != null) {
            NavigationService.navigatorKey.currentState!
                .pushNamedAndRemoveUntil(
                    Routes.loginCustomerRoute, (route) => false);
          } else {
            if (kDebugMode) {
              print(
                  'Logout: No navigator available to navigate to login screen');
            }
          }
        } else if (route == Routes.privacyPolicyRoute) {
          bool isArabic = _selectedLanguage == 'ar';
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PolicyAndTerms(
                  documentType: isArabic
                      ? DocumentType.policyArabic
                      : DocumentType.policyEnglish,
                ),
              ),
            );
          }
        } else if (route == Routes.termsAndConditionsRoute) {
          bool isArabic = _selectedLanguage == 'ar';
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PolicyAndTerms(
                  documentType: isArabic
                      ? DocumentType.termsArabic
                      : DocumentType.termsEnglish,
                ),
              ),
            );
          }
        } else {
          // Navigate directly without socket initialization
          // Socket will be initialized when the chat screen loads
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, route);
          } else {
            if (kDebugMode) {
              print('Context is not mounted, skipping navigation to: $route');
            }
          }
        }
      },
    );
  }

  Widget _buildLanguageButton(
      BuildContext context, String text, String languageCode) {
    bool isSelected = _selectedLanguage == languageCode;
    return ElevatedButton(
      onPressed: () => setAppLanguage(context, languageCode),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 35),
        backgroundColor: isSelected ? Colors.white : Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? ColorManager.blueLight800 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
