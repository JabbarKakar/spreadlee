import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/presentation/resources/assets_manager.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/services/force_logout_service.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/presentation/bloc/business/chat_bloc/chat_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/chat_bloc/chat_cubit.dart';
import '../../../core/constant.dart';
import 'package:spreadlee/providers/user_status_provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ChatService _chatService = ChatService(); // Use singleton

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load all user data from secure storage
      final token = await _secureStorage.read(key: "token");
      final userNumber = await _secureStorage.read(key: "userNumber");
      final userId = await _secureStorage.read(key: "userId");
      final role = await _secureStorage.read(key: "role");

      // Update Constants
      Constants.token = token ?? "";
      Constants.userNumber = int.tryParse(userNumber ?? "0") ?? 0;
      Constants.userId = userId ?? "";
      Constants.role = role ?? "";

      // Set ChatService singleton fields and initialize socket
      if (Constants.baseUrl.isNotEmpty && Constants.token.isNotEmpty) {
        // Ensure suspended services are resumed before attempting to initialize
        try {
          ChatService().resume();
        } catch (e) {
          if (kDebugMode) print('Error resuming ChatService: $e');
        }
        try {
          SocketService().resume();
        } catch (e) {
          if (kDebugMode) print('Error resuming SocketService: $e');
        }

        _chatService.baseUrl = Constants.baseUrl;
        _chatService.token = Constants.token;
        _chatService.initializeSocket();
      }

      if (kDebugMode) {
        print("=== Splash Screen: User Data Loaded ===");
        print(
            "Token: ${Constants.token.isNotEmpty ? 'Available' : 'Not available'}");
        print("User ID: ${Constants.userId}");
        print("Role: ${Constants.role}");
      }

      // Reinitialize force logout service with the loaded token
      if (Constants.token.isNotEmpty) {
        ForceLogoutService.reinitialize();

        // Connect the global UserStatusProvider
        final userStatusProvider =
            Provider.of<UserStatusProvider>(context, listen: false);
        userStatusProvider.connect(Constants.userId, Constants.token);

        // Initialize chat services in background (non-blocking)
        _initializeChatServicesInBackground();
      }

      // Start the timer for navigation immediately
      _startNavigationTimer();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading user data: $e");
      }
      // Start timer even if there's an error
      _startNavigationTimer();
    }
  }

  /// Initialize chat services in background without blocking navigation
  void _initializeChatServicesInBackground() {
    // Use a microtask to run this after the current frame
    Future.microtask(() async {
      try {
        if (kDebugMode) {
          print("=== Starting Background Chat Services Initialization ===");
        }

        // Use a shorter timer to prevent blocking for too long
        Timer(const Duration(seconds: 5), () {
          if (kDebugMode) {
            print("=== Chat Services Initialization Timeout ===");
          }
        });

        // Chat services are now handled by the individual chat screens
        if (kDebugMode) {
          print("=== Chat Services Initialization Skipped (No Database) ===");
        }

        // Reinitialize chat cubits with the new token
        try {
          final chatBusinessCubit = BlocProvider.of<ChatBusinessCubit>(context);
          final chatCustomerCubit = BlocProvider.of<ChatCustomerCubit>(context);

          chatBusinessCubit.reinitializeWithToken(Constants.token);
          chatCustomerCubit.reinitializeWithToken(Constants.token);

          if (kDebugMode) {
            print("=== Chat Cubits Reinitialized ===");
            print("Chat cubits reinitialized with new token");
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error reinitializing chat cubits: $e");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error initializing chat services: $e");
        }
        // Don't block the app - chat services will initialize when needed
      }
    });
  }

  void _startNavigationTimer() {
    _timer = Timer(const Duration(seconds: 1), () async {
      String? isUserLoggedIn = await _secureStorage.read(key: "isUserLoggedIn");

      if (isUserLoggedIn == "true") {
        // Navigate to main screen
        if (Constants.role == "customer") {
          Navigator.pushReplacementNamed(context, Routes.customerHomeRoute);
        } else {
          Navigator.pushReplacementNamed(context, Routes.companyHomeRoute);
        }
      } else {
        Navigator.pushReplacementNamed(context, Routes.loginCustomerRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: AppBar(
          backgroundColor: ColorManager.white,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
            statusBarColor: ColorManager.lightPrimary,
          ),
        ),
      ),
      backgroundColor: ColorManager.white,
      body: Center(
        child: Image.asset(ImageManager.splashLogo, height: 100, width: 280),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
