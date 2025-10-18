import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../resources/color_manager.dart';
import '../../../resources/string_manager.dart';

class SearchTextField extends StatefulWidget {
  final Function(String) onSearchChanged;

  const SearchTextField({Key? key, required this.onSearchChanged}) : super(key: key);

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Timer? _debounce;
  String searchQuery = "";

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isSearching = value.isNotEmpty;
        });
        widget.onSearchChanged(value); // Call parent function with search query
      }
    });
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _isSearching = false;
    });
    widget.onSearchChanged(""); // Clear search in parent
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100.0),
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.gray50,
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: TextFormField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: AppStrings.searchHere.tr(),
            hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 12.0),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: ColorManager.gray100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            suffixIcon: _isSearching
                ? InkWell(
                    onTap: _clearText,
                    child: const Icon(Icons.clear, color: Colors.grey, size: 18.0),
                  )
                : const Icon(Icons.search, color: Colors.grey, size: 22.0),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.0),
        ),
      ),
    );
  }
}
