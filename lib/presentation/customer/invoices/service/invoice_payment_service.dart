import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/customer/payment_method/widget/hyperpay_payment.dart';
import 'package:spreadlee/data/models/card_model.dart';
import 'package:spreadlee/data/remote/hyperpay/hyperpay_registration_api.dart';

class InvoicePaymentService {
  static const String _baseUrl = 'https://eu-prod.oppwa.com/';
  static const String _authToken =
      'Bearer OGFjZGE0Yzg4NjE0M2E3MDAxODYyYmVhMTM1ZTdjZGR8Rnd6dDJNQTROcg==';

  // Entity IDs for different payment methods
  static const String _visaEntityId = '8acda4c886143a7001862beaad757ce7';
  static const String _madaEntityId = '8acda4c886143a7001862bebc2d67d00';
  static const String _applePayEntityId = '8ac9a4c786c085e00186c69867712a93';

  /// Prepare checkout for payment
  static Future<Map<String, dynamic>> prepareCheckout({
    required PaymentMethod paymentMethod,
    required InvoiceModel invoice,
    List<CardModel> savedCards = const [],
  }) async {
    try {
      final entityId = _getEntityId(paymentMethod);
      final amount = invoice.invoiceGrandTotal.toStringAsFixed(2);
      final merchantTransactionId = PaymentMethod.getMerchantTransactionID(
        paymentMethod,
        invoice.invoice_id?.toString() ?? invoice.id.toString(),
      );

      // Get saved card registration IDs for the selected payment method
      final registrationIds = _getRegistrationIds(paymentMethod, savedCards);

      final Map<String, String> body = {
        'entityId': entityId,
        'amount': amount,
        'currency': 'SAR',
        'paymentType': 'DB',
        'merchantTransactionId': merchantTransactionId,
        'customer.email': 'sl@test.com',
        'billing.street1': 'Khobar',
        'billing.city': 'Khobar',
        'billing.state': 'Khobar',
        'billing.country': 'SA',
        'billing.postcode': '34422',
        'customer.givenName': 'Abdul',
        'customer.surname': 'Aziz',
      };

      // Add registration IDs if available
      for (int i = 0; i < registrationIds.length; i++) {
        body['registrations[$i].id'] = registrationIds[i];
      }

      final response = await http.post(
        Uri.parse('${_baseUrl}v1/checkouts'),
        headers: {
          'Authorization': _authToken,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to prepare checkout: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error preparing checkout: $e');
    }
  }

  /// Get payment status
  static Future<Map<String, dynamic>> getPaymentStatus({
    required String checkoutId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final entityId = _getEntityId(paymentMethod);

      final response = await http.get(
        Uri.parse(
            '${_baseUrl}v1/checkouts/$checkoutId/payment?entityId=$entityId'),
        headers: {
          'Authorization': _authToken,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to get payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment status: $e');
    }
  }

  /// Process payment using HyperPay
  static Future<void> processPayment({
    required PaymentMethod paymentMethod,
    required String checkoutId,
    required InvoiceModel invoice,
    required BuildContext context,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await payRequestNowReadyUI(
        paymentMethod: paymentMethod,
        checkoutId: checkoutId,
        checkStatus: () async {
          print("Checking Payment Status<<<<<<<<<");
          final statusResponse = await getPaymentStatus(
            checkoutId: checkoutId,
            paymentMethod: paymentMethod,
          );
          print('Full payment status response:');
          print(statusResponse);

          // Check if payment was successful
          final resultDetails = statusResponse['resultDetails'];
          final result = statusResponse['result'];
          String errorMessage = 'Payment failed';
          if (resultDetails != null) {
            final acquirerMessage = resultDetails['response.acquirerMessage'];
            final acquirerCode = resultDetails['response.acquirerCode'];
            if (acquirerMessage != null && acquirerMessage == 'Approved') {
              // Payment successful
              onSuccess('Payment successful');

              // Show success dialog
              if (context.mounted) {
                // await _showSuccessDialog(context);
              }
              return;
            } else {
              // Payment failed
              errorMessage =
                  acquirerMessage ?? acquirerCode ?? 'Payment failed';
            }
          } else if (result != null) {
            // Sometimes error info is in 'result' field
            final resultDesc = result['description'];
            final resultCode = result['code'];
            errorMessage = resultDesc ?? resultCode ?? 'Payment failed';
          } else if (statusResponse['description'] != null) {
            errorMessage = statusResponse['description'];
          }
          onError(errorMessage);
        },
        registerCard: () async {
          print('Starting card registration...');
          try {
            // Get registration status
            final registrationStatus =
                await HyperPayRegistrationApi.getRegistrationStatus(
              checkoutId: checkoutId,
              cardType: paymentMethod.brands.first,
            );

            if (registrationStatus['id'] != null) {
              print('Card registration completed successfully');
            }
          } catch (e) {
            print('Error during card registration: $e');
          }
        },
      );
    } catch (e) {
      onError('Payment processing failed: $e');
    }
  }

  /// Show success dialog
  static Future<void> _showSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your invoice has been paid successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(); // Close payment modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get entity ID for payment method
  static String _getEntityId(PaymentMethod paymentMethod) {
    switch (paymentMethod) {
      case PaymentMethod.VISA_MASTER_CARD:
        return _visaEntityId;
      case PaymentMethod.MADA:
        return _madaEntityId;
      case PaymentMethod.APPLE_PAY:
        return _applePayEntityId;
    }
  }

  /// Get registration IDs for saved cards
  static List<String> _getRegistrationIds(
    PaymentMethod paymentMethod,
    List<CardModel> savedCards,
  ) {
    return savedCards
        .where((card) {
          final cardBrand = card.cardType.toUpperCase();
          return paymentMethod.brands.contains(cardBrand);
        })
        .map((card) => card.registrationId)
        .toList();
  }
}
