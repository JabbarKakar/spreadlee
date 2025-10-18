class CardModel {
  final String cardId;
  final String binCountry;
  final String cardType;
  final String cardLast4;
  final String holderName;
  final String expiryMonth;
  final String expiryYear;
  final String cardBin;
  final String registrationId;

  CardModel({
    required this.cardId,
    required this.binCountry,
    required this.cardType,
    required this.cardLast4,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardBin,
    required this.registrationId,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardId: json['_id'] ?? '',
      binCountry: json['bin_country'] ?? '',
      cardType: json['cardType'] ?? '',
      cardLast4: json['card_last4'] ?? '',
      holderName: json['holder_name'] ?? '',
      expiryMonth: json['expiry_month'] ?? '',
      expiryYear: json['expiry_year'] ?? '',
      cardBin: json['card_bin'] ?? '',
      registrationId: json['registrationId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': cardId,
      'bin_country': binCountry,
      'cardType': cardType,
      'card_last4': cardLast4,
      'holder_name': holderName,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'card_bin': cardBin,
      'registrationId': registrationId,
    };
  }
}
