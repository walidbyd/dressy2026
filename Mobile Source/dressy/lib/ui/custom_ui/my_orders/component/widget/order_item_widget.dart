import 'package:flutter/material.dart';

import '../../../../../core/vendor/viewobject/item_info.dart';
import '../../../../vendor_ui/my_orders/component/list/widget/order_item_widget.dart';

class CustomOrderItemWidget extends StatelessWidget {
  const CustomOrderItemWidget(
      {Key? key,
      this.itemCount,
      this.orderCode,
      this.orderStatus,
      this.paymentDate,
      this.total,
      this.orderStatusColor,
      this.itemInfo,
      this.isReviewed,
      this.reviewRating,
      this.isDeliveredAndPaid,
      this.deliveredAndPaidLabel})
      : super(key: key);
  final String? orderCode;
  final String? orderStatus;
  final String? paymentDate;
  final int? itemCount;
  final String? total;
  final String? orderStatusColor;
  final List<ItemInfo>? itemInfo;
  final String? isReviewed;
  final String? reviewRating;
  final String? isDeliveredAndPaid;
  final String? deliveredAndPaidLabel;
  @override
  Widget build(BuildContext context) {
    return OrderItemWidget(
        orderCode: orderCode,
        orderStatus: orderStatus,
        paymentDate: paymentDate,
        itemCount: itemCount,
        total: total,
        orderStatusColor: orderStatusColor,
        isReviewed: isReviewed,
        reviewRating: reviewRating,
        isDeliveredAndPaid: isDeliveredAndPaid,
        deliveredAndPaidLabel: deliveredAndPaidLabel,
        itemInfo: itemInfo);
  }
}
