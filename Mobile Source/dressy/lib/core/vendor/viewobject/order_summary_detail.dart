import 'package:quiver/core.dart';

import 'common/ps_object.dart';
import 'item_info.dart';

class OrderSummaryDetail extends PsObject<OrderSummaryDetail> {
  OrderSummaryDetail(
      {this.id,
      this.orderStatusId,
      this.orderStatus,
      this.orderStatusColor,
      this.statusReason,
      this.yalidineTracking,
      this.yalidineParcelId,
      this.yalidineStatus,
      this.yalidineLabelUrl,
      this.deliveryType,
      this.toCommuneName,
      this.fromWilayaId,
      this.toWilayaId,
      this.yalidineStopDeskId,
      this.isWalletCredited,
      this.walletCreditedAt,
      this.billingAddress,
      this.orderCode,
      this.paymentMethod,
      this.paymentStatus,
      this.shippingAddress,
      this.shippingEmail,
      this.shippingFirstName,
      this.shippingLastName,
      this.vendorName,
      this.total,
      this.itemInfo,
      this.billingCity,
      this.billingCountry,
      this.billingEmail,
      this.billingFirstName,
      this.billingLastName,
      this.billingPhoneNo,
      this.billingPostalCode,
      this.billingState,
      this.isSaveBillingInfoForNextTime,
      this.isSaveShippingInfoForNextTime,
      this.shippingCity,
      this.shippingCountry,
      this.shippingPhoneNo,
      this.shippingPostalCode,
      this.shippingState,
      this.paymentDate,
      this.subTotal,
      this.deliveryFee,
      this.totalDiscount,
      this.userId,
      this.buyerUserId,
      this.sellerUserId,
      this.vendorId,
      this.isReviewed,
      this.reviewRating,
      this.isDeliveredAndPaid,
      this.deliveredAndPaidLabel});
  String? id;
  String? orderStatusId;
  String? orderStatus;
  String? orderStatusColor;
  String? statusReason;
  String? yalidineTracking;
  String? yalidineParcelId;
  String? yalidineStatus;
  String? yalidineLabelUrl;
  String? deliveryType;
  String? toCommuneName;
  String? fromWilayaId;
  String? toWilayaId;
  String? yalidineStopDeskId;
  String? isWalletCredited;
  String? walletCreditedAt;
  String? orderCode;
  String? isReviewed;
  String? reviewRating;
  String? isDeliveredAndPaid;
  String? deliveredAndPaidLabel;
  String? shippingFirstName;
  String? shippingLastName;
  String? shippingEmail;
  String? shippingPhoneNo;
  String? shippingAddress;
  String? shippingCountry;
  String? shippingCity;
  String? shippingState;
  String? shippingPostalCode;
  String? isSaveShippingInfoForNextTime;

  String? billingFirstName;
  String? billingLastName;
  String? billingEmail;
  String? billingPhoneNo;
  String? billingAddress;
  String? billingCountry;
  String? billingState;
  String? billingCity;
  String? billingPostalCode;
  String? isSaveBillingInfoForNextTime;

  String? paymentMethod;
  String? paymentStatus;
  String? paymentDate;
  String? vendorName;
  List<ItemInfo>? itemInfo;

  String? subTotal;
  String? totalDiscount;
  String? deliveryFee;
  String? total;
  String? userId;
  String? buyerUserId;
  String? sellerUserId;
  String? vendorId;

  @override
  bool operator ==(dynamic other) =>
      other is OrderSummaryDetail && orderCode == other.orderCode;

  @override
  int get hashCode => hash2(orderCode.hashCode, orderCode.hashCode);

  @override
  String? getPrimaryKey() {
    return orderCode;
  }

  @override
  OrderSummaryDetail fromMap(dynamic dynamicData) {
    if (dynamicData != null && dynamicData is Map) {
      return OrderSummaryDetail(
        id: dynamicData['id']?.toString(),
        orderStatusId: dynamicData['order_status_id']?.toString(),
        orderStatus: dynamicData['order_status']?.toString(),
        orderStatusColor: dynamicData['order_status_color']?.toString(),
        statusReason: dynamicData['status_reason']?.toString(),
        yalidineTracking: dynamicData['yalidine_tracking']?.toString(),
        yalidineParcelId: dynamicData['yalidine_parcel_id']?.toString(),
        yalidineStatus: dynamicData['yalidine_status']?.toString(),
        yalidineLabelUrl: dynamicData['yalidine_label_url']?.toString(),
        deliveryType: dynamicData['delivery_type']?.toString(),
        toCommuneName: dynamicData['to_commune_name']?.toString(),
        fromWilayaId: dynamicData['from_wilaya_id']?.toString(),
        toWilayaId: dynamicData['to_wilaya_id']?.toString(),
        yalidineStopDeskId: dynamicData['yalidine_stop_desk_id']?.toString(),
        isWalletCredited: dynamicData['is_wallet_credited']?.toString(),
        walletCreditedAt: dynamicData['wallet_credited_at']?.toString(),
        orderCode: dynamicData['order_code']?.toString(),
        shippingFirstName: dynamicData['shipping_first_name']?.toString(),
        shippingLastName: dynamicData['shipping_last_name']?.toString(),
        shippingEmail: dynamicData['shipping_email']?.toString(),
        paymentStatus: dynamicData['payment_status']?.toString(),
        paymentMethod: dynamicData['payment_method']?.toString(),
        shippingAddress: dynamicData['shipping_address']?.toString(),
        billingAddress: dynamicData['billing_address']?.toString(),
        vendorName: dynamicData['vendor_name']?.toString(),
        paymentDate: dynamicData['payment_date']?.toString(),
        total: dynamicData['total']?.toString(),
        itemInfo: dynamicData['item_info'] != null
            ? ItemInfo().fromMapList(dynamicData['item_info'])
            : null,
        shippingPhoneNo: dynamicData['shipping_phone_no']?.toString(),
        shippingCountry: dynamicData['shipping_country']?.toString(),
        shippingState: dynamicData['shipping_state']?.toString(),
        shippingCity: dynamicData['shipping_city']?.toString(),
        shippingPostalCode: dynamicData['shipping_postal_code']?.toString(),
        isSaveShippingInfoForNextTime:
            dynamicData['is_save_shipping_info_for_next_time']?.toString(),
        billingFirstName: dynamicData['billing_first_name']?.toString(),
        billingLastName: dynamicData['billing_last_name']?.toString(),
        billingEmail: dynamicData['billing_email']?.toString(),
        billingPhoneNo: dynamicData['billing_phone_no']?.toString(),
        billingCountry: dynamicData['billing_country']?.toString(),
        billingState: dynamicData['billing_state']?.toString(),
        billingCity: dynamicData['billing_city']?.toString(),
        billingPostalCode: dynamicData['billing_postal_code']?.toString(),
        isSaveBillingInfoForNextTime:
            dynamicData['is_save_billing_info_for_next_time']?.toString(),
        subTotal: dynamicData['sub_total']?.toString(),
        totalDiscount: dynamicData['total_discount']?.toString(),
        deliveryFee: dynamicData['delivery_fee']?.toString(),
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
      );
    }
    return OrderSummaryDetail();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};

      data['id'] = object.id;
      data['order_status_id'] = object.orderStatusId;
      data['order_status'] = object.orderStatus;
      data['order_status_color'] = object.orderStatusColor;
      data['status_reason'] = object.statusReason;
      data['yalidine_tracking'] = object.yalidineTracking;
      data['yalidine_parcel_id'] = object.yalidineParcelId;
      data['yalidine_status'] = object.yalidineStatus;
      data['is_wallet_credited'] = object.isWalletCredited;
      data['wallet_credited_at'] = object.walletCreditedAt;
      data['order_code'] = object.orderCode;
      data['is_reviewed'] = object.isReviewed;
      data['review_rating'] = object.reviewRating;
      data['shipping_first_name'] = object.shippingFirstName;
      data['shipping_last_name'] = object.shippingLastName;
      data['shipping_email'] = object.shippingEmail;
      data['payment_date'] = object.paymentDate;
      data['payment_status'] = object.paymentStatus;
      data['payment_method'] = object.paymentMethod;
      data['shipping_address'] = object.shippingAddress;
      data['billing_address'] = object.billingAddress;
      data['vendor_name'] = object.vendorName;
      data['total'] = object.total;
      data['item_info'] = ItemInfo().toMapList(object.itemInfo);

      data['shipping_phone_no'] = object.shippingPhoneNo;
      data['shipping_country'] = object.shippingCountry;
      data['shipping_state'] = object.shippingState;
      data['shipping_city'] = object.shippingCity;
      data['shipping_postal_code'] = object.shippingPostalCode;
      data['is_save_shipping_info_for_next_time'] =
          object.isSaveBillingInfoForNextTime;
      data['billing_first_name'] = object.billingFirstName;
      data['billing_last_name'] = object.billingLastName;
      data['billing_email'] = object.billingEmail;
      data['billing_phone_no'] = object.billingPhoneNo;
      data['billing_country'] = object.billingCountry;
      data['billing_state'] = object.billingState;
      data['billing_city'] = object.billingCity;
      data['billing_postal_code'] = object.billingPostalCode;
      data['is_save_billing_info_for_next_time'] =
          object.isSaveBillingInfoForNextTime;
      data['sub_total'] = object.subTotal;
      data['total_discount'] = object.totalDiscount;
      data['delivery_fee'] = object.deliveryFee;
      data['is_delivered_and_paid'] = object.isDeliveredAndPaid;
      data['delivered_and_paid_label'] = object.deliveredAndPaidLabel;

      return data;
    } else {
      return null;
    }
  }

  @override
  List<OrderSummaryDetail> fromMapList(List<dynamic> dynamicDataList) {
    final List<OrderSummaryDetail> newFeedList = <OrderSummaryDetail>[];
    // if (dynamicDataList != null) {
    for (dynamic json in dynamicDataList) {
      if (json != null) {
        newFeedList.add(fromMap(json));
      }
    }
    // }
    return newFeedList;
  }

  @override
  List<Map<String, dynamic>?> toMapList(List<dynamic> objectList) {
    final List<Map<String, dynamic>?> dynamicList = <Map<String, dynamic>?>[];

    // if (objectList != null) {
    for (dynamic data in objectList) {
      if (data != null) {
        dynamicList.add(toMap(data));
      }
    }
    // }
    return dynamicList;
  }
}
