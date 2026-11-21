import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/common/ps_status.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/api_status.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/wallet.dart';
import '../../../../core/vendor/viewobject/wallet_transaction.dart';
import '../../common/dialog/error_dialog.dart';
import '../../common/dialog/success_dialog.dart';
import '../../common/ps_button_widget_with_round_corner.dart';

class WalletView extends StatefulWidget {
  const WalletView({Key? key}) : super(key: key);

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  bool _isLoading = true;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = <WalletTransaction>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  Future<void> _loadWalletData() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final Future<PsResource<Wallet>> balanceFuture =
        apiService.getWalletBalance(loginUserId, languageCode);
    final Future<PsResource<List<WalletTransaction>>> transactionsFuture =
        apiService.getWalletTransactions(loginUserId, 50, 0, languageCode);

    final List<dynamic> results =
        await Future.wait<dynamic>(<Future<dynamic>>[balanceFuture, transactionsFuture]);

    if (mounted) {
      final PsResource<Wallet> balanceRes = results[0] as PsResource<Wallet>;
      final PsResource<List<WalletTransaction>> transactionsRes =
          results[1] as PsResource<List<WalletTransaction>>;

      setState(() {
        _wallet = balanceRes.data;
        _transactions = transactionsRes.data ?? <WalletTransaction>[];
        _isLoading = false;
      });
    }
  }

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    bool isSubmitting = false;

    showDialog<dynamic>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              title: Text(
                'wallet__request_withdraw'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${'wallet__available_balance'.tr}: ${Utils.getPriceFormat(_wallet?.balance ?? '0', '#,##0')} ${_wallet?.currencySymbol ?? 'DA'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PsColors.primary500,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: PsDimens.space12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'wallet__amount'.tr,
                        hintText: '0',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: PsDimens.space12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'wallet__ccp_or_note'.tr,
                        hintText: 'wallet__ccp_hint'.tr,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('dialog__cancel'.tr),
                ),
                if (isSubmitting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PsColors.primary500,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final double? amount =
                          double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      final PsApiService apiService =
                          Provider.of<PsApiService>(context, listen: false);
                      final PsValueHolder valueHolder =
                          Provider.of<PsValueHolder>(context, listen: false);
                      final AppLocalization langProvider =
                          Provider.of<AppLocalization>(context, listen: false);

                      final PsResource<ApiStatus> res =
                          await apiService.postWithdrawRequest(
                        <dynamic, dynamic>{
                          'amount': amount,
                          'note': noteController.text.trim(),
                        },
                        Utils.checkUserLoginId(valueHolder),
                        langProvider.currentLocale.languageCode,
                      );

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        if (res.status == PsStatus.SUCCESS) {
                          await showDialog<dynamic>(
                            context: context,
                            builder: (BuildContext context) => SuccessDialog(
                              message: res.data?.message ??
                                  'wallet__withdraw_success'.tr,
                            ),
                          );
                          _loadWalletData();
                        } else {
                          await showDialog<dynamic>(
                            context: context,
                            builder: (BuildContext context) => ErrorDialog(
                              message: res.message,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('wallet__submit'.tr),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    final String balance = Utils.getPriceFormat(_wallet?.balance ?? '0', '#,##0');
    final String currency = _wallet?.currencySymbol ?? 'DA';
    final String totalEarned = Utils.getPriceFormat(_wallet?.totalEarned ?? '0', '#,##0');
    final String totalWithdrawn = Utils.getPriceFormat(_wallet?.totalWithdrawn ?? '0', '#,##0');

    return Container(
      margin: const EdgeInsets.all(PsDimens.space16),
      padding: const EdgeInsets.all(PsDimens.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            PsColors.primary500,
            PsColors.primary700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: PsColors.primary500.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'wallet__available_balance'.tr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: PsDimens.space8),
          Text(
            '$balance $currency',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: PsDimens.space16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: PsDimens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'wallet__total_earned'.tr,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalEarned $currency',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'wallet__total_withdrawn'.tr,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalWithdrawn $currency',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: PsDimens.space16),
          PSButtonWidgetRoundCorner(
            titleText: 'wallet__request_withdraw'.tr,
            colorData: Colors.white,
            titleTextColor: PsColors.primary500,
            height: 42,
            width: double.infinity,
            onPressed: _showWithdrawDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction item) {
    final bool isCredit = (item.type ?? '').toLowerCase() == 'credit';
    final String currency = _wallet?.currencySymbol ?? 'DA';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space6,
      ),
      padding: const EdgeInsets.all(PsDimens.space14),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context)
            ? PsColors.achromatic50
            : PsColors.achromatic700,
        borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space10)),
        border: Border.all(
          color: Utils.isLightMode(context)
              ? PsColors.achromatic100
              : PsColors.achromatic600,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCredit
                  ? PsColors.success50
                  : PsColors.error50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? PsColors.success500 : PsColors.error500,
              size: 20,
            ),
          ),
          const SizedBox(width: PsDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (item.orderCode != null && item.orderCode!.isNotEmpty)
                      ? 'Vente livrée #${item.orderCode}'
                      : (item.note ?? (isCredit ? 'Vente livrée' : 'Retrait')),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
                if (isCredit &&
                    item.grossAmount != null &&
                    item.grossAmount!.isNotEmpty &&
                    item.grossAmount != '0.00') ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    'Brut: ${Utils.getPriceFormat(item.grossAmount!, '#,##0')} $currency • Commission: -${Utils.getPriceFormat(item.commissionAmount ?? '0', '#,##0')} $currency • Net crédité: +${Utils.getPriceFormat(item.amount ?? '0', '#,##0')} $currency',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  item.createdAt ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Utils.isLightMode(context)
                            ? PsColors.text800.withValues(alpha: 0.5)
                            : PsColors.text50.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PsDimens.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${isCredit ? '+' : '-'} ${Utils.getPriceFormat(item.amount ?? '0', '#,##0')} $currency',
                style: TextStyle(
                  color: isCredit ? PsColors.success500 : PsColors.error500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${Utils.getPriceFormat(item.balanceAfter ?? '0', '#,##0')} $currency',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Utils.isLightMode(context)
                          ? PsColors.text800.withValues(alpha: 0.4)
                          : PsColors.text50.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
        ),
        title: Text(
          'home__menu_drawer_wallet'.tr,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Utils.isLightMode(context)
                    ? PsColors.achromatic900
                    : PsColors.achromatic50,
                fontWeight: FontWeight.w500,
                fontSize: PsDimens.space18,
              ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  _buildBalanceCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PsDimens.space16,
                      vertical: PsDimens.space8,
                    ),
                    child: Text(
                      'wallet__transaction_history'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                  ),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(PsDimens.space32),
                      child: Center(
                        child: Text(
                          'wallet__no_transactions'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800.withValues(alpha: 0.6)
                                    : PsColors.text50.withValues(alpha: 0.6),
                              ),
                        ),
                      ),
                    )
                  else
                    ..._transactions.map(_buildTransactionItem),
                  const SizedBox(height: PsDimens.space24),
                ],
              ),
            ),
    );
  }
}
