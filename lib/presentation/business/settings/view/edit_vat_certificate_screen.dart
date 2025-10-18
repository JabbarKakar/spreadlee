import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/widgets/loading_dialog.dart';
import 'package:cross_file/cross_file.dart';
import 'package:spreadlee/presentation/business/edit_details_pricing/view_file_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class EditVatCertificateScreen extends StatefulWidget {
  const EditVatCertificateScreen({Key? key}) : super(key: key);

  @override
  State<EditVatCertificateScreen> createState() =>
      _EditVatCertificateScreenState();
}

class _EditVatCertificateScreenState extends State<EditVatCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vatNumberController = TextEditingController();
  final _vatCertificateController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  File? _selectedFile;
  XFile? _vatCertificateFile;
  String? _currentVatNumber;
  String? _currentVatCertificate;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _hasVat = false;
  String? _localVatName;
  String? _uploadedFileUrl;
  bool _textfieldEmpty = false;
  bool _uploadedEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVatInfo();
    _isEditMode = false; // Start in view mode
  }

  @override
  void dispose() {
    _vatNumberController.dispose();
    _vatCertificateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentVatInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentVatNumber = await _secureStorage.read(key: 'vatNumber');
      _currentVatCertificate = await _secureStorage.read(key: 'vatCertificate');

      if (_currentVatNumber != null) {
        _vatNumberController.text = _currentVatNumber!;
        _hasVat = _currentVatCertificate != null &&
            _currentVatCertificate!.isNotEmpty;
      }

      await context.read<SettingCubit>().getVatCertificate();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _localVatName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error picking file'),
            backgroundColor: ColorManager.lightError,
          ),
        );
      }
    }
  }

  void _handleEditPress() {
    setState(() {
      _isEditMode = true; // Enter edit mode
    });
  }

  Future<void> _updateVatInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _textfieldEmpty = false;
      _uploadedEmpty = false;
    });

    final newVatNumber = _vatNumberController.text.trim();
    if (newVatNumber.isEmpty) {
      setState(() {
        _textfieldEmpty = true;
      });
      return;
    }

    if (_vatCertificateFile == null && !_hasVat) {
      setState(() {
        _uploadedEmpty = true;
      });
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingDialog(),
      );
    }

    try {
      if (_vatCertificateFile != null) {
        final file = await MultipartFile.fromFile(
          _vatCertificateFile!.path,
          filename: _vatCertificateFile!.path.split('/').last,
        );

        await context.read<SettingCubit>().updateVatCertificate(
              vatNumber: newVatNumber,
              vatCertificate: file,
            );
      } else {
        await context.read<SettingCubit>().updateVatNumber(
              vatNumber: newVatNumber,
            );
      }

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _vatCertificateFile = null;
          _vatCertificateController.clear();
        });
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _viewVatCertificate() async {
    if (_currentVatCertificate == null) return;

    try {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ViewFileScreen(
              pricingDetails: _currentVatCertificate,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error opening VAT Certificate'),
            backgroundColor: ColorManager.lightError,
          ),
        );
      }
    }
  }

  Future<void> _downloadVatCertificate() async {
    if (_currentVatCertificate == null) return;

    try {
      if (mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LoadingDialog(),
        );
      }

      // Extract filename from URL
      final uri = Uri.parse(_currentVatCertificate!);
      final pathSegments = uri.pathSegments;
      String fileName =
          pathSegments.isNotEmpty ? pathSegments.last : 'vat_certificate';

      // Remove any query parameters from filename
      fileName = fileName.split('?').first;

      // Ensure filename has .pdf extension
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }

      // Download the file using custom method
      final result = await _downloadVatFile(_currentVatCertificate!, fileName);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show result message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: result.contains('successfully')
                ? ColorManager.secondary
                : ColorManager.lightError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading VAT Certificate: ${e.toString()}'),
            backgroundColor: ColorManager.lightError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String> _downloadVatFile(String url, String fileName) async {
    if (url.isEmpty) {
      return 'Invalid URL';
    }

    Dio dio = Dio();

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return 'Storage permission denied';
          }
        }
      }

      // Fetch the file
      Response response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode != 200) {
        return 'Failed to download file: ${response.statusCode}';
      }

      // Get the download directory path
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        return 'Could not access download directory';
      }

      // Create the file path
      String filePath = '${downloadDir.path}/$fileName';

      // Write the file
      File file = File(filePath);
      await file.writeAsBytes(response.data, flush: true);

      // Verify the file was written
      if (await file.exists()) {
        // Open the file after download
        final result = await OpenFile.open(filePath);
        if (result.type == ResultType.done) {
          return 'Download successfully completed!';
        } else {
          return 'File downloaded but could not be opened: ${result.message}';
        }
      } else {
        return 'File download failed: File not found after download';
      }
    } catch (e) {
      print('Error downloading file: $e');
      return 'Error downloading file: ${e.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ColorManager.grey50,
        appBar: AppBar(
          backgroundColor: ColorManager.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: ColorManager.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Edit VAT Certificate & Number',
            style: getMediumStyle(
              color: ColorManager.black,
              fontSize: 16,
            ),
          ),
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAT number:',
                          style: getMediumStyle(
                            color: ColorManager.black,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _vatNumberController,
                          readOnly: !_isEditMode,
                          enabled: _isEditMode,
                          decoration: InputDecoration(
                            hintText: 'Enter VAT Number',
                            hintStyle: getRegularStyle(
                              color: ColorManager.grey,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: _isEditMode
                                ? ColorManager.gray100
                                : ColorManager.gray200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _textfieldEmpty
                                    ? ColorManager.error
                                    : ColorManager.grey50,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: ColorManager.primary,
                              ),
                            ),
                          ),
                          style: getRegularStyle(
                            color: ColorManager.black,
                            fontSize: 14,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 50,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'VAT number is required';
                            }
                            return null;
                          },
                        ),
                        if (_textfieldEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Please enter VAT Number.',
                              style: getRegularStyle(
                                color: ColorManager.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // VAT Certificate Section
                        Text(
                          'VAT Certificate:',
                          style: getMediumStyle(
                            color: ColorManager.black,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_isEditMode)
                          InkWell(
                            onTap: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );

                              if (result != null) {
                                setState(() {
                                  _vatCertificateFile =
                                      XFile(result.files.single.path!);
                                  _vatCertificateController.text =
                                      result.files.single.name;
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: ColorManager.gray200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _uploadedEmpty
                                      ? ColorManager.error
                                      : ColorManager.grey50,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: ColorManager.blueLight800,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _vatCertificateFile?.name ??
                                          _currentVatCertificate
                                              ?.split('/')
                                              .last ??
                                          'Upload VAT Certificate',
                                      style: getRegularStyle(
                                        color: _vatCertificateFile != null ||
                                                _currentVatCertificate != null
                                            ? ColorManager.black
                                            : ColorManager.grey,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: ColorManager.gray200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: ColorManager.blueLight800,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _currentVatCertificate
                                                ?.split('/')
                                                .last ??
                                            'No file uploaded',
                                        style: getRegularStyle(
                                          color: _currentVatCertificate != null
                                              ? ColorManager.black
                                              : ColorManager.grey,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_currentVatCertificate != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: Implement view functionality
                                          _viewVatCertificate();
                                        },
                                        icon: const Icon(Icons.visibility,
                                            color: Colors.white, size: 16),
                                        label: const Text('View'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ColorManager.blueLight800,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: Implement download functionality
                                          _downloadVatCertificate();
                                        },
                                        icon: const Icon(Icons.download,
                                            color: Colors.white, size: 16),
                                        label: const Text('Download'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ColorManager.blueLight800,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        if (_uploadedEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Please upload VAT Certificate.',
                              style: getRegularStyle(
                                color: ColorManager.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<SettingCubit, SettingState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is CreateSettingLoadingState
                          ? null
                          : _isEditMode
                              ? _updateVatInfo // When in edit mode, clicking saves changes
                              : _handleEditPress, // When in view mode, clicking enters edit mode
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        disabledBackgroundColor: ColorManager.buttonDisable,
                      ),
                      child: state is CreateSettingLoadingState
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEditMode
                                  ? 'Update'
                                  : 'Edit', // Show Update when editing, Edit when viewing
                              style: getMediumStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
