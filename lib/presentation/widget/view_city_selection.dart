import 'package:flutter/material.dart';
import '../resources/color_manager.dart';
import 'select_city_widget.dart';

class ViewCitySelectionWidget extends StatefulWidget {
  final String countryName;
  final String countryCode;
  final List<String> initialCities;
  final Function(List<String>) onCitiesChanged;

  const ViewCitySelectionWidget({
    Key? key,
    required this.countryName,
    required this.countryCode,
    required this.initialCities,
    required this.onCitiesChanged,
  }) : super(key: key);

  @override
  State<ViewCitySelectionWidget> createState() =>
      _ViewCitySelectionWidgetState();
}

class _ViewCitySelectionWidgetState extends State<ViewCitySelectionWidget> {
  bool selectMode = false;
  List<String> selectedForDelete = [];
  late List<String> cities;

  @override
  void initState() {
    super.initState();
    cities = List<String>.from(widget.initialCities);
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void updateCities(List<String> updatedCities) {
    safeSetState(() {
      cities = updatedCities;
    });
    widget.onCitiesChanged(cities);
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
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!selectMode)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Previous',
                          style: TextStyle(color: ColorManager.blueLight800)),
                    ),
                  if (selectMode)
                    TextButton(
                      onPressed: () {
                        safeSetState(() {
                          selectMode = false;
                          selectedForDelete.clear();
                        });
                      },
                      child: Text('Cancel',
                          style: TextStyle(color: ColorManager.blueLight800)),
                    ),
                  Text(
                    widget.countryName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  if (!selectMode)
                    TextButton(
                      onPressed: cities.isNotEmpty
                          ? () {
                              safeSetState(() {
                                selectMode = true;
                              });
                            }
                          : null,
                      child: Text('Select',
                          style: TextStyle(color: ColorManager.blueLight800)),
                    ),
                  if (selectMode)
                    TextButton(
                      onPressed: selectedForDelete.isNotEmpty
                          ? () {
                              final updatedCities = List<String>.from(cities)
                                ..removeWhere(
                                    (city) => selectedForDelete.contains(city));
                              updateCities(updatedCities);
                              safeSetState(() {
                                selectedForDelete.clear();
                                selectMode = false;
                              });
                            }
                          : null,
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: selectedForDelete.isNotEmpty
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'You selected ${selectMode ? selectedForDelete.length : cities.length} cities in ${widget.countryName}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
            // City List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final isSelected = selectedForDelete.contains(city);
                  return ListTile(
                    leading: selectMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (checked) {
                              safeSetState(() {
                                if (checked == true) {
                                  selectedForDelete.add(city);
                                } else {
                                  selectedForDelete.remove(city);
                                }
                              });
                            },
                          )
                        : null,
                    title: Text(city),
                    onTap: selectMode
                        ? () {
                            safeSetState(() {
                              if (isSelected) {
                                selectedForDelete.remove(city);
                              } else {
                                selectedForDelete.add(city);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
            ),
            if (!selectMode)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<List<String>>(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: SelectCityWidget(
                            country: widget.countryName,
                            countryCode: widget.countryCode,
                            initialSelectedCities: cities,
                            onSelectionDone: (selectedCities) {
                              Navigator.pop(context, selectedCities);
                            },
                          ),
                        );
                      },
                    );

                    if (result != null) {
                      updateCities(result);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.blueLight800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text(
                    'Add city',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
