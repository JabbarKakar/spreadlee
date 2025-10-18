import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_cubit.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_states.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';

class CustomerCompany extends StatefulWidget {
  const CustomerCompany({super.key});

  @override
  State<CustomerCompany> createState() => _CustomerCompanyState();
}

class _CustomerCompanyState extends State<CustomerCompany> {
  @override
  void initState() {
    context.read<CustomerCompanyCubit>().getCustomerCompanyData();
    context.read<CustomerCompanyCubit>().fToast.init(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var cubit = CustomerCompanyCubit.get(context);
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
                Navigator.pushReplacementNamed(
                    context, Routes.customerHomeRoute);
                // Navigator.pop(context);
              },
            ),
          ),
          title: const Text(
            AppStrings.addCompany,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        body: BlocConsumer<CustomerCompanyCubit, CustomerCompanyStates>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state is CustomerCompanyLoadingState) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CustomerCompanyErrorState) {
                return const Center(
                    child: Text("Error: No Connection Whit The Server"));
              } else if (state is CustomerCompanySuccessState) {
                final companies = state.customerCompanyModel.data ?? [];
                return SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 25,
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: companies.length,
                          itemBuilder: (context, index) {
                            return Material(
                                color: Colors.transparent,
                                elevation: 0.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Container(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color:
                                              ColorManager.customYellowF1D261,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Column(
                                          children: [
                                            ListTile(
                                              title: Text(
                                                companies[index]
                                                        .commercialName ??
                                                    "No Name",
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Text(
                                                companies[index].countryName ??
                                                    "No Country",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black),
                                              ),
                                              trailing: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pushNamed(context,
                                                      Routes.editCompanyRoute,
                                                      arguments: {
                                                        'companyId':
                                                            companies[index]
                                                                .sId,
                                                        'companyData': {
                                                          'countryName':
                                                              companies[index]
                                                                  .countryName,
                                                          'companyName':
                                                              companies[index]
                                                                  .companyName,
                                                          'commercialName':
                                                              companies[index]
                                                                  .commercialName,
                                                          'commercialNumber':
                                                              companies[index]
                                                                  .commercialNumber,
                                                          'vATNumber':
                                                              companies[index]
                                                                  .vATNumber,
                                                          'vATCertificate':
                                                              companies[index]
                                                                  .vATCertificate,
                                                          'comRegForm':
                                                              companies[index]
                                                                  .comRegForm,
                                                          'brief':
                                                              companies[index]
                                                                  .brief,
                                                        }
                                                      });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      ColorManager.blueLight800,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 2,
                                                      vertical: 4),
                                                  minimumSize:
                                                      const Size(75, 30),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: const Text("Edit",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, Routes.addCompanyRoute);
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("Add More Companies",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.blueLight800,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text("No Data Available"));
            }));
  }
}
