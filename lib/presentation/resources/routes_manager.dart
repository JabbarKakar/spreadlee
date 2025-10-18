import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/domain/customer_company_model.dart';
import 'package:spreadlee/presentation/business/chat/view/chat_screen.dart';
import 'package:spreadlee/presentation/business/invoices/widget/invoice_release_widget.dart';
import 'package:spreadlee/presentation/business/settings/view/edit_vat_certificate_screen.dart';
import 'package:spreadlee/presentation/business/settings/view/settings_widget.dart';
import 'package:spreadlee/presentation/business/edit_details_pricing/View/edit_details_pricing.dart';
import 'package:spreadlee/presentation/business/home/view/home_view.dart';
import 'package:spreadlee/presentation/business/my_wallet/view/my_wallet_screen.dart';
import 'package:spreadlee/presentation/business/settings/view/update_business_bank_details_screen.dart';
import 'package:spreadlee/presentation/business/tax_invoices/view/tax_invoices_view.dart';
import 'package:spreadlee/presentation/customer/chat/view/chat_list.dart';
import 'package:spreadlee/presentation/customer/home/view/home_view.dart';
import 'package:spreadlee/presentation/customer/login/login_view.dart';
import 'package:spreadlee/presentation/customer/verify_otp/otp_view.dart';
import 'package:spreadlee/presentation/business/settings/view/change_password_screen.dart';
import 'package:spreadlee/presentation/splash_screen/splash_view.dart';
import 'package:spreadlee/presentation/widgets/add_review_widget.dart';
import '../business/auth/view/bank_details_screen.dart';
import '../business/auth/view/company_registration_screen.dart';
import '../business/auth/view/influencer_registration_screen.dart';
import '../business/auth/view/login_screen.dart';
import '../business/auth/view/otp_view.dart';
import '../business/client_requests/view/client_requests_screen.dart';
import '../business/contact/view/contact_us_screen.dart';
import '../business/invoices/view/claim_invoices_screen.dart';
import '../business/invoices/view/invoice_details_bank_transfer_screen.dart';
import '../business/invoices/view/invoice_details_screen.dart';
import '../business/invoices/view/invoices_screen.dart';
import '../business/invoices/widget/Invoice_release_bank_transfer.dart';
import '../business/notifications_setting/notification_setting.dart';
import '../business/settings/edit_price_tag_screen.dart';
import '../business/settings/edit_services_screen.dart';
import '../business/settings/view/edit_business_profile_photo_screen.dart';
import '../business/settings/view/edit_email_phone_screen.dart';
import '../business/subaccounts/view/create_subaccount_screen.dart';
import '../business/subaccounts/view/subaccounts_screen.dart';
import '../business/tickets/view/create_ticket_screen.dart';
import '../business/tickets/view/tickets_screen.dart';
import '../customer/customer_company/view/add_company.dart';
import '../customer/customer_company/view/company_list.dart';
import '../customer/home/view/filter_view.dart';
import '../customer/home/view/fiter_results_view.dart';
import '../customer/notifications_setting/notification_setting.dart';
import '../customer/customer_company/view/edit_company.dart';
import '../customer/payment_method/view/payment_method_screen.dart';
import '../customer/rejected_requests/view/rejected_requests.dart';
import '../customer/invoices/view/invoices_screen.dart';
import 'package:spreadlee/presentation/customer/invoices/view/invoice_details_bank_transfer_screen.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/customer/invoices/view/invoice_details_screen.dart';
import 'package:spreadlee/presentation/customer/contact/view/contact_us_screen.dart';
import 'package:spreadlee/presentation/customer/tickets/view/tickets_screen.dart';
import 'package:spreadlee/presentation/customer/tickets/view/create_ticket_screen.dart';
import 'package:spreadlee/presentation/business/auth/view/forgot_password_screen.dart';
import 'package:spreadlee/presentation/customer/home/view/pdf_view_screen.dart';

class Routes {
  static const String splashRoute = "/";
  static const String loginCustomerRoute = "/login";
  static const String logincompanyRoute = "/loginCompany";
  static const String otpVerifyRoute = "/otpVerify";
  static const String compantotpVerifyRoute = "/otpVerifyCompany";
  static const String registerCompanyRoute = "/registerCompany";
  static const String registerInfluencerRoute = "/registerInfluencer";
  static const String customerHomeRoute = "/customerHome";
  static const String companyHomeRoute = "/companyHome";
  static const String customerFilterRoute = "/homeFilter";
  static const String customerFilterResultRoute = "/homeFilterResult";
  static const String customerCompanyRoute = "/customerCompany";
  static const String addCompanyRoute = "/addCompany";
  static const String editCompanyRoute = "/editCompany";
  static const String addEditCompanyRoute = "/addEditCompanyHome";
  static const String rejectedRequestRoute = "/rejectedRequest";
  static const String paymentMethodRoute = "/paymentMethod";
  static const String invoicesRoute = "/invoices";
  static const String taxInvoicesRoute = "/taxInvoices";
  static const String contactUsRoute = "/contactUs";
  static const String privacyPolicyRoute = "/privacyPolicy";
  static const String termsAndConditionsRoute = "/termsAndConditions";
  static const String notificationSettingsRoute = "/notificationSettingsScreen";
  static const String rejectedRequestsRoute = "/rejectedRequests";
  static const String invoiceDetails = '/invoice-details';
  static const String invoiceDetailsBankTransfer =
      '/invoice-details-bank-transfer';
  static const String ticketsRoute = "/tickets";
  static const String createTicketRoute = "/createTicket";
  static const String forgotPasswordRoute = "/forgot-password";
  static const String pdfViewRoute = "/pdf-view";
  static const String bankDetailsRoute = "/bank-details";
  static const String invoicesBusinessRoute = "/invoices-business";
  static const String invoiceDetailsBusinessRoute = "/invoice-details-business";
  static const String invoiceDetailsBankTransferBusinessRoute =
      "/invoice-details-bank-transfer-business";
  static const String ticketsBusinessRoute = "/tickets-business";
  static const String contactUsBusinessRoute = "/contact-us-business";
  static const String createTicketBusinessRoute = "/create-ticket-business";
  static const String notificationSettingsBusinessRoute =
      "/notification-settings-business";
  static const String editDetailsPricingRoute = "/edit-details-pricing";
  static const String myWalletRoute = "/my-wallet";
  static const String createSubaccountRoute = "/create-subaccount";
  static const String subaccountsRoute = "/subaccounts";
  static const String clientRequestsRoute = "/client-requests";
  static const String editBusinessProfilePhotoRoute =
      "/edit-business-profile-photo";
  static const String updateBusinessBankDetailsRoute =
      "/update-business-bank-details";
  static const String updateTagPriceRoute = "/update-tag-price";
  static const String editBusinessContactRoute = "/edit-business-contact";
  static const String editBusinessVATRoute = "/edit-business-vat";
  static const String changePasswordRoute = "/change_password";
  static const String businessSettingsRoute = "/business-settings";
  static const String editServicesRoute = "/edit-services";
  static const String claimInvoicesRoute = "/claim-invoices";
  static const String createInvoicesRoute = "/create-invoices";
  static const String chatRoute = "/chat";
  static const String invoiceReleaseRoute = "/invoice-release";
  static const String invoiceReleaseBankTransRoute =
      "/invoice-release-bank-transfer";
  static const String chatCustomerRoute = "/chat-customer";
  static const String addReviewRoute = "/add-review";
}

class RouteGenerator {
  static PageRoute getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const SplashView());
        } else {
          return CupertinoPageRoute(builder: (_) => const SplashView());
        }
      case Routes.loginCustomerRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const LoginView());
        } else {
          return CupertinoPageRoute(builder: (_) => const LoginView());
        }

      case Routes.otpVerifyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const OtpView());
        } else {
          return CupertinoPageRoute(builder: (_) => const OtpView());
        }

      case Routes.customerHomeRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const HomeView());
        } else {
          return CupertinoPageRoute(builder: (_) => const HomeView());
        }

      case Routes.customerFilterRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const HomeFilter());
        } else {
          return CupertinoPageRoute(builder: (_) => const HomeFilter());
        }

      case Routes.customerFilterResultRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const HomeFilterView());
        } else {
          return CupertinoPageRoute(builder: (_) => const HomeFilterView());
        }
      case Routes.customerCompanyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const CustomerCompany());
        } else {
          return CupertinoPageRoute(builder: (_) => const CustomerCompany());
        }
      case Routes.addCompanyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const AddCompany());
        } else {
          return CupertinoPageRoute(builder: (_) => const AddCompany());
        }
      case Routes.notificationSettingsRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const NotificationSettingsScreen());
        }
      case Routes.invoicesRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const InvoicesScreen());
        } else {
          return CupertinoPageRoute(builder: (_) => const InvoicesScreen());
        }
      case Routes.editCompanyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
            builder: (_) => EditCompany(
              companyData:
                  (settings.arguments as Map<String, dynamic>)['companyData'],
              companyId:
                  (settings.arguments as Map<String, dynamic>)['companyId'],
            ),
          );
        } else {
          return CupertinoPageRoute(
            builder: (_) => EditCompany(
              companyData:
                  (settings.arguments as Map<String, dynamic>)['companyData'],
              companyId:
                  (settings.arguments as Map<String, dynamic>)['companyId'],
            ),
          );
        }
      case Routes.rejectedRequestsRoute:
        return MaterialPageRoute(
          builder: (_) => const RejectedRequestsScreen(),
        );
      case Routes.invoiceDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailsScreen(
            invoice: args['invoice'] as InvoiceModel,
          ),
        );
      case Routes.invoiceDetailsBankTransfer:
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailsBankTransferScreen(),
          settings: settings,
        );
      case Routes.contactUsRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const ContactUsScreen());
        } else {
          return CupertinoPageRoute(builder: (_) => const ContactUsScreen());
        }
      case Routes.ticketsRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const TicketsScreen());
        } else {
          return CupertinoPageRoute(builder: (_) => const TicketsScreen());
        }
      case Routes.createTicketRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const CreateTicketScreen());
        } else {
          return CupertinoPageRoute(builder: (_) => const CreateTicketScreen());
        }
      case Routes.logincompanyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const BusinessLoginView());
        } else {
          return CupertinoPageRoute(builder: (_) => const BusinessLoginView());
        }
      case Routes.compantotpVerifyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const OtpBusinessView());
        } else {
          return CupertinoPageRoute(builder: (_) => const OtpBusinessView());
        }
      case Routes.forgotPasswordRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const ForgotPasswordScreen());
        }
      case Routes.pdfViewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PDFViewScreen(pdfUrl: args['pdfUrl']),
        );
      case Routes.paymentMethodRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const PaymentMethodScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const PaymentMethodScreen());
        }
      case Routes.registerCompanyRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const CompanyRegistrationScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const CompanyRegistrationScreen());
        }
      case Routes.registerInfluencerRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const InfluencerRegistrationScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const InfluencerRegistrationScreen());
        }
      case Routes.bankDetailsRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => BankDetailsScreen(
                    registrationData:
                        settings.arguments as Map<String, dynamic>,
                  ));
        } else {
          return CupertinoPageRoute(
              builder: (_) => BankDetailsScreen(
                    registrationData:
                        settings.arguments as Map<String, dynamic>,
                  ));
        }
      case Routes.companyHomeRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const HomeViewBusiness());
        } else {
          return CupertinoPageRoute(builder: (_) => const HomeViewBusiness());
        }

      case Routes.invoicesBusinessRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const InvoicesBusinessScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const InvoicesBusinessScreen());
        }

      case Routes.invoiceDetailsBusinessRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailsBusinessScreen(
            invoice: args['invoice'] as InvoiceModel,
          ),
        );

      case Routes.invoiceDetailsBankTransferBusinessRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailsBankTransferBusinessScreen(
            invoice: args['invoice'] as InvoiceModel,
          ),
        );

      case Routes.ticketsBusinessRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const TicketsBusinessScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const TicketsBusinessScreen());
        }

      case Routes.createTicketBusinessRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const CreateTicketBusinessScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const CreateTicketBusinessScreen());
        }
      case Routes.notificationSettingsBusinessRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(
              builder: (_) => const NotificationSettingsBusinessScreen());
        } else {
          return CupertinoPageRoute(
              builder: (_) => const NotificationSettingsBusinessScreen());
        }
      case Routes.editDetailsPricingRoute:
        return MaterialPageRoute(
          builder: (_) => const EditDetailsPricing(),
        );
      case Routes.myWalletRoute:
        return MaterialPageRoute(
          builder: (_) => const MyWalletScreen(),
        );
      case Routes.createSubaccountRoute:
        return MaterialPageRoute(
          builder: (_) => const CreateSubaccountScreen(),
        );
      case Routes.subaccountsRoute:
        return MaterialPageRoute(
          builder: (_) => const SubaccountsScreen(),
        );
      case Routes.clientRequestsRoute:
        return MaterialPageRoute(
          builder: (_) => const ClientRequestsScreen(),
        );
      case Routes.taxInvoicesRoute:
        return MaterialPageRoute(
          builder: (_) => const TaxInvoicesView(),
        );
      case Routes.businessSettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const SettingsWidget(),
        );
      case Routes.editBusinessProfilePhotoRoute:
        return MaterialPageRoute(
          builder: (_) => const EditBusinessProfilePhotoScreen(),
        );
      case Routes.updateBusinessBankDetailsRoute:
        return MaterialPageRoute(
          builder: (_) => const UpdateBusinessBankDetailsScreen(),
        );
      case Routes.updateTagPriceRoute:
        return MaterialPageRoute(
          builder: (_) => const EditPriceTagScreen(),
        );
      case Routes.editBusinessContactRoute:
        return MaterialPageRoute(
          builder: (_) => const EditEmailPhoneScreen(),
        );
      case Routes.editBusinessVATRoute:
        return MaterialPageRoute(
          builder: (_) => const EditVatCertificateScreen(),
        );
      case Routes.changePasswordRoute:
        return MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen(),
        );
      case Routes.editServicesRoute:
        return MaterialPageRoute(
          builder: (_) => const EditServicesScreen(),
        );
      case Routes.claimInvoicesRoute:
        final invoice = settings.arguments as InvoiceModel;
        return MaterialPageRoute(
          builder: (_) => ClaimInvoicesScreen(
            invoice: invoice,
          ),
        );
      case Routes.chatRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: args['chatId'] as String,
            userId: args['userId'] as String,
            userRole: args['userRole'] as String,
            companyName: args['companyName'] as String,
            isOnline: args['isOnline'] as bool,
            initialMessages: args['initialMessages'] as List<ChatMessage>?,
          ),
        );
      case Routes.invoiceReleaseRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceReleaseWidget(
            customerCompanyRef: args['customerCompanyRef'] as String,
            customerRef: args['customerRef'] as String,
            name: args['name'] as String,
            chatRef: args['chatId'] as String,
            chatClientRequestRef: args['chatId'] as String,
            companyId: args['companyId'] as Map<String, dynamic>,
            chatCustomerCompanyRef:
                args['chatCustomerCompanyRef'] as Map<String, dynamic>,
          ),
        );
      case Routes.invoiceReleaseBankTransRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => InvoiceReleaseBankTransfer(
            customerCompanyRef: args['customerCompanyRef'] as String,
            customerRef: args['customerRef'] as String,
            name: args['name'] as String,
            chatRef: args['chatId'] as String,
            chatClientRequestRef: args['chatId'] as String,
            companyId: args['companyId'] as Map<String, dynamic>,
            chatCustomerCompanyRef:
                args['chatCustomerCompanyRef'] as Map<String, dynamic>,
          ),
        );
      case Routes.chatCustomerRoute:
        return MaterialPageRoute(
          builder: (_) => const ChatListCustomer(),
        );
      case Routes.addReviewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddReviewWidget(
            influencerDoc: args['influencerDoc'] as InvoiceCompanyRef?,
            customerCompany:
                args['customerCompany'] as CustomerCompanyDataModel?,
          ),
        );
      case Routes.contactUsBusinessRoute:
        if (Platform.isAndroid) {
          return MaterialPageRoute(builder: (_) => const ContactUsBusinessScreen());
        } else {
          return CupertinoPageRoute(builder: (_) => const ContactUsBusinessScreen());
        }
      default:
        return pageNotFound();
    }
  }

  static PageRoute pageNotFound() {
    return MaterialPageRoute(
        builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text(''),
              ),
              body: const Center(child: Text('')),
            ));
  }
}
