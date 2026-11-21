import 'package:quiver/core.dart';
import 'common/ps_object.dart';

class SellerTransactionSummary extends PsObject<SellerTransactionSummary> {
  SellerTransactionSummary({
    this.totalSalesCount,
    this.grossSalesTotal,
    this.totalCommission,
    this.realisedProfit,
    this.currencySymbol,
  });

  int? totalSalesCount;
  String? grossSalesTotal;
  String? totalCommission;
  String? realisedProfit;
  String? currencySymbol;

  @override
  bool operator ==(dynamic other) =>
      other is SellerTransactionSummary &&
      totalSalesCount == other.totalSalesCount &&
      realisedProfit == other.realisedProfit;

  @override
  int get hashCode => hash2(totalSalesCount.hashCode, realisedProfit.hashCode);

  @override
  String? getPrimaryKey() {
    return totalSalesCount?.toString();
  }

  @override
  SellerTransactionSummary fromMap(dynamic dynamicData) {
    if (dynamicData != null && dynamicData is Map) {
      return SellerTransactionSummary(
        totalSalesCount:
            int.tryParse(dynamicData['total_sales_count']?.toString() ?? '0') ??
                0,
        grossSalesTotal: (dynamicData['gross_sales_total'] ?? dynamicData['total_sales_amount'])?.toString() ?? '0.00',
        totalCommission: dynamicData['total_commission']?.toString() ?? '0.00',
        realisedProfit: dynamicData['realised_profit']?.toString() ?? '0.00',
        currencySymbol: dynamicData['currency_symbol']?.toString() ?? 'DA',
      );
    }
    return SellerTransactionSummary();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['total_sales_count'] = object.totalSalesCount;
      data['gross_sales_total'] = object.grossSalesTotal;
      data['total_commission'] = object.totalCommission;
      data['realised_profit'] = object.realisedProfit;
      data['currency_symbol'] = object.currencySymbol;
      return data;
    }
    return null;
  }

  @override
  List<SellerTransactionSummary> fromMapList(List<dynamic> dynamicDataList) {
    final List<SellerTransactionSummary> list = <SellerTransactionSummary>[];
    for (dynamic element in dynamicDataList) {
      if (element != null) {
        list.add(fromMap(element));
      }
    }
    return list;
  }

  @override
  List<Map<String, dynamic>?> toMapList(List<dynamic> objectList) {
    final List<Map<String, dynamic>?> list = <Map<String, dynamic>?>[];
    for (dynamic element in objectList) {
      if (element != null) {
        list.add(toMap(element));
      }
    }
    return list;
  }
}
