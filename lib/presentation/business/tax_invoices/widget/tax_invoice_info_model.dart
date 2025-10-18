import 'package:flutter/material.dart';

class TaxInvoiceInfoModel extends ChangeNotifier {
  String? downloadStatus;
  String? savedStatus;
  bool isLoading = false;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setDownloadStatus(String? status) {
    downloadStatus = status;
    notifyListeners();
  }

  void setSavedStatus(String? status) {
    savedStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    downloadStatus = null;
    savedStatus = null;
    isLoading = false;
    super.dispose();
  }
}
