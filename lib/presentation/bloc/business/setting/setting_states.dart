import 'package:equatable/equatable.dart';
import 'package:spreadlee/domain/setting_model.dart';
import 'package:spreadlee/data/models/bank_details_model.dart';
import 'package:spreadlee/data/models/contact_info_model.dart';
import 'package:spreadlee/data/models/vat_certificate_model.dart';

abstract class SettingState extends Equatable {
  const SettingState();

  @override
  List<Object?> get props => [];
}

class SettingInitialState extends SettingState {}

class SettingLoadingState extends SettingState {}

class SettingSuccessState extends SettingState {
  final List<SettingData> settings;

  const SettingSuccessState(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingPhotoSuccessState extends SettingState {
  final SettingDataPhoto photo;

  const SettingPhotoSuccessState(this.photo);

  @override
  List<Object?> get props => [photo];
}

class SettingEmptyState extends SettingState {}

class SettingErrorState extends SettingState {
  final String error;

  const SettingErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

// Create Ticket States
class CreateSettingLoadingState extends SettingState {}

class CreateSettingSuccessState extends SettingState {
  final dynamic data;

  const CreateSettingSuccessState([this.data]);

  @override
  List<Object?> get props => [data];
}

class CreateSettingErrorState extends SettingState {
  final String error;

  const CreateSettingErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

// Bank Details States
class BankDetailsLoadingState extends SettingState {}

class BankDetailsSuccessState extends SettingState {
  final BankDetailsData bankDetails;

  const BankDetailsSuccessState(this.bankDetails);

  @override
  List<Object?> get props => [bankDetails];
}

class BankDetailsEmptyState extends SettingState {}

class BankDetailsErrorState extends SettingState {
  final String message;

  const BankDetailsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Contact Info States
class ContactInfoLoadingState extends SettingState {}

class ContactInfoSuccessState extends SettingState {
  final ContactInfoData data;

  const ContactInfoSuccessState(this.data);

  @override
  List<Object> get props => [data];
}

class ContactInfoEmptyState extends SettingState {}

class ContactInfoErrorState extends SettingState {
  final String error;

  const ContactInfoErrorState(this.error);

  @override
  List<Object> get props => [error];
}

// VAT Certificate States
class VatCertificateLoadingState extends SettingState {}

class VatCertificateSuccessState extends SettingState {
  final VatCertificateData data;

  const VatCertificateSuccessState(this.data);

  @override
  List<Object?> get props => [data];
}

class VatCertificateEmptyState extends SettingState {}

class VatCertificateErrorState extends SettingState {
  final String error;

  const VatCertificateErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
