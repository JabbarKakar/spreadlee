import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/core/languages_manager.dart';
import 'package:spreadlee/presentation/business/home/widget/reviews.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/business/review_bloc/review_cubit.dart';
import '../../../bloc/business/review_bloc/review.states.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../policy_and_terms/policy_and_terms.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/chat_manager_service.dart';
import 'package:spreadlee/services/chat_socket_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/services/user_status_manager.dart';
import 'package:spreadlee/core/navigation/navigation_service.dart';

class AppDrawerBusiness extends StatefulWidget {
  const AppDrawerBusiness({super.key});

  @override
  _AppDrawerBusinessState createState() => _AppDrawerBusinessState();
}

class _AppDrawerBusinessState extends State<AppDrawerBusiness> {
  String _selectedLanguage = 'en';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String get selectedLanguage => _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
    _loadConstantsFromStorage();
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

  Future<void> _loadConstantsFromStorage() async {
    String? savedRole = await _secureStorage.read(key: 'role');
    String? savedPhotoUrl = await _secureStorage.read(key: 'photoUrl');
    String? savedCommercialName =
        await _secureStorage.read(key: 'commercialName');
    String? savedPublicName = await _secureStorage.read(key: 'publicName');
    String? savedUserId = await _secureStorage.read(key: 'userId');
    String? savedSubMainAccount =
        await _secureStorage.read(key: 'subMainAccount');
    String? savedUsername = await _secureStorage.read(key: 'username');

    setState(() {
      Constants.role = savedRole ?? "";
      Constants.photoUrl = savedPhotoUrl ?? "";
      Constants.commercialName = savedCommercialName ?? "";
      Constants.publicName = savedPublicName ?? "";
      Constants.userId = savedUserId ?? "";
      Constants.subMainAccount = savedSubMainAccount ?? "";
      Constants.username = savedUsername ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: ColorManager.blueLight800,
        child: SafeArea(
          child: Column(
            children: [
              // Main content area - takes available space
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: const AlignmentDirectional(1.0, -1.0),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 24.0, 10.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.close,
                              color: ColorManager.secondaryBackground,
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                      // Only show review container for non-subaccount users
                      if (Constants.role != 'subaccount')
                        Container(
                          decoration: const BoxDecoration(),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 62,
                                height: 62,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: Constants.photoUrl.isNotEmpty
                                        ? Constants.photoUrl
                                        : 'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/spread-lee-xf1i5z/assets/gnm1dhgwv47f/profile.png',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    BlocBuilder<ReviewCompanyCubit,
                                        ReviewStates>(
                                      builder: (context, state) {
                                        String ratingText = 'Rating: 0.0';
                                        if (state is ReviewSuccessState) {
                                          ratingText =
                                              'Rating: ${state.reviewsResponse.averageRating.toStringAsFixed(1) ?? '0.0'}';
                                        }
                                        return Row(
                                          children: [
                                            Text(
                                              ratingText,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                              size: 12.5,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 0),
                                    // Only show Reviews button for non-subaccount users
                                    if (Constants.role != 'subaccount')
                                      ElevatedButton(
                                        onPressed: () {
                                          ReviewsCompanyDialog.show(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          minimumSize: const Size(88, 24),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        child: Text(
                                          'Reviews',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: ColorManager.blueLight800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(
                        height: 2,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 20.0),
                          child: Text(
                            Constants.role == 'influencer'
                                ? Constants.publicName ?? ''
                                : Constants.role == 'company'
                                    ? Constants.commercialName ?? ''
                                    : Constants.username ?? '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // Always show Home
                      _buildDrawerItem(context, Icons.home_filled,
                          AppStrings.home.tr(), Routes.companyHomeRoute),

                      // Show these items only for non-subaccount users
                      if (Constants.role != 'subaccount') ...[
                        _buildDrawerItem(
                            context,
                            Icons.edit,
                            'Edit Details&Pricing',
                            Routes.editDetailsPricingRoute),
                        _buildDrawerItem(context, Icons.account_balance_wallet,
                            'My Wallet', Routes.myWalletRoute),
                        _buildDrawerItem(
                            context,
                            Icons.notifications,
                            AppStrings.notifications.tr(),
                            Routes.notificationSettingsBusinessRoute),
                      ],

                      // Always show Client Requests
                      _buildDrawerItem(context, Icons.add_moderator,
                          'Clients Requests', Routes.clientRequestsRoute),

                      // Show Add subaccount only for non-subaccount users
                      if (Constants.role != 'subaccount')
                        _buildDrawerItem(context, Icons.person_add_alt,
                            'Add subaccount', Routes.subaccountsRoute),

                      // Always show Invoices
                      _buildDrawerItem(
                          context,
                          Icons.receipt,
                          AppStrings.invoices.tr(),
                          Routes.invoicesBusinessRoute),

                      // Show Tax Invoices only for non-subaccount users
                      if (Constants.role != 'subaccount')
                        _buildDrawerItem(context, Icons.edit_document,
                            'Tax Invoices', Routes.taxInvoicesRoute),

                      // Always show Contact Us
                      _buildDrawerItem(
                          context,
                          Icons.phone,
                          AppStrings.contactUs.tr(),
                          Routes.contactUsBusinessRoute),

                      // Show Settings only for non-subaccount users
                      if (Constants.role != 'subaccount')
                        _buildDrawerItem(context, Icons.settings, 'Setting',
                            Routes.businessSettingsRoute),

                      // Always show Privacy Policy
                      _buildDrawerItem(
                          context,
                          Icons.policy,
                          AppStrings.privacyPolicy.tr(),
                          Routes.privacyPolicyRoute),

                      // Always show Terms and Conditions
                      _buildDrawerItem(
                          context,
                          Icons.local_police,
                          AppStrings.termsConditions.tr(),
                          Routes.termsAndConditionsRoute),

                      // Always show Logout
                      _buildDrawerItem(
                        context,
                        Icons.logout,
                        AppStrings.logout.tr(),
                        Routes.loginCustomerRoute,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Language buttons - always at the bottom
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLanguageButton(
                        context, AppStrings.english.tr(), 'en'),
                    _buildLanguageButton(context, AppStrings.arabic.tr(), 'ar'),
                  ],
                ),
              ),
            ],
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
              // Suspend generic socket service to stop reconnection attempts
              // and disconnect in a way that prevents automatic re-initialization.
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
          Constants.userContact = "";

          // Use mounted check before navigating after async work; if the local
          // context is unmounted (for example the drawer was dismissed) fall
          // back to the global navigator so navigation still occurs.
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, Routes.loginCustomerRoute, (route) => false);
          } else {
            NavigationService.navigatorKey.currentState
                ?.pushNamedAndRemoveUntil(
                    Routes.loginCustomerRoute, (route) => false);
          }
        } else if (route == Routes.privacyPolicyRoute) {
          bool isArabic = _selectedLanguage == 'ar';
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PolicyAndTerms(
                documentType: isArabic
                    ? DocumentType.policyArabic
                    : DocumentType.policyEnglish,
              ),
            ),
          );
        } else if (route == Routes.termsAndConditionsRoute) {
          bool isArabic = _selectedLanguage == 'ar';
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PolicyAndTerms(
                documentType: isArabic
                    ? DocumentType.termsArabic
                    : DocumentType.termsEnglish,
              ),
            ),
          );
        } else {
          // Navigate directly without socket initialization
          // Socket will be initialized when the chat screen loads
          Navigator.pushReplacementNamed(context, route);
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
