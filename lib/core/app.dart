import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/core/languages_manager.dart';
import '../presentation/resources/routes_manager.dart';
import '../presentation/resources/theme_manager.dart';
import '../services/force_logout_service.dart';
import 'package:spreadlee/core/navigation/navigation_service.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/connection_popup_service.dart';
import 'package:spreadlee/services/connection_monitor_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/core/di.dart';
import 'package:provider/provider.dart';
import '../providers/user_status_provider.dart';
import '../services/app_lifecycle_manager.dart';

class MyApp extends StatefulWidget {
  const MyApp._internal();

  static const MyApp _instance = MyApp._internal();

  factory MyApp() => _instance;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();
  final ConnectionPopupService _popupService = ConnectionPopupService();
  final ConnectionMonitorService _connectionMonitor =
      ConnectionMonitorService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    // fetchDataAndUpdateConstants();
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize popup services globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _popupService.initialize(context);
        _popupService.setConnectionServices(_connectionMonitor, _socketService);
        _socketService.initializePopupService(context);
        _connectionMonitor.initializePopupService(context);
      }
    });

    // context.read<HomeCubit>().initializeNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup popup services
    _popupService.dispose();

    // Disconnect the global ChatService socket when the app is closed
    if (instance.isRegistered<ChatService>()) {
      instance<ChatService>().disconnect();
    }
    super.dispose();
  }
  
  /// Reconnect ChatService socket when app resumes from background/screen lock
  void _reconnectChatService() {
    if (!instance.isRegistered<ChatService>()) return;
    
    try {
      final chatService = instance<ChatService>();
      
      if (kDebugMode) {
        print('=== App Level: Reconnecting ChatService ===');
        print('Socket connected: ${chatService.socket.connected}');
      }
      
      // If socket is disconnected, manually reconnect
      if (!chatService.socket.connected) {
        if (kDebugMode) {
          print('App Level: ChatService socket disconnected, reconnecting...');
        }
        
        // Give system time to stabilize, then reconnect
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            chatService.socket.connect();
            
            if (kDebugMode) {
              print('App Level: ChatService socket.connect() called');
            }
            
            // Wait for connection to establish
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (kDebugMode) {
                print('App Level: ChatService socket connected: ${chatService.socket.connected}');
              }
            });
          } catch (e) {
            if (kDebugMode) {
              print('App Level: Error reconnecting ChatService: $e');
            }
          }
        });
      } else {
        if (kDebugMode) {
          print('App Level: ChatService socket already connected');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('App Level: Error in _reconnectChatService: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userStatusProvider =
        Provider.of<UserStatusProvider>(context, listen: false);

    // Initialize lifecycle manager if not already done
    if (!_lifecycleManager.isInitialized) {
      _lifecycleManager.initialize(userStatusProvider);
    }

    switch (state) {
      case AppLifecycleState.detached:
        // App is being killed/terminated - mark user as offline immediately
        _lifecycleManager.handleAppTerminated();
        break;

      case AppLifecycleState.paused:
        // App is backgrounded (user switched to another app) - mark as offline
        _lifecycleManager.handleAppBackgrounded();
        break;

      case AppLifecycleState.inactive:
        // App is inactive (system overlay, incoming call, etc.) - mark as offline
        _lifecycleManager.handleAppInactive();
        break;

      case AppLifecycleState.resumed:
        // App is back in foreground - reconnect and mark as online
        _lifecycleManager.handleAppForegrounded();
        _lifecycleManager.handleAppActive();
        
        // ✅ CRITICAL: Reconnect ChatService socket when app resumes
        _reconnectChatService();
        break;

      case AppLifecycleState.hidden:
        // App is hidden - mark as offline
        _lifecycleManager.handleAppBackgrounded();
        break;
    }
  }

  @override
  void didChangeDependencies() {
    _getLocale().then((locale) => context.setLocale(locale));
    super.didChangeDependencies();
  }

  Future<Locale> _getLocale() async {
    String? languageCode = await _secureStorage.read(key: 'prefsKeyLang');
    if (languageCode == 'ar') {
      return ARABIC_LOCALE;
    } else {
      return ENGLISH_LOCALE;
    }
  }

  // void fetchDataAndUpdateConstants() async {
  //   Constants.token = await _secureStorage.read(key: 'token') ?? "";
  // }

  @override
  Widget build(BuildContext context) {
    // Use the global navigatorKey (ensure it's the same key used elsewhere)
    ForceLogoutService.setNavigatorKey(NavigationService.navigatorKey);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, child) {
        return MaterialApp(
          navigatorKey:
              NavigationService.navigatorKey, // Use the global navigator key
          // useInheritedMediaQuery: true,
          // locale: DevicePreview.locale(context),
          // builder: DevicePreview.appBuilder,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          debugShowCheckedModeBanner: false,
          theme: getApplicationTheme(),
          onGenerateRoute: RouteGenerator.getRoute,
          initialRoute: Routes.splashRoute,
          // home:  const LoginView() ,
        );
      },
    );
  }
}
