import 'package:quiver/core.dart';
import 'common/ps_object.dart';

class SellerTransaction extends PsObject<SellerTransaction> {
  SellerTransaction({
    this.id,
    this.orderId,
    this.orderCode,
    this.orderDate,
    this.deliveryDate,
    this.status,
    this.statusLabel,
    this.isDeliveredAndPaid,
    this.currencySymbol,
    this.grossAmount,
    this.commissionAmount,
    this.netAmount,
    this.itemName,
    this.itemCount,
    this.imageUrl,
  });

  String? id;
  String? orderId;
  String? orderCode;
  String? orderDate;
  String? deliveryDate;
  String? status;
  String? statusLabel;
  String? isDeliveredAndPaid;
  String? currencySymbol;
  String? grossAmount;
  String? commissionAmount;
  String? netAmount;
  String? itemName;
  int? itemCount;
  String? imageUrl;

  @override
  bool operator ==(dynamic other) => other is SellerTransaction && id == other.id;

  @override
  int get hashCode => hash2(id.hashCode, id.hashCode);

  @override
  String? getPrimaryKey() {
    return id;
  }

  @override
  SellerTransaction fromMap(dynamic dynamicData) {
    if (dynamicData != null && dynamicData is Map) {
      return SellerTransaction(
        id: dynamicData['id']?.toString(),
        orderId: dynamicData['order_id']?.toString(),
        orderCode: dynamicData['order_code']?.toString(),
        orderDate: dynamicData['order_date']?.toString(),
        deliveryDate: dynamicData['delivery_date']?.toString(),
        status: dynamicData['status']?.toString(),
        statusLabel: dynamicData['status_label']?.toString(),
        isDeliveredAndPaid: dynamicData['is_delivered_and_paid']?.toString(),
        currencySymbol: dynamicData['currency_symbol']?.toString(),
        grossAmount: dynamicData['gross_amount']?.toString(),
        commissionAmount: dynamicData['commission_amount']?.toString(),
        netAmount: dynamicData['net_amount']?.toString(),
        itemName: dynamicData['item_name']?.toString(),
        itemCount: int.tryParse(dynamicData['item_count']?.toString() ?? '1') ?? 1,
        imageUrl: dynamicData['image_url']?.toString(),
      );
    }
    return SellerTransaction();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['id'] = object.id;
      data['order_id'] = object.orderId;
      data['order_code'] = object.orderCode;
      data['order_date'] = object.orderDate;
      data['delivery_date'] = object.deliveryDate;
      data['status'] = object.status;
      data['status_label'] = object.statusLabel;
      data['is_delivered_and_paid'] = object.isDeliveredAndPaid;
      data['currency_symbol'] = object.currencySymbol;
      data['gross_amount'] = object.grossAmount;
      data['commission_amount'] = object.commissionAmount;
      data['net_amount'] = object.netAmount;
      data['item_name'] = object.itemName;
      data['item_count'] = object.itemCount;
      data['image_url'] = object.imageUrl;
      return data;
    }
    return null;
  }

  @override
  List<SellerTransaction> fromMapList(List<dynamic> dynamicDataList) {
    final List<SellerTransaction> list = <SellerTransaction>[];
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
