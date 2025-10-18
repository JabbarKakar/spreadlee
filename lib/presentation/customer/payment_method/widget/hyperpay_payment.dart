/// Created by Bekhruz Makhmudov on 18/11/24.
/// Project spreadLee
// import 'package:hyperpay_plugin/flutter_hyperpay.dart';
// import 'package:hyperpay_plugin/model/ready_ui.dart';
import 'dart:io';
import 'package:spreadlee/presentation/customer/payment_method/widget/random.dart';

//Future void callback
typedef FutureVoidCallback = Future<void> Function();

enum PaymentMethod {
  VISA_MASTER_CARD("Visa / Master / Amex", "8acda4c886143a7001862beaad757ce7",
      ["VISA", "MASTER", "AMEX"]),
  MADA("Mada", "8acda4c886143a7001862bebc2d67d00", ["MADA"]),
  APPLE_PAY("Apple Pay", "8ac9a4c786c085e00186c69867712a93", ["APPLEPAY"]);

  final String label;
  final String entityId;
  final List<String> brands;

  const PaymentMethod(this.label, this.entityId, this.brands);

  static String getMerchantTransactionID(
      PaymentMethod paymentMethod, String invoiceID) {
    return "${paymentMethod.name}_${randomInteger(0, 9999)}___$invoiceID";
  }
}

// final FlutterHyperPay flutterHyperPay = FlutterHyperPay(
//   shopperResultUrl: InAppPaymentSetting.shopperResultUrl, // return back to app
//   paymentMode: PaymentMode.live, // test or live
//   lang: InAppPaymentSetting.getLang(),
// );

Future<void> payRequestNowReadyUI({
  required PaymentMethod paymentMethod,
  required String checkoutId,
  FutureVoidCallback? checkStatus,
  FutureVoidCallback? registerCard,
}) async {
  // PaymentResultData paymentResultData = await flutterHyperPay.readyUICards(
  //   readyUI: ReadyUI(
  //     brandsName: paymentMethod.brands,
  //     checkoutId: checkoutId,
  //     merchantIdApplePayIOS: InAppPaymentSetting.merchantId,
  //     countryCodeApplePayIOS: InAppPaymentSetting.countryCode,
  //     companyNameApplePayIOS: "Spreadlee",
  //     themColorHexIOS: "#000000",
  //     setStorePaymentDetailsMode: false, // store payment details for future use
  //   ),
  // );

  // if (paymentResultData.paymentResult == PaymentResult.success ||
  //     paymentResultData.paymentResult == PaymentResult.sync) {
  //   await checkStatus?.call();
  //   await registerCard?.call();
  // }
}

class InAppPaymentSetting {
  static const String shopperResultUrl = "com.jafton.spreadlee.payments";
  static const String merchantId = "merchant.com.codesorbit.SpreadLee-iOS";
  static const String countryCode = "SA";

  static getLang() {
    if (Platform.isIOS) {
      return "en"; // ar
    } else {
      return "en_US"; // ar_AR
    }
  }
}
