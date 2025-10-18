import 'package:equatable/equatable.dart';
import 'subaccount_model.dart';

class SubaccountResponseModel extends Equatable {
  final bool status;
  final String message;
  final List<SubaccountModel> data;

  const SubaccountResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SubaccountResponseModel.fromJson(Map<String, dynamic> json) {
    return SubaccountResponseModel(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((item) => SubaccountModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [status, message, data];
}
