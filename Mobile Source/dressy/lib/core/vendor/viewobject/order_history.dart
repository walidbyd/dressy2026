import 'package:quiver/core.dart';

import 'common/ps_object.dart';
import 'item_info.dart';

class OrderHistory extends PsObject<OrderHistory> {
  OrderHistory(
      {this.id,
      this.itemCount,
      this.orderCode,
      this.orderStatus,
      this.paymentDate,
      this.paymentStatus,
      this.total,
      this.vendorName,
      this.paymentStatusColor,
      this.orderStatusColor,
      this.orderDate,
      this.orderStatusId,
      this.statusReason,
      this.yalidineTracking,
      this.yalidineStatus,
      this.deliveryFee,
      this.userId,
      this.buyerUserId,
      this.sellerUserId,
      this.vendorId,
      this.isReviewed,
      this.reviewRating,
      this.isDeliveredAndPaid,
      this.deliveredAndPaidLabel,
      this.itemInfo});

  String? id;
  String? orderCode;
  String? orderDate;
  String? paymentStatus;
  String? paymentStatusColor;
  String? orderStatus;
  String? orderStatusId;
  String? statusReason;
  String? paymentDate;
  String? vendorName;
  int? itemCount;
  String? total;
  String? deliveryFee;
  String? orderStatusColor;
  String? yalidineTracking;
  String? yalidineStatus;
  String? userId;
  String? buyerUserId;
  String? sellerUserId;
  String? vendorId;
  String? isReviewed;
  String? reviewRating;
  String? isDeliveredAndPaid;
  String? deliveredAndPaidLabel;
  List<ItemInfo>? itemInfo;

  @override
  bool operator ==(dynamic other) => other is OrderHistory && id == other.id;

  @override
  int get hashCode => hash2(id.hashCode, id.hashCode);

  @override
  String? getPrimaryKey() {
    return id;
  }

  @override
  OrderHistory fromMap(dynamic dynamicData) {
    if (dynamicData != null && dynamicData is Map) {
      return OrderHistory(
        id: dynamicData['id']?.toString(),
        orderCode: dynamicData['order_code']?.toString(),
        paymentStatus: dynamicData['payment_status']?.toString(),
        orderStatus: dynamicData['order_status']?.toString(),
        paymentDate: dynamicData['payment_date']?.toString(),
        vendorName: dynamicData['vendor_name']?.toString(),
        itemCount: int.tryParse(dynamicData['item_count']?.toString() ?? '0') ?? 0,
        orderDate: dynamicData['order_date']?.toString(),
        total: dynamicData['total']?.toString(),
        deliveryFee: dynamicData['delivery_fee']?.toString(),
        orderStatusColor: dynamicData['order_status_color']?.toString(),
        paymentStatusColor: dynamicData['payment_status_color']?.toString(),
        orderStatusId: dynamicData['order_status_id']?.toString(),
        statusReason: dynamicData['status_reason']?.toString(),
        yalidineTracking: dynamicData['yalidine_tracking']?.toString(),
        yalidineStatus: dynamicData['yalidine_status']?.toString(),
        userId: dynamicData['user_id']?.toString() ??
            dynamicData['buyer_user_id']?.toString(),
        buyerUserId: dynamicData['buyer_user_id']?.toString() ??
            dynamicData['user_id']?.toString(),
        sellerUserId: dynamicData['seller_user_id']?.toString(),
        vendorId: dynamicData['vendor_id']?.toString(),
        isReviewed: dynamicData['is_reviewed']?.toString(),
        reviewRating: dynamicData['review_rating']?.toString(),
        isDeliveredAndPaid: dynamicData['is_delivered_and_paid']?.toString(),
        deliveredAndPaidLabel: dynamicData['delivered_and_paid_label']?.toString(),
        itemInfo: dynamicData['item_info'] != null
            ? ItemInfo().fromMapList(dynamicData['item_info'])
            : null,
      );
    }
    return OrderHistory();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['id'] = object.id;
      data['order_code'] = object.orderCode;
      data['payment_status'] = object.paymentStatus;
      data['order_status'] = object.orderStatus;
      data['payment_date'] = object.paymentDate;
      data['vendor_name'] = object.vendorName;
      data['item_count'] = object.itemCount;
      data['total'] = object.total;
      data['delivery_fee'] = object.deliveryFee;
      data['payment_status_color'] = object.paymentStatusColor;
      data['order_date'] = object.orderDate;
      data['order_status_color'] = object.orderStatusColor;
      data['order_status_id'] = object.orderStatusId;
      data['status_reason'] = object.statusReason;
      data['yalidine_tracking'] = object.yalidineTracking;
      data['yalidine_status'] = object.yalidineStatus;
      data['is_reviewed'] = object.isReviewed;
      data['review_rating'] = object.reviewRating;
      data['is_delivered_and_paid'] = object.isDeliveredAndPaid;
      data['delivered_and_paid_label'] = object.deliveredAndPaidLabel;
      data['item_info'] = ItemInfo().toMapList(object.itemInfo);

      return data;
    } else {
      return null;
    }
  }

  @override
  List<OrderHistory> fromMapList(List<dynamic> dynamicDataList) {
    final List<OrderHistory> orderList = <OrderHistory>[];

    for (dynamic json in dynamicDataList) {
      if (json != null) {
        orderList.add(fromMap(json));
      }
    }

    return orderList;
  }

  @override
  List<Map<String, dynamic>?> toMapList(List<OrderHistory> objectList) {
    final List<Map<String, dynamic>?> dynamicList = <Map<String, dynamic>?>[];

    for (dynamic data in objectList) {
      if (data != null) {
        dynamicList.add(toMap(data));
      }
    }

    return dynamicList;
  }
}
