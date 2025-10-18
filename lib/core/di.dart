import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_prefs.dart';
import '../services/chat_service.dart';
import '../domain/services/media_cache_service.dart';
import 'package:spreadlee/core/constant.dart';

final instance = GetIt.instance;

Future<void> initAppModule() async {
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  instance.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  // AppPreferences instance using FlutterSecureStorage
  instance
      .registerLazySingleton<AppPreferences>(() => AppPreferences(instance()));

  // Register MediaCacheService
  if (!instance.isRegistered<MediaCacheService>()) {
    instance
        .registerLazySingleton<MediaCacheService>(() => MediaCacheService());
  }

  // Register ChatService as a singleton for global socket management
  if (!instance.isRegistered<ChatService>()) {
    instance.registerLazySingleton<ChatService>(
      () => ChatService(
        baseUrl: Constants.baseUrl,
        token: Constants.token,
      ),
    );
  }
}
