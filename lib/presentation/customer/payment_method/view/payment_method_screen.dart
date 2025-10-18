import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/payment_bloc/payment_state.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/customer/payment_method/widget/payment_option.dart';
import 'package:spreadlee/data/models/card_model.dart';

import '../../../resources/routes_manager.dart';

class PaymentMethodScreen extends StatelessWidget {
  final String? merchantID;
  final bool paymentNavigation;
  final String? entityID;
  final List<String>? cardBrand;
  final String? amount;
  final int? paymentOption;

  const PaymentMethodScreen({
    Key? key,
    this.merchantID,
    this.paymentNavigation = false,
    this.entityID,
    this.cardBrand,
    this.amount,
    this.paymentOption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PaymentCubit(),
        ),
      ],
      child: const _PaymentMethodView(),
    );
  }
}

class _PaymentMethodView extends StatefulWidget {
  const _PaymentMethodView({Key? key}) : super(key: key);

  @override
  State<_PaymentMethodView> createState() => _PaymentMethodViewState();
}

class _PaymentMethodViewState extends State<_PaymentMethodView> {
  bool _addCardClicked = false;
  final bool _paymentCardClicked = false;

  @override
  void initState() {
    super.initState();
    context.read<PaymentCubit>().getCards(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.customerHomeRoute),
        ),
        title: Text(
          AppStrings.paymentMethod.tr(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 16.0),
                child: Text(
                  AppStrings.yourCreditCard.tr(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Stack(
                  children: [
                    _buildAddCardButton(),
                    if (_addCardClicked)
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 60.0,
                        color: Colors.transparent,
                      ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
                child: Text(
                  AppStrings.youCanAddSeveralCreditCards.tr(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: ColorManager.gray500,
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<PaymentCubit, PaymentState>(
                  builder: (context, state) {
                    if (state is CardSavedLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final cards = context.read<PaymentCubit>().cards;
                    if (cards.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.noCards.tr(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.0,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return _buildCardItem(card);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(CardModel card) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  label: 'Delete',
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  onPressed: (_) => _showDeleteDialog(card),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                card.holderName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '**${card.cardLast4}               ${card.expiryMonth}/${card.expiryYear}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  letterSpacing: 0.0,
                ),
              ),
              trailing: const Icon(
                Icons.swipe_left_rounded,
                color: Colors.grey,
              ),
              tileColor: Colors.white,
              dense: false,
            ),
          ),
        ),
        if (_paymentCardClicked)
          Container(
            width: MediaQuery.of(context).size.width,
            height: 64.0,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
      ],
    );
  }

  Future<void> _showDeleteDialog(CardModel card) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              color: ColorManager.blueLight800,
              size: 40.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Are you sure you want to delete this card?'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<PaymentCubit>().deleteCard(
                            cardId: card.cardId,
                            context: context,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.lightError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: Text(
                      'Yes'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.blueLight800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: Text(
                      'No'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardButton() {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        setState(() => _addCardClicked = true);

        await showModalBottomSheet(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          context: context,
          builder: (bottomSheetContext) => BlocProvider(
            create: (context) => PaymentCubit(),
            child: const PaymentOptionWidget(
              forPayment: false,
            ),
          ),
        );

        setState(() => _addCardClicked = false);
      },
      child: Material(
        color: Colors.transparent,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          width: double.infinity,
          height: 60.0,
          decoration: BoxDecoration(
            color: ColorManager.gray100,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20.0,
                          height: 20.0,
                          decoration: const BoxDecoration(
                            color: ColorManager.gray500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.add_circle_rounded,
                          color: ColorManager.gray300,
                          size: 26.0,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.addNewCard.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black,
                  size: 24.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
