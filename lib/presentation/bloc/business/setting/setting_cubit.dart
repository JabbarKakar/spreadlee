import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';
import 'package:spreadlee/data/models/bank_details_model.dart';
import 'package:spreadlee/data/models/contact_info_model.dart';
import 'package:spreadlee/data/models/vat_certificate_model.dart';
import 'package:spreadlee/data/models/price_tag_model.dart';

import '../../../../domain/setting_model.dart';

class SettingCubit extends Cubit<SettingState> {
  SettingCubit() : super(SettingInitialState());

  static SettingCubit get(context) => BlocProvider.of(context);
  FToast? fToast;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  void initFToast(BuildContext context) {
    if (fToast == null) {
      fToast = FToast();
      fToast?.init(context);
    }
  }

  showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.black,
  }) {
    if (fToast == null) {
      if (kDebugMode) {
        print("Toast not initialized. Message was: $message");
      }
      return;
    }

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s10),
        color: color,
      ),
      child: Text(
        message,
        style: getBoldStyle(color: messageColor),
      ),
    );

    fToast?.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  void showNoInternetMessage() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorManager.lightGrey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi),
          const SizedBox(width: 12.0),
          Text(
            AppStrings.noInternetConnection.tr(),
            style: TextStyle(
              color: ColorManager.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    fToast?.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 4),
    );
  }

  Future<void> getPricingDetails() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(SettingLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getPricingDetails,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final settingResponse = SettingResponse.fromJson(response!.data);
          final settingData = SettingData.fromJson(settingResponse.data);

          if (settingData.pricingDetails.isEmpty) {
            emit(SettingEmptyState());
            showCustomToast(
              message: "No setting found",
              color: ColorManager.lightGrey,
            );
          } else {
            emit(SettingSuccessState([settingData]));
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Tickets API Error Details: $error");
        }
        emit(SettingErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> editPricingDetails({
    required MultipartFile pricingDetails,
    ProgressCallback? onSendProgress,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        final response = await DioHelper.updateDataWithFiles(
          endPoint: Constants.editPricingDetails,
          data: FormData.fromMap({
            'pricingDetails': pricingDetails,
          }),
          onSendProgress: onSendProgress,
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          final setting = SettingData.fromJson(response!.data['data']);
          emit(CreateSettingSuccessState(setting));
          showCustomToast(
            message: "Setting updated successfully",
            color: ColorManager.lightGrey,
          );
          await getPricingDetails();
        } else {
          throw Exception("Failed to update setting");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Create Setting API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> getPhoto() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(SettingLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getUserPhoto,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final settingResponse = SettingResponse.fromJson(response!.data);
          final settingDataPhoto =
              SettingDataPhoto.fromJson(settingResponse.data);

          if (settingDataPhoto.photoUrl.isEmpty) {
            emit(SettingEmptyState());
            showCustomToast(
              message: "No setting found",
              color: ColorManager.lightGrey,
            );
          } else {
            emit(SettingPhotoSuccessState(settingDataPhoto));
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Tickets API Error Details: $error");
        }
        emit(SettingErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> editPhoto({
    required MultipartFile photoUrl,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        final response = await DioHelper.updateDataWithFiles(
          endPoint: Constants.changePhoto,
          data: FormData.fromMap({
            'photoUrl': photoUrl,
          }),
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Edit Photo Response: ${response?.data}");
          }

          final settingResponse = SettingResponse.fromJson(response!.data);
          final settingDataPhoto =
              SettingDataPhoto.fromJson(settingResponse.data);

          emit(
              const CreateSettingSuccessState(SettingData(pricingDetails: "")));
          showCustomToast(
            message: "Photo updated successfully",
            color: ColorManager.lightGrey,
          );

          await _secureStorage.write(
              key: 'photoUrl', value: settingDataPhoto.photoUrl);
          Constants.photoUrl = settingDataPhoto.photoUrl;

          if (kDebugMode) {
            print("Updated photo URL: ${Constants.photoUrl}");
          }

          await getPhoto();
        } else {
          throw Exception("Failed to update photo");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Create Setting API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> deletePhoto() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        final response = await DioHelper.delete(
          endPoint: Constants.deletePhoto,
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          emit(SettingEmptyState());
          showCustomToast(
            message: "Photo deleted successfully",
            color: ColorManager.lightGrey,
          );
          await _secureStorage.delete(key: 'photoUrl');
          Constants.photoUrl = "";
          await getPhoto();
        } else {
          throw Exception("Failed to delete photo");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Delete Photo API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> getVatCertificate() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(VatCertificateLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getVatDetails,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          try {
            final vatResponse = VatCertificateResponse.fromJson(response!.data);

            if (vatResponse.status) {
              // Show current VAT details to user
              if (fToast != null) {
                showCustomToast(
                  message:
                      "Current VAT Details:\nVAT Number: ${vatResponse.data.vatNumber}\nCertificate: ${vatResponse.data.vatCertificate.split('/').last}",
                  color: ColorManager.lightGrey,
                  messageColor: ColorManager.black,
                );
              }

              emit(VatCertificateSuccessState(vatResponse.data));
              // Store the values in secure storage
              await _secureStorage.write(
                  key: 'vatNumber', value: vatResponse.data.vatNumber);
              await _secureStorage.write(
                  key: 'vatCertificate',
                  value: vatResponse.data.vatCertificate);
            } else {
              emit(VatCertificateEmptyState());
              if (fToast != null) {
                showCustomToast(
                  message: vatResponse.message,
                  color: ColorManager.lightGrey,
                );
              }
            }
          } catch (parseError) {
            if (kDebugMode) {
              print("Error parsing VAT response: $parseError");
            }
            emit(const VatCertificateErrorState("Error parsing VAT data"));
            if (fToast != null) {
              showCustomToast(
                message: "Error parsing VAT data",
                color: ColorManager.lightError,
                messageColor: ColorManager.white,
              );
            }
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("VAT Certificate API Error Details: $error");
        }
        emit(VatCertificateErrorState(error.toString()));
        if (fToast != null) {
          showCustomToast(
            message: AppStrings.error.tr(),
            color: ColorManager.lightError,
            messageColor: ColorManager.white,
          );
        }
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> updateVatCertificate({
    required String vatNumber,
    required MultipartFile vatCertificate,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        // Debug print to check values being sent
        if (kDebugMode) {
          print('Sending to API - VAT Number: $vatNumber');
          print('Sending to API - VAT Certificate: ${vatCertificate.filename}');
        }

        final response = await DioHelper.updateDataWithFiles(
          endPoint: Constants.updateVatDetails,
          data: FormData.fromMap({
            'vATNumber': vatNumber,
            'vATCertificate': vatCertificate,
          }),
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Update VAT Certificate Response: ${response?.data}");
          }

          final responseData = response!.data;
          if (responseData['status'] == true) {
            // Update stored values
            await _secureStorage.write(key: 'vatNumber', value: vatNumber);
            await _secureStorage.write(
                key: 'vatCertificate',
                value: responseData['data']['vATCertificate']);

            emit(const CreateSettingSuccessState(
                SettingData(pricingDetails: "")));
            showCustomToast(
              message: responseData['message'] ??
                  "VAT certificate updated successfully",
              color: ColorManager.lightGrey,
            );
            // Refresh VAT certificate data
            await getVatCertificate();
            return;
          }
          throw Exception(
              responseData['message'] ?? "Failed to update VAT certificate");
        }
        throw Exception("Failed to update VAT certificate");
      } catch (error) {
        if (kDebugMode) {
          print("Update VAT Certificate API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> getBankDetails() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(BankDetailsLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getBankDetails,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final bankDetailsResponse =
              BankDetailsResponse.fromJson(response!.data);

          if (bankDetailsResponse.status) {
            emit(BankDetailsSuccessState(bankDetailsResponse.data));
          } else {
            emit(BankDetailsEmptyState());
            showCustomToast(
              message: bankDetailsResponse.message,
              color: ColorManager.lightGrey,
            );
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("bank details API Error Details: $error");
        }
        emit(BankDetailsErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> updateBankDetails({
    required String bank_account_number,
    required String iban_string,
    required String branch_code_string,
    required String branch_name,
    required String country,
    required String holder_name,
    required String bank_name,
    required String swift_code_string,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        final response = await DioHelper.updateData(
            endPoint: Constants.updateBankDetalis,
            data: {
              "bank_account_number": bank_account_number,
              "iban_string": iban_string,
              "branch_code_string": branch_code_string,
              "branch_name": branch_name,
              "country": country,
              "holder_name": holder_name,
              "bank_name": bank_name,
              "swift_code_string": swift_code_string
            });

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Edit bank details Response: ${response?.data}");
          }

          final settingResponse = SettingResponse.fromJson(response!.data);
          final settingDataPhoto =
              SettingDataPhoto.fromJson(settingResponse.data);

          emit(
              const CreateSettingSuccessState(SettingData(pricingDetails: "")));
          showCustomToast(
            message: "bank details updated successfully",
            color: ColorManager.lightGrey,
          );

          await getPhoto();
        } else {
          throw Exception("Failed to update bank details");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Create Setting API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        final response = await DioHelper.updateData(
            endPoint: Constants.changePassword,
            data: {
              "oldPassword": oldPassword,
              "newPassword": newPassword,
            });

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Change Password Response: ${response?.data}");
          }

          final responseData = response!.data;
          if (responseData['status'] == true) {
            // Create a dummy SettingData since we don't need actual data for password change
            emit(const CreateSettingSuccessState(
                SettingData(pricingDetails: "")));
            showCustomToast(
              message:
                  responseData['message'] ?? "Password changed successfully",
              color: ColorManager.success,
            );
            return;
          }
          throw Exception(
              responseData['message'] ?? "Failed to change password");
        }
        throw Exception("Failed to change password");
      } catch (error) {
        if (kDebugMode) {
          print("Change Password API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.alertError500,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> changeContactInfo({
    required String newEmail,
    required String newPhoneNumber,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        // Debug print to check values being sent
        if (kDebugMode) {
          print('Sending to API - Email: $newEmail');
          print('Sending to API - Phone: $newPhoneNumber');
        }

        final response = await DioHelper.updateData(
          endPoint: Constants.changeContactDetails,
          data: {
            "newEmail": newEmail,
            "newPhoneNumber": newPhoneNumber,
          },
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Change Contact Info Response: ${response?.data}");
          }

          final responseData = response!.data;
          if (responseData['status'] == true) {
            // Update stored values
            await _secureStorage.write(key: 'email', value: newEmail);
            await _secureStorage.write(
                key: 'phoneNumber', value: newPhoneNumber);

            emit(const CreateSettingSuccessState(
                SettingData(pricingDetails: "")));
            showCustomToast(
              message: responseData['message'] ??
                  "Contact information updated successfully",
              color: ColorManager.success,
            );
            return;
          }
          throw Exception(responseData['message'] ??
              "Failed to update contact information");
        }
        throw Exception("Failed to update contact information");
      } catch (error) {
        if (kDebugMode) {
          print("Change Contact Info API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.alertError500,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> getContactInfo() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ContactInfoLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getContactDetails,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final contactInfoResponse =
              ContactInfoResponse.fromJson(response!.data);

          if (contactInfoResponse.status) {
            emit(ContactInfoSuccessState(contactInfoResponse.data));
            // Store the values in secure storage
            await _secureStorage.write(
                key: 'email', value: contactInfoResponse.data.email);
            await _secureStorage.write(
                key: 'phoneNumber',
                value: contactInfoResponse.data.phoneNumber);
          } else {
            emit(ContactInfoEmptyState());
            showCustomToast(
              message: contactInfoResponse.message,
              color: ColorManager.lightGrey,
            );
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Contact info API Error Details: $error");
        }
        emit(ContactInfoErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> updateVatNumber({required String vatNumber}) async {
    try {
      emit(CreateSettingLoadingState());

      // Update VAT number in secure storage
      await _secureStorage.write(key: 'vatNumber', value: vatNumber);

      // Update VAT number in API
      final response = await DioHelper.updateData(
        endPoint: Constants.updateVatNumber,
        data: {'vatNumber': vatNumber},
      );

      if (response?.statusCode == 200) {
        emit(const CreateSettingSuccessState());
      } else {
        emit(const CreateSettingErrorState('Failed to update VAT number'));
      }
    } catch (e) {
      emit(CreateSettingErrorState(e.toString()));
    }
  }

  Future<void> editServices({
    required List marketing_fields,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        // Debug print to check values being sent
        if (kDebugMode) {
          print('Sending to API - marketing_fields: $marketing_fields');
        }

        final response = await DioHelper.updateData(
          endPoint: Constants.updateMarkting,
          data: {
            "marketing_fields": marketing_fields,
          },
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Change Contact Info Response: ${response?.data}");
          }

          final responseData = response!.data;
          if (responseData['status'] == true) {
            // Update stored values

            emit(const CreateSettingSuccessState(
                SettingData(pricingDetails: "")));
            showCustomToast(
              message: responseData['message'] ??
                  "Marketing fields updated successfully",
              color: ColorManager.lightGrey,
            );
            return;
          }
          throw Exception(responseData['message'] ??
              "Failed to update contact information");
        }
        throw Exception("Failed to update contact information");
      } catch (error) {
        if (kDebugMode) {
          print("Change Contact Info API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> editPriceTag({
    required String price_tag,
  }) async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(CreateSettingLoadingState());

      try {
        // Debug print to check values being sent
        if (kDebugMode) {
          print('Sending to API - price_tag: $price_tag');
        }

        final response = await DioHelper.updateData(
          endPoint: Constants.updateTagPrice,
          data: {
            "price_tag": price_tag,
          },
        );

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          if (kDebugMode) {
            print("Change Contact Info Response: ${response?.data}");
          }

          final responseData = response!.data;
          if (responseData['status'] == true) {
            // Update stored values

            emit(const CreateSettingSuccessState(
                SettingData(pricingDetails: "")));
            showCustomToast(
              message:
                  responseData['message'] ?? "Price tag updated successfully",
              color: ColorManager.lightGrey,
            );
            return;
          }
          throw Exception(
              responseData['message'] ?? "price_tag must be a string");
        }
        throw Exception("Failed to update Price tag");
      } catch (error) {
        if (kDebugMode) {
          print("Change Price tag API Error: $error");
        }
        emit(CreateSettingErrorState(error.toString()));
        showCustomToast(
          message: error.toString(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }

  Future<void> getPriceTag() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      emit(ContactInfoLoadingState());

      try {
        final response = await DioHelper.getData(
          endPoint: Constants.getTagPrice,
        );

        if (kDebugMode) {
          print("Raw Response: ${response?.data}");
        }

        if (response?.data != null) {
          final priceTagResponse = PriceTagResponse.fromJson(response!.data);

          if (priceTagResponse.status) {
            emit(ContactInfoSuccessState(ContactInfoData(
              email: '',
              phoneNumber: '',
              priceTag: priceTagResponse.data.priceTag,
            )));
          } else {
            emit(ContactInfoEmptyState());
            showCustomToast(
              message: priceTagResponse.message,
              color: ColorManager.lightGrey,
            );
          }
        } else {
          throw Exception("No data received from server");
        }
      } catch (error) {
        if (kDebugMode) {
          print("Price tag API Error Details: $error");
        }
        emit(ContactInfoErrorState(error.toString()));
        showCustomToast(
          message: AppStrings.error.tr(),
          color: ColorManager.lightError,
          messageColor: ColorManager.white,
        );
      }
    } else {
      showNoInternetMessage();
    }
  }
}
