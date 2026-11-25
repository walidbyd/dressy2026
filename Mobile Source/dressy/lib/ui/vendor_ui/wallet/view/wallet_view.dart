import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/ps_config.dart';
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

class _WalletViewState extends State<WalletView> with WidgetsBindingObserver {
  bool _isLoading = true;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = <WalletTransaction>[];
  List<Map<String, dynamic>> _topupPacks = <Map<String, dynamic>>[];
  bool _loadingPacks = false;
  int? _initiatingPackId;
  bool _pendingTopupRedirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
      _loadTopupPacks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingTopupRedirect) {
      _pendingTopupRedirect = false;
      _loadWalletData();
    }
  }

  Future<void> _loadTopupPacks() async {
    if (!mounted) {
      return;
    }
    setState(() => _loadingPacks = true);
    try {
      final PsValueHolder valueHolder =
          Provider.of<PsValueHolder>(context, listen: false);
      final String loginUserId = Utils.checkUserLoginId(valueHolder);
      final http.Response res = await http.get(
        Uri.parse('${PsConfig.ps_app_url}wallet/topup-packs?login_user_id=$loginUserId'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
          'header-token': valueHolder.headerToken ?? '',
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200 && mounted) {
        final dynamic decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
          setState(() {
            _topupPacks = (decoded['data'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .toList();
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _loadingPacks = false);
      }
    }
  }

  Future<void> _initiateTopup(int packId) async {
    if (_initiatingPackId != null) {
      return;
    }
    setState(() => _initiatingPackId = packId);
    try {
      final PsValueHolder valueHolder =
          Provider.of<PsValueHolder>(context, listen: false);
      final String loginUserId = Utils.checkUserLoginId(valueHolder);
      final http.Response res = await http.post(
        Uri.parse('${PsConfig.ps_app_url}wallet/topup/initiate'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
          'header-token': valueHolder.headerToken ?? '',
        },
        body: json.encode(<String, dynamic>{
          'pack_id': packId,
          'login_user_id': loginUserId,
        }),
      ).timeout(const Duration(seconds: 15));

      final dynamic decoded = json.decode(res.body);
      if (res.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['data'] is Map<String, dynamic>) {
        final String paymentUrl =
            (decoded['data']['payment_url'] ?? '').toString();
        if (paymentUrl.isNotEmpty) {
          _pendingTopupRedirect = true;
          final bool launched = await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!launched && mounted) {
            _pendingTopupRedirect = false;
            showDialog<dynamic>(
              context: context,
              builder: (_) => ErrorDialog(message: 'wallet__topup_error'.tr),
            );
          }
          return;
        }
      }
      if (mounted) {
        final String msg = (decoded is Map<String, dynamic> &&
                decoded['message'] != null &&
                decoded['message'].toString().isNotEmpty)
            ? decoded['message'].toString()
            : 'wallet__topup_error'.tr;
        showDialog<dynamic>(
          context: context,
          builder: (_) => ErrorDialog(message: msg),
        );
      }
    } catch (_) {
      if (mounted) {
        showDialog<dynamic>(
          context: context,
          builder: (_) => ErrorDialog(message: 'wallet__topup_error'.tr),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _initiatingPackId = null);
      }
    }
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
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
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
                ),
              ),
              const SizedBox(width: PsDimens.space12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
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
                ),
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
    final String source = (item.source ?? '').toLowerCase();
    final bool isReversal = source == 'sale_reversal';
    final bool isRefund = source == 'order_refund';
    final bool isAffiliation = source == 'affiliation_reward';
    final bool isSilkpayTopup = source == 'silkpay_topup';
    final bool isAdBoost = source == 'ad_story_boost' || source == 'ad_item_boost';

    Color iconBgColor = isCredit ? PsColors.success50 : PsColors.error50;
    Color iconColor = isCredit ? PsColors.success500 : PsColors.error500;
    IconData txIcon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;

    if (isSilkpayTopup) {
      iconBgColor = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF059669);
      txIcon = Icons.credit_card;
    } else if (isAdBoost) {
      iconBgColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      txIcon = Icons.bolt_rounded;
    } else if (isAffiliation) {
      iconBgColor = const Color(0xFFF3E8FF);
      iconColor = const Color(0xFF7C3AED);
      txIcon = Icons.card_giftcard;
    } else if (isReversal) {
      iconBgColor = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFDC2626);
      txIcon = Icons.replay;
    } else if (isRefund) {
      iconBgColor = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF2563EB);
      txIcon = Icons.undo;
    }

    String txTitle;
    if (isSilkpayTopup) {
      txTitle = (item.description != null && item.description!.trim().isNotEmpty)
          ? item.description!.trim()
          : (item.note ?? 'Rechargement CIB / Edahabia');
    } else if (isAdBoost) {
      txTitle = (item.description != null && item.description!.trim().isNotEmpty)
          ? item.description!.trim()
          : (item.note ?? 'Publicité / Boost');
    } else if (isAffiliation) {
      txTitle = (item.description != null && item.description!.trim().isNotEmpty)
          ? item.description!.trim()
          : ((item.orderCode != null && item.orderCode!.isNotEmpty)
              ? '${'affiliation__wallet_tx_title'.tr} #${item.orderCode}'
              : 'affiliation__wallet_tx_title'.tr);
    } else if (isReversal) {
      txTitle = (item.orderCode != null && item.orderCode!.isNotEmpty)
          ? 'Annulation / Retour #${item.orderCode}'
          : (item.description ?? item.note ?? 'Débit annulation');
    } else if (isRefund) {
      txTitle = (item.orderCode != null && item.orderCode!.isNotEmpty)
          ? 'Remboursement commande #${item.orderCode}'
          : (item.description ?? item.note ?? 'Remboursement commande');
    } else if (isCredit) {
      txTitle = (item.orderCode != null && item.orderCode!.isNotEmpty)
          ? 'Vente livrée #${item.orderCode}'
          : (item.note ?? 'Vente livrée');
    } else {
      txTitle = item.note ?? 'Demande de retrait';
    }

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
          color: isReversal
              ? const Color(0xFFFCA5A5)
              : (Utils.isLightMode(context)
                  ? PsColors.achromatic100
                  : PsColors.achromatic600),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              txIcon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: PsDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  txTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
                if (isReversal &&
                    item.grossAmount != null &&
                    item.grossAmount!.isNotEmpty &&
                    item.grossAmount != '0.00') ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    'Brut: ${Utils.getPriceFormat(item.grossAmount!, '#,##0')} $currency • Commission: -${Utils.getPriceFormat(item.commissionAmount ?? '0', '#,##0')} $currency • Net débité: -${Utils.getPriceFormat(item.amount ?? '0', '#,##0')} $currency',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ] else if (isAffiliation) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    'affiliation__wallet_tx_badge'.tr,
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ] else if (isCredit &&
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

  Widget _buildTopupSection() {
    if (_loadingPacks && _topupPacks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: PsDimens.space12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_topupPacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space8,
      ),
      padding: const EdgeInsets.all(PsDimens.space14),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context)
            ? PsColors.achromatic50
            : PsColors.achromatic700,
        borderRadius: BorderRadius.circular(PsDimens.space12),
        border: Border.all(
          color: Utils.isLightMode(context)
              ? PsColors.achromatic200
              : PsColors.achromatic600,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.credit_card_rounded,
                  color: PsColors.primary500, size: 20),
              const SizedBox(width: PsDimens.space8),
              Expanded(
                child: Text(
                  'wallet__topup_section_title'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'wallet__topup_section_subtitle'.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Utils.isLightMode(context)
                      ? PsColors.text800.withValues(alpha: 0.65)
                      : PsColors.text50.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: PsDimens.space12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.35,
            ),
            itemCount: _topupPacks.length,
            itemBuilder: (BuildContext ctx, int idx) {
              final Map<String, dynamic> pack = _topupPacks[idx];
              final int packId = int.tryParse((pack['id'] ?? '0').toString()) ?? 0;
              final int amount = int.tryParse((pack['amount_dzd'] ?? '0').toString()) ?? 0;
              final String label = (pack['label'] ?? '$amount DA').toString();
              final bool isBusy = _initiatingPackId == packId;

              return InkWell(
                onTap: isBusy ? null : () => _initiateTopup(packId),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Utils.isLightMode(context)
                        ? Colors.white
                        : PsColors.achromatic800,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PsColors.primary500.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: PsColors.primary500,
                              ),
                            ),
                            Text(
                              'wallet__topup_btn'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isBusy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: PsColors.primary500),
                    ],
                  ),
                ),
              );
            },
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
                  _buildTopupSection(),
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
