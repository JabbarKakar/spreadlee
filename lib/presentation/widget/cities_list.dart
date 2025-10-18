import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import '../../core/outside_api_call.dart';

class MultiSelectCityDropdown extends StatefulWidget {
  final String countryIso;
    final Function(List<String>) onCitiesSelected; 

 const MultiSelectCityDropdown({
    Key? key,
    required this.countryIso,
    required this.onCitiesSelected,
  }) : super(key: key);

  @override
  _MultiSelectCityDropdownState createState() =>
      _MultiSelectCityDropdownState();
}

class _MultiSelectCityDropdownState extends State<MultiSelectCityDropdown> {
  final ApiService apiService = ApiService();
  List<String> cities = [];
  List<String> filteredCities = [];
  List<String> selectedCities = [];
  
  bool isDropdownOpen = false;
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCities();
  }

  @override
  void didUpdateWidget(covariant MultiSelectCityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countryIso != oldWidget.countryIso) {
      fetchCities();
    }
  }

  Future<void> fetchCities() async {
    setState(() {
      isLoading = true; // Show loading before fetching
    });
    List<String> fetchedCities =
        await apiService.fetchCities(widget.countryIso);
    setState(() {
      cities = fetchedCities;
      filteredCities = fetchedCities;
      selectedCities.clear();
      isLoading = false;
    });
  }

  void _filterCities(String query) {
    setState(() {
      filteredCities = cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _closeDropdown() {
    if (isDropdownOpen) {
      setState(() {
        isDropdownOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Detect taps outside
      onTap: _closeDropdown, // Close dropdown when tapping outside
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown Field
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
                  Expanded(
                    child: Text(
                      selectedCities.isNotEmpty
                          ? selectedCities.join(", ")
                          : "Select Cities",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
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

          // Dropdown List (closes when tapping outside)
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
                        hintText: "Search city...",
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
                      onChanged: _filterCities,
                    ),
                  ),
                  // Show loading spinner when fetching data
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ColorManager.blueLight800,
                        ),
                      ),
                    )
                  else
                    // City List with Multi-Selection
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = filteredCities[index];
                          return CheckboxListTile(
                            title: Text(city),
                            value: selectedCities.contains(city),
                            onChanged: (bool? isChecked) {
                              setState(() {
                                if (isChecked == true) {
                                  selectedCities.add(city);
                                } else {
                                  selectedCities.remove(city);
                                }
                                widget.onCitiesSelected(selectedCities);
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: ColorManager
                                .blueLight800, // Checkbox color when selected
                            tileColor: selectedCities.contains(city)
                                ? Colors.blue.withOpacity(0.2)
                                : Colors
                                    .transparent, // Background color when selected
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Optional rounded corners
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
