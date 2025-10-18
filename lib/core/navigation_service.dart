import 'package:flutter/material.dart';
import 'package:spreadlee/core/navigation/navigation_service.dart' as ns;

// Backwards-compatible top-level navigatorKey that points to the
// single NavigationService.navigatorKey instance. Some files import
// `package:spreadlee/core/navigation_service.dart` while others import
// `package:spreadlee/core/navigation/navigation_service.dart`. To avoid
// having multiple GlobalKey instances, re-use the one on
// NavigationService.navigatorKey here.
final GlobalKey<NavigatorState> navigatorKey =
    ns.NavigationService.navigatorKey;
