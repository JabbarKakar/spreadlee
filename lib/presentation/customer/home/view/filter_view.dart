import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/outside_api_call.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/widget/cities_list.dart';
import '../../../bloc/customer/home_customer_bloc/home_customer_cubit.dart';
import '../../../bloc/customer/home_customer_bloc/home_customer_states.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';
import '../../../widget/country_dropdown_list.dart';

class HomeFilter extends StatefulWidget {
  const HomeFilter({super.key});

  @override
  _HomeFilterState createState() => _HomeFilterState();
}

class _HomeFilterState extends State<HomeFilter> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  String? selectedCountryIso;
  String? selectedRole;
  List<String> selectedCities = [];
  bool _isNavigatingBack = false;

  @override
  void initState() {
    context.read<HomeCubit>().fToast.init(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    var cubit = HomeCubit.get(context);
    return Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: ColorManager.white,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.black,
                size: 24.0,
              ),
              onPressed: () {
                setState(() {
                  _isNavigatingBack = true;
                });
                Navigator.pushReplacementNamed(
                    context, Routes.customerHomeRoute);
              },
            ),
          ),
          title: const Text("Filter"),
        ),
        body: BlocConsumer<HomeCubit, HomeStates>(listener: (context, state) {
          if (state is HomeSuccessState && !_isNavigatingBack) {
            if (cubit.customerHomeModel?.message ==
                "Users retrieved successfully") {
              Navigator.pushReplacementNamed(
                  context, Routes.customerFilterResultRoute);
              context.read<HomeCubit>().fToast.init(context);
            } else if (cubit.customerHomeModel?.message == "Role is required") {
              cubit.showCustomToast(
                message: AppStrings.roleRequired.tr(),
                color: ColorManager.lightError,
              );
            } else if (cubit.customerHomeModel?.message ==
                "No users found matching the criteria.") {
              cubit.showCustomToast(
                message: AppStrings.noUsersFoundMatching.tr(),
                color: ColorManager.lightError,
              );
            }
          }
          if (state is HomeErrorState) {
            cubit.showCustomToast(
                message: AppStrings.error.tr(),
                color: ColorManager.lightError,
                messageColor: ColorManager.white);
          }
        }, builder: (context, state) {
          return SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            AppStrings.applyingFilter.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            AppStrings.country.tr(),
                            style: const TextStyle(
                                fontSize: 12.0, fontWeight: FontWeight.w500),
                          ),
                        ),
                        CountryDropdown(
                          onCountrySelected: (iso) {
                            setState(() {
                              selectedCountryIso = iso;
                            });
                          },
                        ),
                        if (selectedCountryIso != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 12.0, bottom: 6.0),
                                child: Text(
                                  AppStrings.cities.tr(),
                                  style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              MultiSelectCityDropdown(
                                key: ValueKey(
                                    selectedCountryIso), // 🔹 Force widget rebuild
                                countryIso: selectedCountryIso!,
                                onCitiesSelected: (cities) {
                                  setState(() {
                                    selectedCities = cities;
                                    print("Selected Cities: $selectedCities");
                                  });
                                },
                              ),
                            ],
                          ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Radio<String>(
                                  value: "influencer",
                                  groupValue: selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value;
                                    });
                                  },
                                  activeColor: ColorManager.blueLight800,
                                ),
                                Text(AppStrings.individual.tr()),
                                const SizedBox(width: 20),
                                Radio<String>(
                                  value: "company",
                                  groupValue: selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value;
                                    });
                                  },
                                  activeColor: ColorManager.blueLight800,
                                ),
                                Text(AppStrings.company.tr()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selectedRole != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 16.0),
                        child: FutureBuilder(
                            future: Future.value(false),
                            builder: (context, AsyncSnapshot<bool> snapshot) {
                              if (snapshot.hasData) {
                                return InkWell(
                                  onTap: () {
                                    if (snapshot.data.toString() == "false") {
                                      if (_formKey.currentState!.validate()) {
                                        cubit
                                            .filterCustomerHomeData(
                                                country_code:
                                                    selectedCountryIso,
                                                cities: selectedCities ?? [],
                                                role: selectedRole)
                                            .then((_) {
                                          if (cubit
                                                  .customerHomeModel?.message ==
                                              "Users retrieved successfully") {
                                            Navigator.pushReplacementNamed(
                                                context,
                                                Routes
                                                    .customerFilterResultRoute);
                                          }
                                        });
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                          msg: AppStrings.vpnDetect.tr(),
                                          backgroundColor:
                                              ColorManager.lightGrey);
                                    }
                                  },
                                  child: state is HomeLoadingState
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            backgroundColor:
                                                ColorManager.blueLight800,
                                            color: ColorManager.white,
                                          ),
                                        )
                                      : Container(
                                          width: 300,
                                          height: 50,
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
                                              AppStrings.apply.tr(),
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
          ));
        }));
  }
}
