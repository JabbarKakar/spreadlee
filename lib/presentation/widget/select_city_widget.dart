import 'package:flutter/material.dart';
import '../../core/outside_api_call.dart';
import '../resources/color_manager.dart';

class SelectCityWidget extends StatefulWidget {
  final String? country;
  final String? countryCode;
  final List<String> initialSelectedCities;
  final Function(List<String>) onSelectionDone;

  const SelectCityWidget({
    Key? key,
    required this.country,
    required this.countryCode,
    this.initialSelectedCities = const [],
    required this.onSelectionDone,
  }) : super(key: key);

  @override
  State<SelectCityWidget> createState() => _SelectCityWidgetState();
}

class _SelectCityWidgetState extends State<SelectCityWidget> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<String> _allCities = [];
  List<String> _filteredCities = [];
  List<String> _selectedCities = [];
  bool _isLoading = true;
  final Map<String, bool> _checkboxValueMap = {};

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCities();
    _selectedCities = List.from(widget.initialSelectedCities);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCities() async {
    if (widget.countryCode == null) return;
    List<String> fetchedCities =
        await apiService.fetchCities(widget.countryCode!);
    safeSetState(() {
      _allCities = fetchedCities;
      _filteredCities = fetchedCities;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    safeSetState(() {
      _filteredCities = _allCities
          .where((city) =>
              city.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Select City',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  if (_selectedCities.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        widget.onSelectionDone(_selectedCities);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ColorManager.blueLight800,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Find city by name',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey[400],
                    fontSize: 12.0,
                  ),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400], size: 18.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                ),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 9.0),
              child: Text(
                _selectedCities.isEmpty
                    ? 'You can choose multiple cities'
                    : 'You selected ${_selectedCities.length} cities',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey[500],
                  fontSize: 10.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        final isSelected = _selectedCities.contains(city);
                        return GestureDetector(
                          onTap: () {
                            safeSetState(() {
                              if (isSelected) {
                                _selectedCities.remove(city);
                                _checkboxValueMap[city] = false;
                              } else {
                                _selectedCities.add(city);
                                _checkboxValueMap[city] = true;
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 10.0, 10.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      checkboxTheme: CheckboxThemeData(
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                      ),
                                      unselectedWidgetColor: Colors.grey[300],
                                    ),
                                    child: Checkbox(
                                      value: _checkboxValueMap[city] ??=
                                          isSelected,
                                      onChanged: (newValue) {
                                        safeSetState(() {
                                          _checkboxValueMap[city] = newValue!;
                                          if (newValue) {
                                            _selectedCities.add(city);
                                          } else {
                                            _selectedCities.remove(city);
                                          }
                                        });
                                      },
                                      side: BorderSide(
                                        width: 2,
                                        color: Colors.grey[300]!,
                                      ),
                                      activeColor: Colors.blue[800],
                                      checkColor: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    city,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
