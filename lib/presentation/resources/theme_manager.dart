
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spreadlee/presentation/resources/value_manager.dart';

import 'color_manager.dart';

ThemeData getApplicationTheme() {
  return ThemeData(
      appBarTheme:
          AppBarTheme(
            elevation: AppSize.s0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light),
              backgroundColor: ColorManager.primary, centerTitle: true),
      primaryColor: ColorManager.primary,
      primaryColorDark: ColorManager.darkGrey,
      disabledColor: ColorManager.lightGrey);
}
