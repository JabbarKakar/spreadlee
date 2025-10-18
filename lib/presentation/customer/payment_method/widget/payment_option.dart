import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_state.dart';
import 'package:spreadlee/presentation/customer/payment_method/widget/hyperpay_payment.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';

class PaymentOptionWidget extends StatefulWidget {
  final bool forPayment;

  const PaymentOptionWidget({
    Key? key,
    this.forPayment = true,
  }) : super(key: key);

  @override
  State<PaymentOptionWidget> createState() => _PaymentOptionWidgetState();
}

class _PaymentOptionWidgetState extends State<PaymentOptionWidget> {
  PaymentMethod? selectedOption;
  bool get isIOS => Platform.isIOS;

  void _handlePaymentMethodSelection(PaymentMethod method) {
    print('Payment method selected: ${method.name}');
    print('Entity ID: ${method.entityId}');
    print('Brands: ${method.brands}');

    setState(() => selectedOption = method);

    final cubit = context.read<PaymentCubit>();
    print('Preparing card registration...');
    final cardType = method.brands.first;
    print('Using card type: $cardType');
    cubit.prepareCardRegistration(
      cardType: cardType,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        print('Payment state changed: $state');
        if (state is CardRegistrationSuccess && selectedOption != null) {
          print(
              'CardRegistrationSuccess received with checkoutId: ${state.checkoutId}');
          print('Selected payment method: ${selectedOption!.name}');
          print('Selected entity ID: ${selectedOption!.entityId}');
          print('Selected brands: ${selectedOption!.brands}');

          // Store the context and cubit for later use
          final currentContext = context;
          final currentCubit = context.read<PaymentCubit>();

          // Navigate to payment webview
          try {
            print('Attempting to open payment UI...');
            print('Using checkout ID: ${state.checkoutId}');
            print('Using payment method: ${selectedOption!.name}');

            payRequestNowReadyUI(
              checkoutId: state.checkoutId,
              paymentMethod: selectedOption!,
              checkStatus: () async {
                if (!currentContext.mounted) {
                  print('Context is no longer mounted, skipping status check');
                  return;
                }
                print('Checking registration status...');
                final cardType = selectedOption!.brands.first;
                print('Using card type for status check: $cardType');
                try {
                  final status = await currentCubit.checkRegistrationStatus(
                    checkoutId: state.checkoutId,
                    cardType: cardType,
                  );
                  print('Registration status response: $status');
                  if (status != null && currentContext.mounted) {
                    print('Registration successful, preparing to save card...');
                    // Use the brand from the payment method
                    final cardType = selectedOption!.brands.first;
                    print('Using card type: $cardType');

                    try {
                      final savedCard = await currentCubit.saveCardMongo(
                        cardType: cardType,
                        bin_country: status['card']?['binCountry'] ?? '',
                        card_last4: status['card']?['last4Digits'] ?? '',
                        holder_name: status['card']?['holder'] ?? '',
                        expiry_month: status['card']?['expiryMonth'] ?? '',
                        expiry_year: status['card']?['expiryYear'] ?? '',
                        card_bin: status['card']?['bin'] ?? '',
                        registrationId: status['id'] ?? '',
                        context: currentContext,
                      );
                      print('Saved card response: $savedCard');

                      if (savedCard != null && savedCard['status'] == true) {
                        if (currentContext.mounted &&
                            Navigator.canPop(currentContext)) {
                          Navigator.pop(currentContext);
                        }
                      } else {
                        print('Failed to save card: ${savedCard?['message']}');
                        if (currentContext.mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            SnackBar(
                                content: Text(savedCard?['message'] ??
                                    'Failed to save card')),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error saving card: $e');
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                              content: Text('Error saving card details')),
                        );
                      }
                    }
                  } else {
                    print(
                        'Registration status check returned null or context not mounted');
                  }
                } catch (e) {
                  print('Error during status check: $e');
                  if (currentContext.mounted &&
                      Navigator.canPop(currentContext)) {
                    Navigator.pop(currentContext);
                  }
                }
              },
              registerCard: () async {
                if (!currentContext.mounted) {
                  print(
                      'Context is no longer mounted, skipping card registration');
                  return;
                }
                print('Starting card registration...');
                try {
                  await currentCubit.registerCard(
                    checkoutId: state.checkoutId,
                    entityId: selectedOption!.entityId,
                    context: currentContext,
                  );
                  print('Card registration completed successfully');
                } catch (e) {
                  print('Error during card registration: $e');
                  if (currentContext.mounted) {
                    Navigator.pop(currentContext);
                  }
                }
              },
            );
          } catch (e, stackTrace) {
            print('Error opening payment UI: $e');
            print('Stack trace: $stackTrace');
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        } else if (state is CardRegistrationError) {
          print('Card registration error: ${state.message}');
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Container(
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.selectPaymentMethod.tr(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: ColorManager.gray500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Options Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaymentOption(
                          PaymentMethod.VISA_MASTER_CARD,
                          'Master / Visa / Amex',
                        ),
                        const SizedBox(height: 22),
                        _buildPaymentOption(
                          PaymentMethod.MADA,
                          'Mada',
                        ),
                        if (widget.forPayment && isIOS) ...[
                          const SizedBox(height: 22),
                          _buildPaymentOption(
                            PaymentMethod.APPLE_PAY,
                            'Apple Pay',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Payment Icons Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildPaymentIcon(
                              'assets/images/Payment_method_master.png'),
                          const SizedBox(width: 4),
                          _buildPaymentIcon(
                              'assets/images/Payment_method_visa.png'),
                          const SizedBox(width: 4),
                          _buildPaymentIcon(
                              'assets/images/Payment_method_amex.png'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPaymentIcon(
                              'assets/images/Payment_method_mada.png'),
                        ],
                      ),
                      if (widget.forPayment && isIOS) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPaymentIcon('assets/images/Apple_Pay.png'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, String title) {
    return InkWell(
      onTap: () => _handlePaymentMethodSelection(method),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedOption == method
                    ? ColorManager.primary
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
                        color: ColorManager.primary,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        assetPath,
        width: 46,
        height: 32,
        fit: BoxFit.cover,
      ),
    );
  }
}
