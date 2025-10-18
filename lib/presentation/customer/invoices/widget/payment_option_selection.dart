import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/customer/payment_method/widget/hyperpay_payment.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/data/models/card_model.dart';

class PaymentOptionSelection extends StatefulWidget {
  final List<CardModel> cards;
  final Function(PaymentMethod) onPaymentMethodSelected;

  const PaymentOptionSelection({
    Key? key,
    required this.cards,
    required this.onPaymentMethodSelected,
  }) : super(key: key);

  @override
  State<PaymentOptionSelection> createState() => _PaymentOptionSelectionState();
}

class _PaymentOptionSelectionState extends State<PaymentOptionSelection> {
  PaymentMethod? selectedOption;
  bool get isIOS => Platform.isIOS;

  void _handlePaymentMethodSelection(PaymentMethod method) {
    setState(() => selectedOption = method);
    widget.onPaymentMethodSelected(method);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: ColorManager.gray500,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: ColorManager.gray500),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Options
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentOption(
                  PaymentMethod.VISA_MASTER_CARD,
                  'Master / Visa / Amex',
                  'assets/images/Payment_method_master.png',
                  'assets/images/Payment_method_visa.png',
                  'assets/images/Payment_method_amex.png',
                ),
                const SizedBox(height: 16),
                _buildPaymentOption(
                  PaymentMethod.MADA,
                  'Mada',
                  'assets/images/Payment_method_mada.png',
                ),
                if (isIOS) ...[
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    PaymentMethod.APPLE_PAY,
                    'Apple Pay',
                    'assets/images/Apple_Pay.png',
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // // Saved Cards Section (if any)
            // if (widget.cards.isNotEmpty) ...[
            //   const Divider(),
            //   const SizedBox(height: 16),
            //   const Text(
            //     'Saved Cards',
            //     style: TextStyle(
            //       fontFamily: 'Poppins',
            //       color: ColorManager.gray500,
            //       fontSize: 14,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            //   const SizedBox(height: 12),
            //   ...widget.cards.map((card) => _buildSavedCardOption(card)),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    String primaryIcon, [
    String? secondaryIcon,
    String? tertiaryIcon,
  ]) {
    return InkWell(
      onTap: () => _handlePaymentMethodSelection(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedOption == method
                ? ColorManager.blueLight800
                : ColorManager.gray300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedOption == method
                      ? ColorManager.blueLight800
                      : ColorManager.gray300,
                  width: 2,
                ),
              ),
              child: selectedOption == method
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorManager.blueLight800,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: ColorManager.gray500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Image.asset(
                  primaryIcon,
                  width: 32,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                if (secondaryIcon != null) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    secondaryIcon,
                    width: 32,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ],
                if (tertiaryIcon != null) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    tertiaryIcon,
                    width: 32,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardOption(CardModel card) {
    final cardBrand = card.cardType.toUpperCase();
    PaymentMethod? cardPaymentMethod;

    // Determine payment method based on card brand
    if (['VISA', 'MASTER', 'AMEX'].contains(cardBrand)) {
      cardPaymentMethod = PaymentMethod.VISA_MASTER_CARD;
    } else if (cardBrand == 'MADA') {
      cardPaymentMethod = PaymentMethod.MADA;
    }

    if (cardPaymentMethod == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _handlePaymentMethodSelection(cardPaymentMethod!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedOption == cardPaymentMethod
                ? ColorManager.blueLight800
                : ColorManager.gray300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedOption == cardPaymentMethod
                      ? ColorManager.blueLight800
                      : ColorManager.gray300,
                  width: 1,
                ),
              ),
              child: selectedOption == cardPaymentMethod
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorManager.blueLight800,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.holderName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: ColorManager.gray500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '**** ${card.cardLast4} • ${card.expiryMonth}/${card.expiryYear}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: ColorManager.gray400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              cardBrand,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: ColorManager.gray400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
