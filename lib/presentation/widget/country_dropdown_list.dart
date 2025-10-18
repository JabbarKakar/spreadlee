import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import '../../core/outside_api_call.dart';

class CountryDropdown extends StatefulWidget {
  final Function(String) onCountrySelected;

  const CountryDropdown({Key? key, required this.onCountrySelected})
      : super(key: key);

  @override
  _CountryDropdownState createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> filteredCountries = [];
  String? selectedCountry;
  String? selectedCountryName;
  bool isDropdownOpen = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCountries();
  }

  Future<void> fetchCountries() async {
    List<Map<String, dynamic>> fetchedCountries =
        await apiService.fetchCountries();
    setState(() {
      countries = fetchedCountries;
      filteredCountries = fetchedCountries;
    });
  }

  void _filterCountries(String query) {
    setState(() {
      filteredCountries = countries
          .where((country) =>
              country['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GestureDetector to open dropdown
        GestureDetector(
          onTap: () {
            setState(() {
              isDropdownOpen = !isDropdownOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: ColorManager.gray100,
              border: Border.all(color: ColorManager.gray50),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCountry != null
                      ? countries.firstWhere((country) =>
                          country['iso2'] == selectedCountry)['name']
                      : "Select Country",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                Icon(
                  isDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),

        // Dropdown List with Search Bar
        if (isDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorManager.gray50),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search country...",
                      hintStyle: TextStyle(
                        color: ColorManager.greycard, // Hint text color
                        fontSize: 16, // Font size
                        fontWeight: FontWeight.w400, // Font weight
                      ),
                      filled: true, // Enables background color
                      fillColor: ColorManager.gray100,
                      prefixIcon:
                          Icon(Icons.search, color: ColorManager.greycard),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _filterCountries,
                  ),
                ),

                // Country List
                SizedBox(
                  height: 400, // Adjust height as needed
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      return ListTile(
                        title: Text(country['name']),
                        onTap: () {
                          setState(() {
                            selectedCountry = country['iso2'];
                            isDropdownOpen = false; // Close dropdown
                          });
                          widget.onCountrySelected(
                              selectedCountry!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
