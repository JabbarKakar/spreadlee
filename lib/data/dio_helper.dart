import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../core/constant.dart';

const String applicationJson = "application/json";
const String contentType = "content-type";
const String accept = "accept";
const String authorization = "Authorization";
const String defaultLanguage = "language";

class DioHelper {
  static Dio? dio;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static init() {
    if (_isInitialized) return;

    // Map<String, String> headers = {
    //   accept: applicationJson,
    //   authorization: "Bearer ${Constants.token}"
    // };

    dio = Dio(BaseOptions(
        followRedirects: false,
        validateStatus: (state) => true,
        baseUrl: Constants.baseUrl,
        receiveTimeout:
            const Duration(seconds: 30), // Increased from 15 to 30 seconds
        sendTimeout:
            const Duration(seconds: 30), // Increased from 15 to 30 seconds
        connectTimeout:
            const Duration(seconds: 30))); // Added explicit connect timeout
    dio?.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers = {
          accept: applicationJson,
          authorization: "Bearer ${Constants.token}"
        };
        print("🔹 Headers Updated: ${options.headers}");
        return handler.next(options);
      },
    ));
    if (!kReleaseMode) {
      dio?.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
      ));
    }

    _isInitialized = true;
  }

  static Future<Response?> getData({
    required String endPoint,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio?.get(
      endPoint,
      queryParameters: queryParameters ?? query,
    );
  }

  static Future<Response?> updateData(
      {required String endPoint, required Map<String, dynamic> data}) async {
    return await dio?.put(
      endPoint,
      data: data,
    );
  }

  static Future<Response?> postData(
      {required String endPoint, required Map<String, dynamic> data}) async {
    return await dio?.post(
      endPoint,
      data: data,
    );
  }

  static Future<Response?> postDataWithFiles({
    required String endPoint,
    FormData? data,
  }) async {
    try {
      return await dio?.post(endPoint, data: data);
    } catch (error) {
      print("Dio Error: ${error.toString()}");
      return null; // Return null instead of crashing
    }
  }

  static Future<Response?> updateDataWithFiles({
    required String endPoint,
    FormData? data,
    ProgressCallback? onSendProgress,
  }) async {
    return await dio?.put(
      endPoint,
      data: data,
      onSendProgress: onSendProgress,
    );
  }

  static Future<Response?> delete({required String endPoint}) async {
    return await dio?.delete(endPoint);
  }
}
