import 'dart:convert';
import 'package:http/http.dart' as http;

class HyperPayRegistrationApi {
  static const String _baseUrl = 'https://eu-prod.oppwa.com/';
  static const String _authToken =
      'Bearer OGFjZGE0Yzg4NjE0M2E3MDAxODYyYmVhMTM1ZTdjZGR8Rnd6dDJNQTROcg==';

  // Entity IDs for different payment methods
  static const String _visaEntityId = '8acda4c886143a7001862beaad757ce7';
  static const String _madaEntityId = '8acda4c886143a7001862bebc2d67d00';

  static Future<Map<String, dynamic>> prepareCheckoutRegistration({
    required String cardType,
  }) async {
    try {
      final entityId = cardType == 'MADA' ? _madaEntityId : _visaEntityId;

      final response = await http.post(
        Uri.parse('${_baseUrl}v1/checkouts'),
        headers: {
          'Authorization': _authToken,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'entityId': entityId,
          'createRegistration': 'true',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception(
            'Failed to prepare checkout registration: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error preparing checkout registration: $e');
    }
  }

  static Future<Map<String, dynamic>> getRegistrationStatus({
    required String checkoutId,
    required String cardType,
  }) async {
    try {
      final entityId = cardType == 'MADA' ? _madaEntityId : _visaEntityId;

      final response = await http.get(
        Uri.parse(
            '${_baseUrl}v1/checkouts/$checkoutId/registration?entityId=$entityId'),
        headers: {
          'Authorization': _authToken,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to get registration status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting registration status: $e');
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatus({
    required String checkoutId,
    required String cardType,
  }) async {
    try {
      final entityId = cardType == 'MADA' ? _madaEntityId : _visaEntityId;

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

  static Future<Map<String, dynamic>> getPaymentWidgets({
    required String checkoutId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}v1/paymentWidgets.js?checkoutId=$checkoutId'),
        headers: {
          'Authorization': _authToken,
        },
      );

      if (response.statusCode == 200) {
        return {'script': response.body};
      } else {
        throw Exception('Failed to get payment widgets: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment widgets: $e');
    }
  }

  static Future<Map<String, dynamic>> getPciIframe({
    required String checkoutId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}v1/pciIframe.html?checkoutId=$checkoutId'),
        headers: {
          'Authorization': _authToken,
        },
      );

      if (response.statusCode == 200) {
        return {'html': response.body};
      } else {
        throw Exception('Failed to get PCI iframe: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting PCI iframe: $e');
    }
  }
}
