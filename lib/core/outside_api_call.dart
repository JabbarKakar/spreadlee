import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "https://api.countrystatecity.in/v1/";
  static const String apiKey = "N1dsRU43Y2NnVHZXZHRTYW5BSlRYeHFTeWVScXFIZTR0N0hvVUFnaw==";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'X-CSCAPI-KEY': apiKey,
    },
  ));

  // Fetch list of countries
  Future<List<Map<String, dynamic>>> fetchCountries() async {
    try {
      Response response = await _dio.get("countries");
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((country) => {
          "name": country['name'],
          "iso2": country['iso2'], // Used for fetching cities
        }).toList();
      }
    } catch (e) {
      print("Error fetching countries: $e");
    }
    return [];
  }

  // Fetch list of cities by country
  Future<List<String>> fetchCities(String countryIso) async {
    try {
      Response response = await _dio.get("countries/$countryIso/cities");
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((city) => city['name'].toString()).toList();
      }
    } catch (e) {
      print("Error fetching cities: $e");
    }
    return [];
  }
}
