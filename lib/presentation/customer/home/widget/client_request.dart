import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/presentation/customer/home/widget/company_list_dropdown.dart';
import 'package:spreadlee/presentation/customer/home/widget/add_company_dialog.dart';
import '../../../bloc/customer/client_request_bloc/client_request_cubit.dart';
import '../../../bloc/customer/client_request_bloc/client_request_states.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_cubit.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';

class ClientRequestDialog {
  static void show(BuildContext context, Function(String) onCompanySelected,
      {String? customerId}) async {
    if (!context.mounted) return;
    final formKey = GlobalKey<FormState>();
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();

    String selectedCompany = '';
    CustomerCompanyCubit.get(context).getCustomerCompanyData();

    // Use a stateful builder to manage local state for empty company list
    bool isCompanyListEmpty = false;

    // Use BlocConsumer to listen to and react to IncidentsCubit states
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          var cubit = ClientRequestCubit.get(context);
          return StatefulBuilder(
            builder: (context, setState) {
              return BlocConsumer<ClientRequestCubit, ClientRequestStates>(
                listener: (context, state) {
                  if (state is ClientRequestSuccessState) {
                    if (cubit.clientRequestModel?.message ==
                        "Client request created successfully") {
                      showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return Dialog(
                              elevation: 0,
                              insetPadding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                              alignment: const AlignmentDirectional(0.0, 0.0)
                                  .resolve(Directionality.of(context)),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Message",
                                      style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    const SizedBox(height: 12.0),
                                    const Text(
                                      "Chat request has been successfully sent.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16.0, color: Colors.black),
                                    ),
                                    const SizedBox(height: 20.0),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                      child: const Text(
                                        "OK",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                    } else if (cubit.clientRequestModel?.message ==
                        "Missing required fields") {
                      cubit.showCustomToast(
                        message: AppStrings.Unauthorized.tr(),
                        color: ColorManager.lightError,
                      );
                    } else if (cubit.clientRequestModel?.message ==
                        "A request for this client and company already exists") {
                      showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return Dialog(
                              elevation: 0,
                              insetPadding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              alignment: const AlignmentDirectional(0.0, 0.0)
                                  .resolve(Directionality.of(context)),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Notice",
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    const Text(
                                      "A request for this client and company already exists",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    const SizedBox(height: 20.0),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                      child: const Text(
                                        "OK",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                    }
                  }
                  if (state is ClientRequestErrorState) {
                    cubit.showCustomToast(
                        message: AppStrings.error.tr(),
                        color: ColorManager.lightError,
                        messageColor: ColorManager.white);
                  }
                },
                builder: (context, state) {
                  return AlertDialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding:
                        const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                    content: Container(
                      width: MediaQuery.of(context).size.width * 1.0,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.transparent,
                                  size: 24.0,
                                ),
                                const SizedBox(
                                  width: 55,
                                ),
                                Expanded(
                                    child: Text(
                                        AppStrings.gorwhichcompanyyou.tr())),
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 18.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (isCompanyListEmpty) ...[
                              const SizedBox(height: 40),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final bool result =
                                        await AddCompanyDialog.show(context);
                                    if (result) {
                                      CustomerCompanyCubit.get(context)
                                          .getCustomerCompanyData();
                                      // Reset the empty state when a company is successfully added
                                      setState(() {
                                        isCompanyListEmpty = false;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    size: 20.0,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    AppStrings.addnew.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(
                                        MediaQuery.of(context).size.width * 0.4,
                                        40),
                                    backgroundColor: ColorManager.blueLight800,
                                    elevation: 0.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ] else ...[
                              Align(
                                alignment: const AlignmentDirectional(1.0, 0.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final bool result =
                                        await AddCompanyDialog.show(context);
                                    if (result) {
                                      CustomerCompanyCubit.get(context)
                                          .getCustomerCompanyData();
                                      // Reset the empty state when a company is successfully added
                                      setState(() {
                                        isCompanyListEmpty = false;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    size: 20.0,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    AppStrings.addnew.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(
                                        MediaQuery.of(context).size.width * 0.3,
                                        32),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: ColorManager.blueLight800,
                                    elevation: 0.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              DynamicDropdown(
                                onChanged: (value) {
                                  selectedCompany = value;
                                },
                                onEmpty: () {
                                  setState(() {
                                    isCompanyListEmpty = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 30),
                            ],
                            if (!isCompanyListEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 6.0),
                                    child: FutureBuilder(
                                        future: Future.value(false),
                                        builder: (context,
                                            AsyncSnapshot<bool> snapshot) {
                                          if (snapshot.hasData) {
                                            return InkWell(
                                              onTap: () {
                                                if (snapshot.data.toString() ==
                                                    "false") {
                                                  if (formKey.currentState!
                                                      .validate()) {
                                                    cubit.clientRequest(
                                                        customer_companyId:
                                                            selectedCompany,
                                                        client: customerId!);
                                                    secureStorage.write(
                                                        key: "selectedCountry",
                                                        value: selectedCompany);

                                                    if (kDebugMode) {
                                                      print(
                                                          "Saved country: $selectedCompany"); // Debug log
                                                    }
                                                  }
                                                } else {
                                                  Fluttertoast.showToast(
                                                      msg: AppStrings.vpnDetect
                                                          .tr(),
                                                      backgroundColor:
                                                          ColorManager
                                                              .lightGrey);
                                                }
                                              },
                                              child: state
                                                      is ClientRequestLoadingState
                                                  ? Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        backgroundColor:
                                                            ColorManager
                                                                .blueLight800,
                                                        color:
                                                            ColorManager.white,
                                                      ),
                                                    )
                                                  : Container(
                                                      width: 230,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: ColorManager
                                                            .blueLight800,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        border: Border.all(
                                                            color: ColorManager
                                                                .blueLight800,
                                                            width: 1.0),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Center(
                                                        child: Text(
                                                          AppStrings.confirms
                                                              .tr(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                            fontFamily:
                                                                'Poppins',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                            );
                                          } else {
                                            return CircularProgressIndicator(
                                              color: ColorManager.lightGreen,
                                              backgroundColor:
                                                  ColorManager.white,
                                            );
                                          }
                                        }),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 30),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }, // end BlocConsumer builder
              ); // end BlocConsumer
            }, // end StatefulBuilder builder
          ); // end StatefulBuilder
        });
  }
}
