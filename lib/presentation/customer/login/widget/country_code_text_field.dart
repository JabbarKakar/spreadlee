import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import '../../../widget/country_key_phone.dart';
import '../../../widget/phone_mask_util.dart';

class CountryCodeTextField extends StatefulWidget {
  final String initialCountryCode;
  final bool phoneLengthError;
  final bool enterPhoneError;
  final Function(String) onChange;
  final Function(int) updateMaskLength;
  final Function(String)? onCountryCodeChanged;
  final TextEditingController? controller;
  final bool enabled;

  const CountryCodeTextField({
    Key? key,
    required this.initialCountryCode,
    required this.phoneLengthError,
    required this.enterPhoneError,
    required this.onChange,
    required this.updateMaskLength,
    this.onCountryCodeChanged,
    this.controller,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CountryCodeTextField> createState() => _CountryCodeTextFieldState();
}

class _CountryCodeTextFieldState extends State<CountryCodeTextField> {
  late String selectedCountryCode;
  late TextEditingController _controller;
  late TextInputFormatter _maskFormatter;
  String _previousCountryCode = '';

  @override
  void initState() {
    super.initState();
    selectedCountryCode = widget.initialCountryCode;
    _controller = widget.controller ?? TextEditingController();
    _maskFormatter =
        MaskTextInputFormatterFF(mask: getMask(selectedCountryCode));
    _previousCountryCode = selectedCountryCode;
    widget.updateMaskLength(getMask(selectedCountryCode).length);

    // Add listener to external controller if provided
    if (widget.controller != null) {
      widget.controller!.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    // This will be called when the external controller's text changes
    // We need to update the mask formatter to match the new text
    if (mounted) {
      setState(() {
        _maskFormatter =
            MaskTextInputFormatterFF(mask: getMask(selectedCountryCode));
      });
    }
  }

  @override
  void didUpdateWidget(CountryCodeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (widget.controller != oldWidget.controller) {
      // Remove listener from old controller
      if (oldWidget.controller != null) {
        oldWidget.controller!.removeListener(_onControllerChanged);
      }

      if (widget.controller != null) {
        _controller = widget.controller!;
        // Add listener to new controller
        widget.controller!.addListener(_onControllerChanged);
      }
    }

    if (widget.initialCountryCode != oldWidget.initialCountryCode) {
      setState(() {
        selectedCountryCode = widget.initialCountryCode;
        _maskFormatter =
            MaskTextInputFormatterFF(mask: getMask(selectedCountryCode));
        _previousCountryCode = selectedCountryCode;
      });
      widget.updateMaskLength(getMask(selectedCountryCode).length);
    } else if (selectedCountryCode != _previousCountryCode) {
      setState(() {
        _maskFormatter =
            MaskTextInputFormatterFF(mask: getMask(selectedCountryCode));
        _previousCountryCode = selectedCountryCode;
      });
      widget.updateMaskLength(getMask(selectedCountryCode).length);
    }
  }

  void _openCountrySelector() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectCountryPhoneCodeWidget(
        selectedCode: selectedCountryCode,
      ),
    );
    if (code != null && code.isNotEmpty) {
      setState(() {
        selectedCountryCode = code;
        _maskFormatter =
            MaskTextInputFormatterFF(mask: getMask(selectedCountryCode));
      });
      widget.updateMaskLength(getMask(selectedCountryCode).length);
      widget.onCountryCodeChanged?.call(selectedCountryCode);
    }
  }

  @override
  void dispose() {
    // Remove listener from controller if it was added
    if (widget.controller != null) {
      widget.controller!.removeListener(_onControllerChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              InkWell(
                onTap: widget.enabled ? _openCountrySelector : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        selectedCountryCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: Colors.black),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE5E7EB),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        getMask(selectedCountryCode)
                            .replaceAll(RegExp(r'[^#]'), '')
                            .length),
                    _maskFormatter,
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: getHintText(getMask(selectedCountryCode)),
                    hintStyle: const TextStyle(
                      color: Color(0xFFB0B3BC),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (value) {
                    widget.onChange(value);
                  },
                ),
              ),
            ],
          ),
        ),
        if (widget.enterPhoneError)
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Text(
              'Please enter phone number',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (widget.phoneLengthError)
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Text(
              'Please enter a valid phone number',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String getHintText(String mask) {
    return mask.replaceAll('#', '0');
  }
}

class SelectCountryPhoneCodeWidget extends StatefulWidget {
  final String? selectedCode;
  const SelectCountryPhoneCodeWidget({Key? key, this.selectedCode})
      : super(key: key);

  @override
  State<SelectCountryPhoneCodeWidget> createState() =>
      _SelectCountryPhoneCodeWidgetState();
}

class _SelectCountryPhoneCodeWidgetState
    extends State<SelectCountryPhoneCodeWidget> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> countries = getPhoneNumberCountriesListSpreadLee(null) ?? [];
  List<dynamic> filteredCountries = [];
  String? selectedCode;

  @override
  void initState() {
    super.initState();
    filteredCountries = countries;
    selectedCode = widget.selectedCode;
    searchController.addListener(_onSearch);
  }

  void _onSearch() {
    setState(() {
      filteredCountries =
          getPhoneNumberCountriesListSpreadLee(searchController.text) ?? [];
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Country',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Find country by name',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: Color(0xFFB0B3BC)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filteredCountries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                final isSelected = selectedCode == country['dial_code'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCode = country['dial_code'];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: isSelected
                        ? const Color(0xFFF7F8FA)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(country['flag'] ?? '',
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            country['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Text(
                          country['dial_code'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: selectedCode == null
                    ? null
                    : () {
                        Navigator.pop(context, selectedCode);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCode == null
                      ? Colors.grey[100]
                      : ColorManager.blueLight800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[100],
                ),
                child: Text(
                  'Select',
                  style: TextStyle(
                    color: selectedCode == null ? Colors.grey : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
