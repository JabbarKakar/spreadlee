import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import '../../../resources/color_manager.dart';
import '../details_pricing_container.dart';

class EditDetailsPricing extends StatefulWidget {
  const EditDetailsPricing({super.key});

  @override
  State<EditDetailsPricing> createState() => _EditDetailsPricingState();
}

class _EditDetailsPricingState extends State<EditDetailsPricing> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final settingCubit = context.read<SettingCubit>();
    settingCubit.getPricingDetails();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingCubit = context.read<SettingCubit>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.companyHomeRoute,
            (route) => false,
          ),
            icon: Icon(
              Icons.arrow_back,
              color: theme.colorScheme.onSurface,
              size: 24.0,
            ),
          ),
          title: Text(
            'Edit Details & Pricing',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins'
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              0,
              24.0,
              0,
              24.0,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: DetailsPricingContainer(),
              ),
            ]
                .map((widget) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: widget,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
