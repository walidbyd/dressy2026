

import '../common/ps_holder.dart';

class ResetUnreadMessageParameterHolder
    extends PsHolder<ResetUnreadMessageParameterHolder> {
  ResetUnreadMessageParameterHolder({
    required this.itemId,
    required this.buyerUserId,
    required this.sellerUserId,
    required this.type,
    this.orderId,
    this.orderCode,
  });

  final String? itemId;
  final String? buyerUserId;
  final String? sellerUserId;
  final String? type;
  final String? orderId;
  final String? orderCode;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['item_id'] = itemId;
    map['buyer_user_id'] = buyerUserId;
    map['seller_user_id'] = sellerUserId;
    map['type'] = type;
    if (orderId != null && orderId!.isNotEmpty) {
      map['order_id'] = orderId;
    }
    if (orderCode != null && orderCode!.isNotEmpty) {
      map['order_code'] = orderCode;
    }
    return map;
  }

  @override
  ResetUnreadMessageParameterHolder fromMap(dynamic dynamicData) {
    return ResetUnreadMessageParameterHolder(
      itemId: dynamicData['item_id'],
      buyerUserId: dynamicData['buyer_user_id'],
      sellerUserId: dynamicData['seller_user_id'],
      type: dynamicData['type'],
      orderId: dynamicData['order_id'],
      orderCode: dynamicData['order_code'],
    );
  }

  @override
  String getParamKey() {
    String key = '';

    if (itemId != '') {
      key += itemId!;
    }
    if (buyerUserId != '') {
      key += buyerUserId!;
    }
    if (sellerUserId != '') {
      key += sellerUserId!;
    }
    if (type != '') {
      key += type!;
    }
    if (orderId != null && orderId != '') {
      key += orderId!;
    }
    if (orderCode != null && orderCode != '') {
      key += orderCode!;
    }

    return key;
  }
}
