import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/widget/view_country_selection.dart';
import '../../core/outside_api_call.dart';
import '../resources/color_manager.dart';
import 'select_city_widget.dart';

class SelectedCountry {
  final String countryName;
  final String countryCode;
  final List<String> cities;
  SelectedCountry({
    required this.countryName,
    required this.countryCode,
    required this.cities,
  });

  Map<String, dynamic> toMap() => {
        'countryName': countryName,
        'iso2': countryCode,
        'cities': cities,
      };

  factory SelectedCountry.fromMap(Map<String, dynamic> map) => SelectedCountry(
        countryName: map['countryName'],
        countryCode: map['iso2'],
        cities: List<String>.from(map['cities'] ?? []),
      );
}

class SelectCountryWidget extends StatefulWidget {
  final List<SelectedCountry> initialSelectedCountries;
  final Function(List<SelectedCountry>) onSelectionDone;

  // Add static cache for countries
  static List<Map<String, dynamic>>? _cachedCountries;

  const SelectCountryWidget({
    Key? key,
    this.initialSelectedCountries = const [],
    required this.onSelectionDone,
  }) : super(key: key);

  @override
  State<SelectCountryWidget> createState() => _SelectCountryWidgetState();
}

class _SelectCountryWidgetState extends State<SelectCountryWidget> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allCountries = [];
  List<Map<String, dynamic>> _filteredCountries = [];
  List<SelectedCountry> _selectedCountries = [];
  bool _isLoading = true;

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCountries = List.from(widget.initialSelectedCountries);
    _fetchCountries();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCountries() async {
    if (SelectCountryWidget._cachedCountries != null) {
      _allCountries = SelectCountryWidget._cachedCountries!;
      safeSetState(() {
        _filteredCountries = _allCountries;
        _isLoading = false;
      });
      return;
    }
    List<Map<String, dynamic>> fetchedCountries =
        await apiService.fetchCountries();
    SelectCountryWidget._cachedCountries = fetchedCountries;
    _allCountries = fetchedCountries;
    safeSetState(() {
      _filteredCountries = _allCountries;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    safeSetState(() {
      _filteredCountries = _allCountries
          .where((country) => country['name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _addSelectedCountry(
      String countryName, String countryCode, List<String> cities) {
    // Check if country already exists
    final existingIndex = _selectedCountries
        .indexWhere((country) => country.countryName == countryName);

    if (existingIndex != -1) {
      // Update existing country's cities
      safeSetState(() {
        _selectedCountries[existingIndex] = SelectedCountry(
          countryName: countryName,
          countryCode: countryCode,
          cities: cities,
        );
      });
    } else {
      // Add new country
      safeSetState(() {
        _selectedCountries.add(
          SelectedCountry(
            countryName: countryName,
            countryCode: countryCode,
            cities: cities,
          ),
        );
      });
    }
  }

  int get totalSelectedCities =>
      _selectedCountries.fold(0, (sum, c) => sum + c.cities.length);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCountries = _filteredCountries.where((country) {
      return country['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Cancel, Title, Done
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: ColorManager.blueLight800)),
                  ),
                  const Text('Select country',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  TextButton(
                    onPressed: _selectedCountries.isNotEmpty
                        ? () {
                            Navigator.pop(context, _selectedCountries);
                          }
                        : null,
                    child: Text('Done',
                        style: TextStyle(
                            color: _selectedCountries.isNotEmpty
                                ? ColorManager.blueLight800
                                : Colors.grey)),
                  ),
                ],
              ),
            ),
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Find country by name',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 16),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Selected countries as chips
            if (_selectedCountries.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 3.0, 16.0, 12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  direction: Axis.horizontal,
                  runAlignment: WrapAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  clipBehavior: Clip.none,
                  children: List.generate(_selectedCountries.length, (index) {
                    final country = _selectedCountries[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9DDE8), // Light grey
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 6.0),
                      child: Text(
                        country.countryName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 15.0,
                          color: Color(0xFF222B45), // Dark text
                        ),
                      ),
                    );
                  }),
                ),
              ),
            // Info text: number of selected countries and cities
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'You selected ${_selectedCountries.length} and $totalSelectedCities cities',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500),
              ),
            ),
            // Country list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final countryName = country['name'];
                        final isSelected = _selectedCountries
                            .any((c) => c.countryName == countryName);
                        return InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: isSelected
                              ? null
                              : () async {
                                  // Store current selections before navigating
                                  final currentSelections =
                                      List<SelectedCountry>.from(
                                          _selectedCountries);

                                  await showModalBottomSheet(
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    isDismissible: false,
                                    enableDrag: false,
                                    context: context,
                                    builder: (context) {
                                      return SelectCityWidget(
                                        country: countryName,
                                        countryCode: country['iso2'],
                                        initialSelectedCities: const [], // Start with empty cities for new country
                                        onSelectionDone: (selectedCities) {
                                          if (selectedCities.isNotEmpty) {
                                            _addSelectedCountry(
                                                countryName,
                                                country['iso2'],
                                                selectedCities);
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  8.0, 10.0, 10.0, 10.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    countryName,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: isSelected
                                          ? Colors.grey[300]
                                          : Colors.black,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_right,
                                    color: isSelected
                                        ? Colors.grey[300]
                                        : Colors.grey[500],
                                    size: 20.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_selectedCountries.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      isDismissible: false,
                      enableDrag: false,
                      context: context,
                      builder: (context) {
                        return ViewCountrySelectionWidget(
                          selectedCountries: _selectedCountries
                              .map((country) => country.toMap())
                              .toList(),
                          onCountriesChanged: (countries) {
                            _selectedCountries = countries
                                .map((countryMap) =>
                                    SelectedCountry.fromMap(countryMap))
                                .toList();
                          },
                        );
                      },
                    ).then((value) => safeSetState(() {}));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.blueLight800,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View selection',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
