import 'package:flutter/material.dart';
import '../component/widgets/order_successful_widget.dart';

class OrderSuccessfulView extends StatelessWidget {
  const OrderSuccessfulView({
    Key? key,
    required this.orderId,
    this.totalPrice = '',
    this.currencySymbol = 'DA',
  }) : super(key: key);
  final String orderId;
  final String totalPrice;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
          body: OrderSuccessfulWidget(
        orderId: orderId,
        totalPrice: totalPrice,
        currencySymbol: currencySymbol,
      )),
    );
  }
}
