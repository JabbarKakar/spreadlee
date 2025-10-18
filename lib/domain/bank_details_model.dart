import 'package:flutter/material.dart';

class BankDetailsModel extends ChangeNotifier {
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController holderNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ibanController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchCodeController = TextEditingController();
  final TextEditingController swiftCodeController = TextEditingController();

  String selectedCountry = '';
  bool isEditMode = true;
  bool isUpdating = false;
  String? errorMessage;

  void setCountry(String country) {
    selectedCountry = country;
    notifyListeners();
  }

  void toggleEditMode() {
    isEditMode = !isEditMode;
    notifyListeners();
  }

  void setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void startUpdate() {
    isUpdating = true;
    notifyListeners();
  }

  void finishUpdate() {
    isUpdating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    bankNameController.dispose();
    holderNameController.dispose();
    accountNumberController.dispose();
    ibanController.dispose();
    branchNameController.dispose();
    branchCodeController.dispose();
    swiftCodeController.dispose();
    super.dispose();
  }
}
