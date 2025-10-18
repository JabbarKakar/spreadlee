import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/bloc/business/my_wallet/wallet_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/my_wallet/wallet_states.dart';
import 'package:spreadlee/presentation/business/my_wallet/widget/wallet_card.dart';
import 'package:spreadlee/presentation/business/my_wallet/widgets/empty_list_text.dart';
import 'package:spreadlee/presentation/business/my_wallet/widgets/indicate_page_tab.dart';
import '../../../resources/color_manager.dart';
import '../../../resources/routes_manager.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  final List<String> _selectedInvoices = [];
  int _walletCount = 0;
  List<InvoiceModel> _currentInvoices = [];
  bool _isClaiming = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset to My Wallet tab when screen is focused
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      context.read<WalletCubit>().changeTab(0);
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().getWalletInvoices();
  }

  void _handleCheckboxChange(String invoiceId, bool isChecked) {
    setState(() {
      if (isChecked) {
        if (!_selectedInvoices.contains(invoiceId)) {
          _selectedInvoices.add(invoiceId);
        }
      } else {
        _selectedInvoices.remove(invoiceId);
      }
    });
  }

  void _handleClaim() async {
    if (_selectedInvoices.isEmpty) return;

    setState(() {
      _isClaiming = true;
    });

    await context.read<WalletCubit>().claimInvoices(_selectedInvoices);

    if (mounted) {
      setState(() {
        _selectedInvoices.clear();
        _isClaiming = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Your claim request has been sent successfully. It will be approved within 48 hours.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorManager.black,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.blueLight800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
          'My Wallet',
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
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                        context.read<WalletCubit>().changeTab(0);
                      },
                      child: IndicatePageTab(
                        text: 'My Wallet',
                        isActive: _selectedIndex == 0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                        context.read<WalletCubit>().changeTab(1);
                      },
                      child: IndicatePageTab(
                        text: 'Under Process',
                        isActive: _selectedIndex == 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = 2);
                        context.read<WalletCubit>().changeTab(2);
                      },
                      child: IndicatePageTab(
                        text: 'Completed',
                        isActive: _selectedIndex == 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1.0,
              thickness: 1.0,
              color: ColorManager.gray300,
            ),
            if (_selectedIndex == 0 && _walletCount > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: Text(
                  'Select single or multiple invoices to claim',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: ColorManager.gray500,
                      fontSize: 10.0,
                      fontFamily: 'Poppins'),
                ),
              ),
            Expanded(
              child: BlocBuilder<WalletCubit, WalletState>(
                builder: (context, state) {
                  if (state is WalletLoadingState) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.blueLight800,
                      ),
                    );
                  }

                  if (state is WalletSuccessState) {
                    final invoices =
                        context.read<WalletCubit>().getFilteredInvoices();
                    _walletCount = invoices.length;
                    _currentInvoices = invoices;

                    if (invoices.isEmpty) {
                      return const EmptyListText(
                        text: 'No Wallet Available here',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return WalletCard(
                          key: ValueKey('wallet_${invoice.id}'),
                          invoice: invoice,
                          pageIndex: _selectedIndex,
                          onCheckboxChanged: (isChecked) =>
                              _handleCheckboxChange(invoice.id, isChecked),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.claimInvoicesRoute,
                              arguments: invoice,
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            if (_selectedIndex == 0 && _walletCount > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isClaiming
                      ? null
                      : (_selectedInvoices.isEmpty ? null : _handleClaim),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.blueLight800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    disabledBackgroundColor: ColorManager.buttonDisable,
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Claim',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins'),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
