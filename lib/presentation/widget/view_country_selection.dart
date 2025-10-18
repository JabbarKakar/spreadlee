import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/widget/select_country_widget.dart';
import 'package:spreadlee/presentation/widget/view_city_selection.dart';

class ViewCountrySelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>>
      selectedCountries; // [{countryName: ..., iso2: ..., cities: [...]}, ...]
  final Function(List<Map<String, dynamic>>) onCountriesChanged;

  const ViewCountrySelectionWidget({
    Key? key,
    required this.selectedCountries,
    required this.onCountriesChanged,
  }) : super(key: key);

  @override
  State<ViewCountrySelectionWidget> createState() =>
      _ViewCountrySelectionWidgetState();
}

class _ViewCountrySelectionWidgetState
    extends State<ViewCountrySelectionWidget> {
  bool selectMode = false;
  List<Map<String, dynamic>> selectedForDelete = [];

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
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
                  const Text('View selection',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  if (!selectMode)
                    Visibility(
                      visible: widget.selectedCountries.isNotEmpty,
                      child: TextButton(
                        onPressed: () {
                          safeSetState(() {
                            selectMode = true;
                          });
                        },
                        child: Text('Select',
                            style: TextStyle(color: ColorManager.blueLight800)),
                      ),
                    ),
                  if (selectMode)
                    TextButton(
                      onPressed: selectedForDelete.isNotEmpty
                          ? () {
                              safeSetState(() {
                                widget.selectedCountries.removeWhere(
                                    (country) =>
                                        selectedForDelete.contains(country));
                                selectedForDelete.clear();
                                selectMode = false;
                              });
                              widget
                                  .onCountriesChanged(widget.selectedCountries);
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
                'You selected ${widget.selectedCountries.length} countries',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
            // Country List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.selectedCountries.length,
                itemBuilder: (context, index) {
                  final country = widget.selectedCountries[index];
                  final isSelected = selectedForDelete.contains(country);
                  return ListTile(
                    leading: selectMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (checked) {
                              safeSetState(() {
                                if (checked == true) {
                                  selectedForDelete.add(country);
                                } else {
                                  selectedForDelete.remove(country);
                                }
                              });
                            },
                          )
                        : null,
                    title: Text(country['countryName'] ?? ''),
                    // subtitle: country['cities'] != null &&
                    //         (country['cities'] as List).isNotEmpty
                    //     ? Text(
                    //         'Cities: ${(country['cities'] as List).join(', ')}')
                    //     : null,
                    trailing:
                        const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
                    onTap: () {
                      if (selectMode) {
                        safeSetState(() {
                          if (isSelected) {
                            selectedForDelete.remove(country);
                          } else {
                            selectedForDelete.add(country);
                          }
                        });
                      } else {
                        // Open city selection for this country
                        showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (context) {
                            return ViewCitySelectionWidget(
                              countryName: country['countryName'],
                              countryCode: country['iso2'],
                              initialCities: country['cities'] ?? [],
                              onCitiesChanged: (updatedCities) {
                                if (mounted) {
                                  safeSetState(() {
                                    country['cities'] = updatedCities;
                                  });
                                  widget.onCountriesChanged(
                                      widget.selectedCountries);
                                }
                              },
                            );
                          },
                        );
                      }
                    },
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
                    final result =
                        await showModalBottomSheet<List<Map<String, dynamic>>>(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: SelectCountryWidget(
                            onSelectionDone: (selectedCountries) {
                              Navigator.pop(
                                  context,
                                  selectedCountries
                                      .map((country) => country.toMap())
                                      .toList());
                            },
                          ),
                        );
                      },
                    );

                    if (result != null && mounted) {
                      safeSetState(() {
                        widget.selectedCountries.addAll(result);
                      });
                      widget.onCountriesChanged(widget.selectedCountries);
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
                    'Add country',
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
