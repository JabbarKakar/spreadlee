import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/presentation/bloc/customer/home_customer_bloc/home_customer_cubit.dart';
import '../../../bloc/customer/home_customer_bloc/home_customer_states.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';

@override
class CountrySelectionDialog {
  static void show(
      BuildContext context, Function(String) onCountrySelected) async {
    if (!context.mounted) return;
    final formKey = GlobalKey<FormState>();
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();

    String selectedCountry = '';

    // Use BlocConsumer to listen to and react to IncidentsCubit states
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocBuilder<HomeCubit, HomeStates>(
          builder: (context, state) {
            return AlertDialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
              content: Center(
                child: Container(
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
                        Text(AppStrings.selectYourCountry.tr()),
                        const SizedBox(height: 10),
                        CSCPickerPlus(
                          showCities: false,
                          showStates: false,
                          flagState: CountryFlag.DISABLE,
                          countryStateLanguage:
                              CountryStateLanguage.englishOrNative,
                          onCountryChanged: (country) {
                            selectedCountry =
                                country; // Update selected country
                            onCountrySelected(
                                country); // Pass selected country to callback
                          },
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 6.0),
                              child: FutureBuilder(
                                  future: Future.value(false),
                                  builder:
                                      (context, AsyncSnapshot<bool> snapshot) {
                                    if (snapshot.hasData) {
                                      return InkWell(
                                        onTap: () {
                                          if (snapshot.data.toString() ==
                                              "false") {
                                            if (formKey.currentState!
                                                .validate()) {
                                              // Just save the country and close dialog
                                              // The actual API call will be handled by the OTP view
                                              secureStorage.write(
                                                  key: "selectedCountry",
                                                  value: selectedCountry);

                                              if (kDebugMode) {
                                                print(
                                                    "Saved country: $selectedCountry"); // Debug log
                                              }

                                              // Close the dialog - the OTP view will handle the API calls
                                              Navigator.of(context).pop();
                                            }
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: AppStrings.vpnDetect.tr(),
                                                backgroundColor:
                                                    ColorManager.lightGrey);
                                          }
                                        },
                                        child: Container(
                                          width: 180,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: ColorManager.blueLight800,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                                color:
                                                    ColorManager.blueLight800,
                                                width: 1.0),
                                          ),
                                          alignment: Alignment.center,
                                          child: Center(
                                            child: Text(
                                              AppStrings.confirm.tr(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return CircularProgressIndicator(
                                        color: ColorManager.lightGreen,
                                        backgroundColor: ColorManager.white,
                                      );
                                    }
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
