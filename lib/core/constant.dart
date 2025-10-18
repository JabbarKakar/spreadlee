class Constants {
  // Font Family
  static const String fontFamily = 'Poppins';

  static const String privacyPolicyLink =
      "https://spreadlee.com/en/privacy-policy/";
  static const String termsAndConditionsLink =
      "http://spreadlee.com/en/terms-and-conditions";
  // static const String baseUrl = "http://172.20.10.10:5000/api";
  static const String baseUrl =
      "https://api.spreadleebackend.com/api"; // Production
//   static const String baseUrl = "http://localhost:4000/api"; //Local

  // Socket base URL (without /api for WebSocket connections)
  static const String socketBaseUrl =
      "https://api.spreadleebackend.com"; // Production
//   static const String socketBaseUrl = "http://localhost:4000"; //Local
  // Note: WebSocket will automatically use wss:// for secure connections
  static const String login = "/user/register/customer";
  static const String verifyOtp = "/user/verifyOtp";
  static const String addCustomerCountry = "/user/addCustomerCountry";
  static const String editCustomerCountry = "/customer/company/edit";
  static const String getAllComp_Infl =
      "/customer/home/getAll-Company-Influencer";
  static const String homeFilter = "/customer/home/filter";
  static const String homeSearch = "/customer/home/search";
  static const String customerCompanyId = "/customer/company/get";
  static const String createCustomerCompany = "/customer/company/create";
  static const String customerCompany = "/customer/company/get";
  static const String createClientRequest = "/client-requests/create-request";
  static const String deleteAccount = "//user/delete-account";
  static const String rejectedCustomerRequest =
      "/client-requests/rejected-customer-request";
  static const String invoices = "/invoices/get-invoices-customer";
  static const String invoiceById = "/invoices/get-invoices";
  static const String createTicket = "/tickets/tickets-data";
  static const String getTickets = "/tickets/tickets-data";
  static const String getReviews = "/reviews/getReview-specific-company";
  static const String reviews = '/api/reviews';
  static const String loginBusiness = "/user/login/company";
  static const String verifyOtpBusiness = "/user/verifyOtp/company";
  static const String forgotPassword = "/user/forgot-password";
  static const String registration = "/user/register";
  static const String invoicesBusiness = "/invoices/get-invoices-company";
  static const String getPricingDetails = "/setting/get-pricingDetails";
  static const String editPricingDetails = "/setting/upload-pricingDetails";
  static const String claimInvoices = "/invoices/get-invoices-paid";
  static const String claimRequest = "/invoices/update-Claim-status";
  static const String createSubaccount = "/account/add-subaccount";
  static const String getSubaccounts = "/account/get-all-subaccounts";
  static const String deleteSubaccount = "/account/subaccounts/";
  static const String updateSubaccount = "/account/subaccounts/";

  static const String prepareCardRegistration =
      "/hyperpay/prepare-registration";
  static const String saveCard = "/payment/savePaymentMethod";
  static const String deleteCard = "/payment/deletePaymentMethod";
  static const String getCards = "/payment/getUserPaymentMethods";
  static const String setDefaultCard = "/payment/setDefaultPaymentMethod";
  // Client Requests Endpoints
  static const String getClientRequests = '/client-requests/get-client-request';
  static const String acceptClientRequest =
      '/client-requests/approve-client-request/';
  static const String rejectClientRequest =
      '/client-requests/reject-client-request/';
  static const String getReviewCompany = "/reviews/getMy-reviews";
  static const String getTaxInvoices = "/invoices/get-tax-invoices";
  static const String getUserPhoto = "/setting/get-photo";
  static const String changePhoto = "/setting/upload-photo";
  static const String changePassword = "/setting/change-password";
  static const String getBankDetails = "/setting/getBankDetails";
  static const String updateBankDetalis = "/setting/BankDetails";
  static const String getContactDetails = "/setting/get-contact";
  static const String changeContactDetails = "/setting/change-contact";
  static const String getVatDetails = "/setting/get-vatDetails";
  static const String updateVatDetails = "/setting/upload-vatAndNumber";
  static const String updateMarkting = "/setting/updateMarketingFields";
  static const String getTagPrice = "/setting/getPriceTag";
  static const String updateTagPrice = "/setting/updatePriceTag";
  static const String deletePhoto = "/setting/delete-photo";
  static const String createinvoices = "/invoices/create-invoices";
  static const String chatBusinessList = "/chats/get-chat-company";
  static const String chatCustomerList = "/chats/get-chat-customer";
  static const String chatMessages = "/chats/get-messages-by-chat-id";
  static const String deleteChatBusiness = "/chats/get-chat-company";
  static const String closeChatBusiness = "/chats/get-chat-company";
  static const String updateVatNumber = '/settings/vat-number';
  static const String closeChat = '/chats/close';
  static const String deleteChat = '/chats/delete';
  static const String chatFilter = '/chats/get-chat-company-filtered';
  static const String updateInvoics = "/invoices/update-invoices";
  static const String addReview = "/reviews/addReview";

  static String token = "";
  static String userId = "";
  static String userContact = "";
  static String userEmail = "";
  static String role = "";
  static String locationId = "";
  static String commercialName = "";
  static String publicName = "";
  static String photoUrl = "";
  static String subMainAccount = "";
  static String username = "";
  static int userNumber = 0;
  static const connectTimeOut = 15000;
  static const receiveTimeOut = 15000;
}
