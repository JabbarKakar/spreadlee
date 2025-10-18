import 'package:equatable/equatable.dart';
import 'package:spreadlee/data/models/card_model.dart';


abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentProcessing extends PaymentState {
  final String paymentId;
  final String amount;
  final CardModel card;

  const PaymentProcessing({
    required this.paymentId,
    required this.amount,
    required this.card,
  });

  @override
  List<Object?> get props => [paymentId, amount, card];
}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  final String amount;
  final DateTime timestamp;

  const PaymentSuccess({
    required this.transactionId,
    required this.amount,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [transactionId, amount, timestamp];
}

class CardRegistrationSuccess extends PaymentState {
  final String checkoutId;
  final String cardType;

  const CardRegistrationSuccess({
    required this.checkoutId,
    required this.cardType,
  });

  @override
  List<Object?> get props => [checkoutId, cardType];
}

class CardRegistrationError extends PaymentState {
  final String message;

  const CardRegistrationError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class CardRegistrationLoading extends PaymentState {
  const CardRegistrationLoading();
}

class PaymentError extends PaymentState {
  final String message;
  final String? errorCode;

  const PaymentError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class CardSavedSuccess extends PaymentState {
  final String message;

  const CardSavedSuccess({required this.message});
}

class CardSavedError extends PaymentState {
  final String message;

  const CardSavedError({required this.message});
}

class CardSavedLoading extends PaymentState {
  const CardSavedLoading();
}

class PaymentCancelled extends PaymentState {
  const PaymentCancelled();
}
