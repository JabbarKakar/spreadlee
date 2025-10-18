import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'languages_manager.dart';

const String prefsKeyLang = "prefsKeyLang";
const String prefsKeyIsLoggedIn = "prefsKeyIsLoggedIn";
const String prefsKeyOnBoarding = "prefsKeyOnBoarding";
const String hasShownCountryDialog = "hasShownCountryDialog";

class AppPreferences {
  final FlutterSecureStorage _secureStorage;

  AppPreferences(this._secureStorage);

  Future<String> getAppLanguage() async {
    String? language = await _secureStorage.read(key: prefsKeyLang);
    if (language != null && language.isNotEmpty) {
      return language;
    } else {
      // return default lang
      return LanguageType.ARABIC.getValue();
    }
  }

  Future<void> setAppLanguage(String value) async {
    await _secureStorage.write(key: prefsKeyLang, value: value);
  }

  Future<void> deleteUserLogin() async {
    await _secureStorage.write(key: prefsKeyIsLoggedIn, value: 'false');
  }

  Future<void> changeAppLanguage([String? languageCode]) async {
    String currentLang = await getAppLanguage();
    if (currentLang == LanguageType.ARABIC.getValue()) {
      await _secureStorage.write(
          key: prefsKeyLang, value: LanguageType.ENGLISH.getValue());
    } else {
      await _secureStorage.write(
          key: prefsKeyLang, value: LanguageType.ARABIC.getValue());
    }
  }

  Future<String?> getToken({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setToken({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getRole({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setRole({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getCommercialName({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setCommercialName(
      {required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getPublicName({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setPublicName(
      {required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getPhotoUrl({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setPhotoUrl({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getUserId({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setUserId({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getOTPExpiry({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setOTPExpiry(
      {required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getUsername({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setUsername({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getPassword({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setPassword({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getUserContact({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setUserContact(
      {required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getLocationId({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setLocationId(
      {required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<int?> getUserNumber({required String key}) async {
    String? value = await _secureStorage.read(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> setUserNumber({required String key, required int value}) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<Locale> getLocale() async {
    String currentLang = await getAppLanguage();
    if (currentLang == LanguageType.ARABIC.getValue()) {
      return ARABIC_LOCALE;
    } else {
      return ENGLISH_LOCALE;
    }
  }

  Future<void> setOnBoardingScreenViewed() async {
    await _secureStorage.write(key: prefsKeyOnBoarding, value: 'true');
  }

  Future<bool> isOnBoardingScreenViewed() async {
    String? value = await _secureStorage.read(key: prefsKeyOnBoarding);
    return value == 'true';
  }

  Future<void> setUserLoggedIn() async {
    await _secureStorage.write(key: prefsKeyIsLoggedIn, value: 'true');
  }

  Future<bool> isUserLoggedIn() async {
    String? value = await _secureStorage.read(key: prefsKeyIsLoggedIn);
    return value == 'true';
  }

  Future<bool> hasShownDialog() async {
    String? value = await _secureStorage.read(key: hasShownCountryDialog);
    return value == 'true';
  }
}
