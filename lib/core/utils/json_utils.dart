import 'dart:convert';

/// Gets a value from a JSON object using a JSONPath-like syntax.
///
/// Example:
/// ```dart
/// final json = {'user': {'name': 'John'}};
/// final name = getJsonField(json, r'$.user.name'); // Returns 'John'
/// ```
dynamic getJsonField(dynamic json, String path) {
  if (json == null) return null;

  // Remove the leading '$.' if present
  if (path.startsWith(r'$.')) {
    path = path.substring(2);
  }

  // Split the path into parts
  final parts = path.split('.');

  // Navigate through the JSON object
  dynamic current = json;
  for (var part in parts) {
    if (current == null) return null;

    // Handle array access with [:index]
    if (part.contains('[:]')) {
      final arrayPart = part.split('[:]')[0];
      if (current is Map) {
        current = current[arrayPart];
      }
      if (current is List && current.isNotEmpty) {
        current = current.first;
      } else {
        return null;
      }
    } else {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
  }

  return current;
}

/// Casts a value to a specific type.
///
/// Example:
/// ```dart
/// final value = castToType<String>(123); // Returns '123'
/// final number = castToType<int>('123'); // Returns 123
/// ```
T? castToType<T>(dynamic value) {
  if (value == null) return null;

  if (T == String) {
    return value.toString() as T;
  } else if (T == int) {
    if (value is int) return value as T;
    if (value is String) return int.tryParse(value) as T?;
    if (value is num) return value.toInt() as T;
  } else if (T == double) {
    if (value is double) return value as T;
    if (value is String) return double.tryParse(value) as T?;
    if (value is num) return value.toDouble() as T;
  } else if (T == bool) {
    if (value is bool) return value as T;
    if (value is String) {
      return (value.toLowerCase() == 'true') as T;
    }
  } else if (T == List) {
    if (value is List) return value as T;
    if (value is String) {
      try {
        return jsonDecode(value) as T;
      } catch (_) {}
    }
  } else if (T == Map) {
    if (value is Map) return value as T;
    if (value is String) {
      try {
        return jsonDecode(value) as T;
      } catch (_) {}
    }
  }

  return null;
}
