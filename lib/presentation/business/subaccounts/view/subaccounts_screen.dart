import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/business/subaccounts/widget/subaccount_card.dart';
import 'package:spreadlee/presentation/business/subaccounts/widget/empty_list_text.dart';
import 'package:spreadlee/presentation/bloc/business/subaccounts/subaccounts_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/subaccounts/subaccounts_states.dart';

class SubaccountsScreen extends StatefulWidget {
  const SubaccountsScreen({super.key});

  @override
  State<SubaccountsScreen> createState() => _SubaccountsScreenState();
}

class _SubaccountsScreenState extends State<SubaccountsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SubaccountsCubit>().getSubaccounts(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.companyHomeRoute,
            (route) => false,
          ),
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 20.0,
          ),
        ),
        title: Text(
          'SubAccounts',
          style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins'),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: BlocBuilder<SubaccountsCubit, SubaccountsState>(
                  builder: (context, state) {
                    if (state is SubaccountsLoadingState) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: ColorManager.blueLight800,
                        ),
                      );
                    }

                    if (state is SubaccountsSuccessState) {
                      if (state.subaccounts.isEmpty) {
                        return const EmptyListText(
                          text: 'No Subaccount Available here.',
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: state.subaccounts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16.0),
                        itemBuilder: (context, index) {
                          final subaccount = state.subaccounts[index];
                          return SubaccountCard(
                            key: ValueKey(
                                'subaccount_${subaccount.data?.first.id}'),
                            subaccount: subaccount,
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.createSubaccountRoute,
                  );
                  if (result == true && mounted) {
                    context.read<SubaccountsCubit>().getSubaccounts(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.blueLight800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 15.0,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Create New Subaccount',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
