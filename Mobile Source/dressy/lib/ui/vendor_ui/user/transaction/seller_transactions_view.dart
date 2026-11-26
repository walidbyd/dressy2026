import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/seller_transaction.dart';
import '../../../../core/vendor/viewobject/seller_transaction_summary.dart';
import '../../../../core/vendor/viewobject/seller_transactions_response.dart';
import '../../../vendor_ui/common/ps_ui_widget.dart';

enum SellerDateFilterPreset {
  all,
  today,
  last7Days,
  thisMonth,
  custom,
}

class SellerTransactionsView extends StatefulWidget {
  const SellerTransactionsView({Key? key}) : super(key: key);

  @override
  State<SellerTransactionsView> createState() => _SellerTransactionsViewState();
}

class _SellerTransactionsViewState extends State<SellerTransactionsView> {
  bool _isLoading = true;
  SellerTransactionSummary? _summary;
  List<SellerTransaction> _transactions = <SellerTransaction>[];

  SellerDateFilterPreset _currentFilter = SellerDateFilterPreset.all;
  String _selectedCategory = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _getFilterDates(
      void Function(DateTime? start) outStartDate,
      void Function(DateTime? end) outEndDate) {
    final DateTime now = DateTime.now();
    switch (_currentFilter) {
      case SellerDateFilterPreset.all:
        outStartDate(null);
        outEndDate(null);
        break;
      case SellerDateFilterPreset.today:
        outStartDate(DateTime(now.year, now.month, now.day));
        outEndDate(DateTime(now.year, now.month, now.day));
        break;
      case SellerDateFilterPreset.last7Days:
        outStartDate(now.subtract(const Duration(days: 6)));
        outEndDate(now);
        break;
      case SellerDateFilterPreset.thisMonth:
        outStartDate(DateTime(now.year, now.month, 1));
        outEndDate(now);
        break;
      case SellerDateFilterPreset.custom:
        outStartDate(_customStartDate);
        outEndDate(_customEndDate);
        break;
    }
  }

  Future<void> _loadData() async {
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

    DateTime? startDate;
    DateTime? endDate;
    _getFilterDates((DateTime? s) => startDate = s, (DateTime? e) => endDate = e);

    final String? dateFromStr =
        startDate != null ? _apiDateFormat.format(startDate!) : null;
    final String? dateToStr =
        endDate != null ? _apiDateFormat.format(endDate!) : null;

    final PsResource<SellerTransactionsResponse> response =
        await apiService.getSellerSalesTransactions(
      loginUserId,
      dateFrom: dateFromStr,
      dateTo: dateToStr,
      limit: 50,
      offset: 0,
      languageCode: languageCode,
    );

    if (mounted) {
      setState(() {
        _summary = response.data?.summary ?? SellerTransactionSummary();
        _transactions = response.data?.transactions ?? <SellerTransaction>[];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCustomDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PsColors.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: PsColors.text800,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentFilter = SellerDateFilterPreset.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadData();
    }
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: PsDimens.space16, vertical: PsDimens.space8),
      child: Row(
        children: <Widget>[
          _buildFilterChip(
            label: 'seller_filter_all'.tr,
            preset: SellerDateFilterPreset.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'seller_filter_today'.tr,
            preset: SellerDateFilterPreset.today,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'seller_filter_7_days'.tr,
            preset: SellerDateFilterPreset.last7Days,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'seller_filter_this_month'.tr,
            preset: SellerDateFilterPreset.thisMonth,
          ),
          const SizedBox(width: 8),
          _buildCustomFilterChip(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required SellerDateFilterPreset preset,
  }) {
    final bool isSelected = _currentFilter == preset;
    return InkWell(
      onTap: () {
        if (_currentFilter != preset) {
          setState(() {
            _currentFilter = preset;
          });
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PsColors.primary500
              : (Utils.isLightMode(context)
                  ? PsColors.achromatic100
                  : PsColors.achromatic700),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PsColors.primary500
                : (Utils.isLightMode(context)
                    ? PsColors.achromatic200
                    : PsColors.achromatic600),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (Utils.isLightMode(context)
                    ? PsColors.text800
                    : PsColors.achromatic50),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFilterChip() {
    final bool isSelected = _currentFilter == SellerDateFilterPreset.custom;
    String label = 'seller_filter_custom'.tr;
    if (isSelected && _customStartDate != null && _customEndDate != null) {
      label =
          '${DateFormat('dd/MM').format(_customStartDate!)} - ${DateFormat('dd/MM').format(_customEndDate!)}';
    }

    return InkWell(
      onTap: _selectCustomDateRange,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PsColors.primary500
              : (Utils.isLightMode(context)
                  ? PsColors.achromatic100
                  : PsColors.achromatic700),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PsColors.primary500
                : (Utils.isLightMode(context)
                    ? PsColors.achromatic200
                    : PsColors.achromatic600),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (Utils.isLightMode(context)
                      ? PsColors.text800
                      : PsColors.achromatic50),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (Utils.isLightMode(context)
                        ? PsColors.text800
                        : PsColors.achromatic50),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final String currency = _summary?.currencySymbol ?? 'DA';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PsDimens.space16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_sales_count'.tr,
                  value: '${_summary?.totalSalesCount ?? 0}',
                  icon: Icons.shopping_bag_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  iconBgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_gross_sales'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.grossSalesTotal ?? '0', '#,##0')} $currency',
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBgColor: const Color(0xFFF5F3FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_platform_commission'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.totalCommission ?? '0', '#,##0')} $currency',
                  icon: Icons.pie_chart_outline,
                  iconColor: const Color(0xFFF59E0B),
                  iconBgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_ads_spend'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.totalAdsSpend ?? '0', '#,##0')} $currency',
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBgColor: const Color(0xFFFEF3C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_referral_gains'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.totalAffiliationGains ?? '0', '#,##0')} $currency',
                  icon: Icons.card_giftcard_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF3E8FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_topups'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.totalTopups ?? '0', '#,##0')} $currency',
                  icon: Icons.credit_card_outlined,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFECFDF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_wallet_balance'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.walletBalance ?? '0', '#,##0')} $currency',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'seller_kpi_net_account_profit'.tr,
                  value:
                      '${Utils.getPriceFormat(_summary?.netAccountProfit ?? _summary?.realisedProfit ?? '0', '#,##0')} $currency',
                  icon: Icons.savings_outlined,
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: const Color(0xFFECFDF5),
                  isHighlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final List<Map<String, String>> tabs = <Map<String, String>>[
      <String, String>{'key': 'all', 'label': 'seller_cat_all'.tr},
      <String, String>{'key': 'sale', 'label': 'seller_cat_sales'.tr},
      <String, String>{'key': 'ads', 'label': 'seller_cat_ads'.tr},
      <String, String>{'key': 'referral', 'label': 'seller_cat_referral'.tr},
      <String, String>{'key': 'topup', 'label': 'seller_cat_topup'.tr},
      <String, String>{'key': 'wallet', 'label': 'seller_cat_wallet'.tr},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: PsDimens.space16),
      child: Row(
        children: tabs.map((Map<String, String> t) {
          final String key = t['key']!;
          final bool active = _selectedCategory == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t['label']!, style: TextStyle(fontSize: 11.5, fontWeight: active ? FontWeight.bold : FontWeight.w500)),
              selected: active,
              selectedColor: PsColors.primary500.withValues(alpha: 0.16),
              onSelected: (_) => setState(() => _selectedCategory = key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(PsDimens.space14),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context)
            ? (isHighlight ? const Color(0xFFF0FDF4) : Colors.white)
            : (isHighlight
                ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                : PsColors.achromatic700),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF10B981)
              : (Utils.isLightMode(context)
                  ? const Color(0xFFE5E7EB)
                  : PsColors.achromatic600),
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Utils.isLightMode(context)
                      ? PsColors.text800.withValues(alpha: 0.6)
                      : PsColors.achromatic50.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isHighlight
                  ? const Color(0xFF10B981)
                  : (Utils.isLightMode(context)
                      ? PsColors.text800
                      : PsColors.achromatic50),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(SellerTransaction item) {
    final String currency = item.currencySymbol ?? 'DA';
    final String category = (item.category ?? '').toLowerCase();
    final bool isLedgerItem = category == 'ads' ||
        category == 'referral' ||
        category == 'topup' ||
        category == 'wallet';

    if (isLedgerItem) {
      final bool isCredit = (item.type ?? '').toLowerCase() == 'credit' ||
          !(item.netAmount ?? '').startsWith('-');
      final String cleanAmt = Utils.getPriceFormat(
          (item.netAmount ?? item.grossAmount ?? '0').replaceAll('-', ''),
          '#,##0');
      final String amtText = '${isCredit ? '+' : '-'}$cleanAmt $currency';
      Color badgeBg = const Color(0xFFECFDF5);
      Color badgeText = const Color(0xFF059669);
      IconData catIcon = Icons.account_balance_wallet_outlined;
      if (category == 'ads') {
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        catIcon = Icons.bolt_rounded;
      } else if (category == 'referral') {
        badgeBg = const Color(0xFFF3E8FF);
        badgeText = const Color(0xFF7C3AED);
        catIcon = Icons.card_giftcard_outlined;
      } else if (category == 'topup') {
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF059669);
        catIcon = Icons.credit_card_outlined;
      } else if (!isCredit) {
        badgeBg = const Color(0xFFFEF2F2);
        badgeText = const Color(0xFFDC2626);
      }

      return Container(
        margin: const EdgeInsets.symmetric(
            horizontal: PsDimens.space16, vertical: PsDimens.space6),
        padding: const EdgeInsets.all(PsDimens.space12),
        decoration: BoxDecoration(
          color: Utils.isLightMode(context)
              ? Colors.white
              : PsColors.achromatic700,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Utils.isLightMode(context)
                ? const Color(0xFFE5E7EB)
                : PsColors.achromatic600,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
              child: Icon(catIcon, color: badgeText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.statusLabel ?? category.toUpperCase(),
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.itemTitle ?? item.itemName ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if ((item.deliveryDate ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      item.deliveryDate!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Utils.isLightMode(context)
                                ? PsColors.text800.withValues(alpha: 0.5)
                                : PsColors.achromatic50.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amtText,
              style: TextStyle(
                color: isCredit
                    ? const Color(0xFF10B981)
                    : const Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      );
    }

    final String status = (item.statusType ?? item.status ?? '').toLowerCase();
    final bool isCancelled = status == 'cancelled';
    final bool isReturned = status == 'returned';
    final bool hasDeduction = item.netAmount != null && item.netAmount!.startsWith('-');
    final bool isReversal = isCancelled || isReturned || hasDeduction;

    final Color badgeBg = isReversal ? const Color(0xFFFEF2F2) : const Color(0xFFE8F5E9);
    final Color badgeBorder = isReversal ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final Color badgeText = isReversal ? const Color(0xFFDC2626) : const Color(0xFF10B981);
    final IconData badgeIcon = isReversal
        ? (isReturned ? Icons.replay : Icons.cancel_outlined)
        : Icons.done_all;
    final String badgeLabel = item.statusLabel ?? (isReturned ? 'Retournée' : (isCancelled ? 'Annulée' : 'Livré et payé'));

    final String cleanNetAmount = Utils.getPriceFormat((item.netAmount ?? '0').replaceAll('-', ''), '#,##0');
    final String netAmountText;
    final bool isNetPositive;

    if (isCancelled || isReturned) {
      if (hasDeduction) {
        netAmountText = '-$cleanNetAmount $currency';
        isNetPositive = false;
      } else {
        netAmountText = '0 $currency';
        isNetPositive = false;
      }
    } else {
      netAmountText = '+$cleanNetAmount $currency';
      isNetPositive = true;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: PsDimens.space16, vertical: PsDimens.space6),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context)
            ? Colors.white
            : PsColors.achromatic700,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReversal
              ? const Color(0xFFFCA5A5)
              : (Utils.isLightMode(context)
                  ? const Color(0xFFE5E7EB)
                  : PsColors.achromatic600),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (item.orderId != null && item.orderId!.isNotEmpty) {
            Navigator.of(context).pushNamed(
              RoutePaths.sellerOrderDetail,
              arguments: <String, dynamic>{
                'orderId': item.orderId,
              },
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Row: Order Code & Item Title & Status Badge
              Row(
                children: <Widget>[
                  Text(
                    '#${item.orderCode ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF5C1A2B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.itemTitle ?? item.itemName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      border: Border.all(
                          color: badgeBorder, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(badgeIcon,
                            size: 13, color: badgeText),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: TextStyle(
                            color: badgeText,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Middle: Product Thumbnail (54x54, border radius 10) & Date / Count
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 54,
                      height: 54,
                      color: Utils.isLightMode(context)
                          ? const Color(0xFFF3F4F6)
                          : PsColors.achromatic800,
                      child: (item.defaultPhoto != null && (item.defaultPhoto?.imgPath?.isNotEmpty ?? false))
                          ? PsNetworkImage(
                              photoKey: '',
                              defaultPhoto: item.defaultPhoto,
                              imageAspectRation: PsConst.Aspect_Ratio_1x,
                              width: 54,
                              height: 54,
                              boxfit: BoxFit.cover,
                            )
                          : ((item.itemImage ?? item.imageUrl)?.isNotEmpty ?? false)
                              ? Image.network(
                                  item.itemImage ?? item.imageUrl!,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context, Object error,
                                      StackTrace? stackTrace) {
                                    return const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.grey,
                                      size: 24,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.deliveryDate ?? item.orderDate ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800.withValues(alpha: 0.6)
                                    : PsColors.achromatic50.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.itemCount ?? 1} ${(item.itemCount ?? 1) > 1 ? 'articles' : 'article'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800.withValues(alpha: 0.45)
                                    : PsColors.achromatic50.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom Financial Row: Responsive 3-Column Layout with FittedBox (Zero Overflow)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Utils.isLightMode(context)
                      ? const Color(0xFFFAF7F2)
                      : PsColors.achromatic800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    // Col 1: Vente
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'seller_financial_sale'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800.withValues(alpha: 0.6)
                                    : PsColors.achromatic50.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${Utils.getPriceFormat(item.grossAmount ?? '0', '#,##0')} $currency',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: (isCancelled || isReturned) ? TextDecoration.lineThrough : null,
                                color: (isCancelled || isReturned)
                                    ? (Utils.isLightMode(context)
                                        ? PsColors.text800.withValues(alpha: 0.4)
                                        : PsColors.achromatic50.withValues(alpha: 0.4))
                                    : (Utils.isLightMode(context)
                                        ? PsColors.text800
                                        : PsColors.achromatic50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Utils.isLightMode(context) ? const Color(0xFFE5E7EB) : PsColors.achromatic600,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    // Col 2: Commission
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'seller_financial_commission'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800.withValues(alpha: 0.6)
                                    : PsColors.achromatic50.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (isCancelled || isReturned)
                                  ? '0 $currency'
                                  : '-${Utils.getPriceFormat(item.commissionAmount ?? '0', '#,##0')} $currency',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Utils.isLightMode(context) ? const Color(0xFFE5E7EB) : PsColors.achromatic600,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    // Col 3: Net réalisé
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'seller_financial_net'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800.withValues(alpha: 0.6)
                                    : PsColors.achromatic50.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              netAmountText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isNetPositive ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
        ),
        title: Text(
          'seller_sales_transactions_title'.tr,
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
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  const SizedBox(height: 8),
                  _buildFilterPills(),
                  const SizedBox(height: 6),
                  _buildCategoryTabs(),
                  const SizedBox(height: 12),
                  _buildKpiGrid(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PsDimens.space16, vertical: PsDimens.space6),
                    child: Text(
                      'seller_transactions_ledger_title'.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  Builder(
                    builder: (BuildContext bCtx) {
                      final List<SellerTransaction> visibleTx =
                          _selectedCategory == 'all'
                              ? _transactions
                              : _transactions.where((SellerTransaction t) {
                                  final String c =
                                      (t.category ?? 'sale').toLowerCase();
                                  if (_selectedCategory == 'sale') {
                                    return c == 'sale' || c == 'reversal';
                                  }
                                  return c == _selectedCategory;
                                }).toList();
                      if (visibleTx.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(PsDimens.space32),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 56,
                                color: Utils.isLightMode(context)
                                    ? PsColors.achromatic300
                                    : PsColors.achromatic500,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'seller_no_transactions_found'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Utils.isLightMode(context)
                                          ? PsColors.text800
                                              .withValues(alpha: 0.5)
                                          : PsColors.achromatic50
                                              .withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: visibleTx.map(_buildTransactionItem).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
