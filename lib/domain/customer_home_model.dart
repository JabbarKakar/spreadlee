import 'package:flutter/foundation.dart';

class CustomerData {
  String? sId;
  String? role;
  String? commercialName;
  String? publicName;
  String? pricingDetails;
  String? photoUrl;
  String? price_tag;
  List<String>? countryNames;
  List<String>? cityNames;
  int? companyPin;
  List<String>? marketing_fields;

  CustomerData(
      {this.sId,
      this.role,
      this.commercialName,
      this.pricingDetails,
      this.countryNames,
      this.publicName,
      this.photoUrl,
      this.price_tag,
      this.cityNames,
      this.companyPin,
      this.marketing_fields});

  CustomerData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    role = json['role'];
    commercialName = json['commercialName'];
    pricingDetails = json['pricingDetails'];
    publicName = json['publicName'];
    photoUrl = json['photoUrl'];
    price_tag = json['price_tag'];
    // Handle country_names with various data structures
    if (json['country_names'] != null) {
      List<String> flattenedCountries = [];

      // Debug: Print original country_names data
      if (kDebugMode) {
        print('🌍 Country Names Raw Data: ${json['country_names']}');
      }

      for (var country in json['country_names']) {
        if (country != null) {
          if (country is String) {
            // Check if the string contains commas (comma-separated values)
            if (country.contains(',')) {
              // Split by comma and add each country
              List<String> splitCountries =
                  country.split(',').map((e) => e.trim()).toList();
              flattenedCountries
                  .addAll(splitCountries.where((c) => c.isNotEmpty));
              if (kDebugMode) {
                print(
                    '🌍 Split comma-separated country: $country -> $splitCountries');
              }
            } else {
              flattenedCountries.add(country);
              if (kDebugMode) {
                print('🌍 Added single country: $country');
              }
            }
          } else if (country is List) {
            // Handle nested arrays
            for (var nestedCountry in country) {
              if (nestedCountry != null && nestedCountry is String) {
                // Check if the nested country contains commas
                if (nestedCountry.contains(',')) {
                  List<String> splitCountries =
                      nestedCountry.split(',').map((e) => e.trim()).toList();
                  flattenedCountries
                      .addAll(splitCountries.where((c) => c.isNotEmpty));
                  if (kDebugMode) {
                    print(
                        '🌍 Split nested comma-separated country: $nestedCountry -> $splitCountries');
                  }
                } else {
                  flattenedCountries.add(nestedCountry);
                  if (kDebugMode) {
                    print('🌍 Added nested country: $nestedCountry');
                  }
                }
              }
            }
          }
        }
      }

      countryNames = flattenedCountries;

      // Debug: Print final parsed country_names
      if (kDebugMode) {
        print('🌍 Final Country Names: $countryNames');
      }
    } else {
      countryNames = [];
      if (kDebugMode) {
        print('🌍 Country Names is null, setting to empty array');
      }
    }

    // Handle city_names with various data structures
    if (json['city_names'] != null) {
      List<String> flattenedCities = [];

      // Debug: Print original city_names data
      if (kDebugMode) {
        print('🏙️ City Names Raw Data: ${json['city_names']}');
      }

      for (var city in json['city_names']) {
        if (city != null) {
          if (city is String) {
            // Check if the string contains commas (comma-separated values)
            if (city.contains(',')) {
              // Split by comma and add each city
              List<String> splitCities =
                  city.split(',').map((e) => e.trim()).toList();
              flattenedCities.addAll(splitCities.where((c) => c.isNotEmpty));
              if (kDebugMode) {
                print('🏙️ Split comma-separated city: $city -> $splitCities');
              }
            } else {
              flattenedCities.add(city);
              if (kDebugMode) {
                print('🏙️ Added single city: $city');
              }
            }
          } else if (city is List) {
            // Handle nested arrays
            for (var nestedCity in city) {
              if (nestedCity != null && nestedCity is String) {
                // Check if the nested city contains commas
                if (nestedCity.contains(',')) {
                  List<String> splitCities =
                      nestedCity.split(',').map((e) => e.trim()).toList();
                  flattenedCities
                      .addAll(splitCities.where((c) => c.isNotEmpty));
                  if (kDebugMode) {
                    print(
                        '🏙️ Split nested comma-separated city: $nestedCity -> $splitCities');
                  }
                } else {
                  flattenedCities.add(nestedCity);
                  if (kDebugMode) {
                    print('🏙️ Added nested city: $nestedCity');
                  }
                }
              }
            }
          }
        }
      }

      cityNames = flattenedCities;

      // Debug: Print final parsed city_names
      if (kDebugMode) {
        print('🏙️ Final City Names: $cityNames');
      }
    } else {
      cityNames = [];
      if (kDebugMode) {
        print('🏙️ City Names is null, setting to empty array');
      }
    }
    companyPin = json['company_pin'];

    // Handle marketing_fields with various data structures
    if (json['marketing_fields'] != null) {
      List<String> flattenedFields = [];

      // Debug: Print original marketing_fields data
      if (kDebugMode) {
        print('🔍 Marketing Fields Raw Data: ${json['marketing_fields']}');
      }

      // Handle the case where marketing_fields might be a list of lists or contain null values
      for (var field in json['marketing_fields']) {
        if (field != null) {
          if (field is String) {
            // Check if the string contains commas (comma-separated values)
            if (field.contains(',')) {
              // Split by comma and add each field
              List<String> splitFields =
                  field.split(',').map((e) => e.trim()).toList();
              flattenedFields.addAll(splitFields.where((f) => f.isNotEmpty));
              if (kDebugMode) {
                print('🔍 Split comma-separated field: $field -> $splitFields');
              }
            } else {
              flattenedFields.add(field);
              if (kDebugMode) {
                print('🔍 Added single field: $field');
              }
            }
          } else if (field is List) {
            // Handle nested arrays
            for (var nestedField in field) {
              if (nestedField != null && nestedField is String) {
                // Check if the nested field contains commas
                if (nestedField.contains(',')) {
                  List<String> splitFields =
                      nestedField.split(',').map((e) => e.trim()).toList();
                  flattenedFields
                      .addAll(splitFields.where((f) => f.isNotEmpty));
                  if (kDebugMode) {
                    print(
                        '🔍 Split nested comma-separated field: $nestedField -> $splitFields');
                  }
                } else {
                  flattenedFields.add(nestedField);
                  if (kDebugMode) {
                    print('🔍 Added nested field: $nestedField');
                  }
                }
              }
            }
          }
        }
      }

      // Normalize field names to match serviceIcons mapping
      marketing_fields =
          flattenedFields.map((field) => _normalizeFieldName(field)).toList();

      // Debug: Print final parsed marketing_fields
      if (kDebugMode) {
        print('🔍 Final Marketing Fields: $marketing_fields');
      }
    } else {
      marketing_fields = [];
      if (kDebugMode) {
        print('🔍 Marketing Fields is null, setting to empty array');
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['role'] = role;
    data['commercialName'] = commercialName;
    data['pricingDetails'] = pricingDetails;
    data['photoUrl'] = photoUrl;
    data['publicName'] = publicName;
    data['price_tag'] = price_tag;
    data['country_names'] = countryNames;
    data['city_names'] = cityNames;
    data['company_pin'] = companyPin;
    data['marketing_fields'] = marketing_fields;
    return data;
  }

  // Helper method to normalize field names to match serviceIcons mapping
  String _normalizeFieldName(String field) {
    // Mapping of API field names to serviceIcons keys
    final Map<String, String> fieldMapping = {
      'Digital marketing': 'Digital Marketing',
      'Airports billboards': 'Airports Billboards',
      'Metro stations advertising': 'Metro Stations Advertising',
      'Radio advertising': 'Radio Advertising',
      'Building & street billboards': 'Building & Street Billboards',
      'Event planning': 'Event Planning',
      'Influencers marketing': 'Influencers Marketing',
      'TV commercials': 'TV Commercials',
      'Cinemas advertising': 'Cinemas Advertising',
      'Taxis & buses advertising': 'Taxis & Buses Advertising',
      'Others': 'Other',
      'Other': 'Other',
    };

    // Check if we have a mapping for this field
    if (fieldMapping.containsKey(field)) {
      return fieldMapping[field]!;
    }

    // If no mapping found, return the original field (it might already be correct)
    return field;
  }
}

class CustomerHomeModel {
  bool? status;
  String? message;
  int? total;
  List<CustomerData>? data;

  CustomerHomeModel({this.status, this.message, this.data, this.total});

  factory CustomerHomeModel.fromJson(Map<String, dynamic> json) {
    return CustomerHomeModel(
      status: json['status'],
      message: json['message'],
      total: json['total'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => CustomerData.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "total": total,
      "data": data?.map((item) => item.toJson()).toList() ?? [],
    };
  }
}
