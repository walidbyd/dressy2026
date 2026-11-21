import 'package:quiver/core.dart';
import 'common/ps_object.dart';
import 'seller_transaction.dart';
import 'seller_transaction_summary.dart';

class SellerTransactionsResponse extends PsObject<SellerTransactionsResponse> {
  SellerTransactionsResponse({
    this.summary,
    this.transactions,
    this.total,
    this.limit,
    this.offset,
  });

  SellerTransactionSummary? summary;
  List<SellerTransaction>? transactions;
  int? total;
  int? limit;
  int? offset;

  @override
  bool operator ==(dynamic other) =>
      other is SellerTransactionsResponse && total == other.total;

  @override
  int get hashCode => hash2(total.hashCode, total.hashCode);

  @override
  String? getPrimaryKey() {
    return total?.toString();
  }

  @override
  SellerTransactionsResponse fromMap(dynamic dynamicData) {
    if (dynamicData != null && dynamicData is Map) {
      return SellerTransactionsResponse(
        summary: dynamicData['summary'] != null
            ? SellerTransactionSummary().fromMap(dynamicData['summary'])
            : SellerTransactionSummary(),
        transactions: dynamicData['transactions'] != null
            ? SellerTransaction().fromMapList(dynamicData['transactions'])
            : <SellerTransaction>[],
        total: int.tryParse(dynamicData['total']?.toString() ?? '0') ?? 0,
        limit: int.tryParse(dynamicData['limit']?.toString() ?? '20') ?? 20,
        offset: int.tryParse(dynamicData['offset']?.toString() ?? '0') ?? 0,
      );
    }
    return SellerTransactionsResponse();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['summary'] = SellerTransactionSummary().toMap(object.summary);
      data['transactions'] =
          SellerTransaction().toMapList(object.transactions ?? <SellerTransaction>[]);
      data['total'] = object.total;
      data['limit'] = object.limit;
      data['offset'] = object.offset;
      return data;
    }
    return null;
  }

  @override
  List<SellerTransactionsResponse> fromMapList(List<dynamic> dynamicDataList) {
    final List<SellerTransactionsResponse> list =
        <SellerTransactionsResponse>[];
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
