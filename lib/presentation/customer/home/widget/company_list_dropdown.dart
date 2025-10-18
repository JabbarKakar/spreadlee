import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/customer/customer_company_bloc/customer_company_cubit.dart';
import '../../../bloc/customer/customer_company_bloc/customer_company_states.dart';

class DynamicDropdown extends StatefulWidget {
  final Function(String) onChanged;
  final VoidCallback? onEmpty;

  const DynamicDropdown({required this.onChanged, this.onEmpty, super.key});

  @override
  State<DynamicDropdown> createState() => _DynamicDropdownState();
}

class _DynamicDropdownState extends State<DynamicDropdown> {
  Map<String, String> nameToIdMap = {}; // name → id
  List<String> dropdownItems = [];
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerCompanyCubit, CustomerCompanyStates>(
      listener: (context, state) {
        if (state is CustomerCompanySuccessState) {
          final companies = state.customerCompanyModel.data ?? [];

          // Always refresh the dropdown data when state changes
          nameToIdMap = {
            for (var company in companies)
              company.commercialName ?? 'No Name': company.sId ?? ''
          };

          dropdownItems = nameToIdMap.keys.toList();

          // Reset selected item if it's no longer in the list
          if (selectedItem != null && !dropdownItems.contains(selectedItem)) {
            selectedItem = null;
          }

          // Notify parent if empty
          if (companies.isEmpty && widget.onEmpty != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onEmpty!();
            });
          }
        }
      },
      builder: (context, state) {
        if (state is CustomerCompanyLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CustomerCompanyErrorState) {
          return const Center(
            child: Text("Error: No Connection With The Server"),
          );
        } else if (state is CustomerCompanySuccessState) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100], // background color of the dropdown field
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedItem,
              hint: const Text(
                "Select option",
                style: TextStyle(color: Colors.grey),
              ),
              items: dropdownItems.map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedItem = newValue;
                });
                // Pass ID to parent
                widget.onChanged(nameToIdMap[newValue!] ?? '');
              },
            ),
          );
        }
        return const Center(child: Text("No Data Available"));
      },
    );
  }
}
