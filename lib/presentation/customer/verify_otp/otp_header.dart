import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/core/languages_manager.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';



class OtpHeaderWidget extends StatefulWidget {
  const OtpHeaderWidget({super.key});

  @override
  State<OtpHeaderWidget> createState() => _OtpHeaderWidgetState();
}

class _OtpHeaderWidgetState extends State<OtpHeaderWidget> {
 String _selectedLanguage = 'en';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String get selectedLanguage => _selectedLanguage;
 
  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }


void _loadSelectedLanguage() async {
    String? currentLanguage = await _secureStorage.read(key: 'prefsKeyLang');

    setState(() {
      _selectedLanguage = currentLanguage ?? 'en'; // Default to 'en' if null
    });

    if (currentLanguage == 'ar') {
      await context.setLocale(ARABIC_LOCALE);
    } else if (currentLanguage == 'en') {
      await context.setLocale(ENGLISH_LOCALE);
    }
  }

  void setAppLanguage(BuildContext context, String languageCode) async {
    await _secureStorage.write(key: 'prefsKeyLang', value: languageCode);

    if (languageCode == 'ar') {
      await context.setLocale(ARABIC_LOCALE);
    } else if (languageCode == 'en') {
      await context.setLocale(ENGLISH_LOCALE);
    }

    setState(() {
      _selectedLanguage = languageCode;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/IMG_7539-2.png',
                width: 31.0,
                height: 55.0,
                fit: BoxFit.contain,
              ),
              Container(
                width: 140.0,
                height: 27.0,
                decoration: BoxDecoration(
                  color: ColorManager.blueLight800,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: const AlignmentDirectional(0.0, 0.0),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: _selectedLanguage == 'ar' ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      _languageButton(context, AppStrings.english.tr(), 'en'),
                      const SizedBox(width: 1.0),
                      _languageButton(context, AppStrings.arabic.tr(), 'ar'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13.0),
          Image.asset(
            'assets/images/IMG_7539-3.png',
            width: 254.0,
            height: 51.0,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }

  Widget _languageButton(
      BuildContext context, String text, String languageCode) {
    bool isSelected = _selectedLanguage == languageCode;
    return ElevatedButton(
      onPressed: () => setAppLanguage(context, languageCode),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
        backgroundColor: isSelected
            ? Theme.of(context).scaffoldBackgroundColor
            : ColorManager.blueLight800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown, // Prevent text from wrapping
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: isSelected
                ? ColorManager.blueLight800
                : Theme.of(context).scaffoldBackgroundColor,
            fontSize: 12.0,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
