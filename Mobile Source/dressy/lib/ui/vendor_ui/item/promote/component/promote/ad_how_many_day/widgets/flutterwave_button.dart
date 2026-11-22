import 'package:flutter/material.dart';
import '../../../../../../../../core/vendor/provider/app_info/app_info_provider.dart';
import '../../../../../../../../core/vendor/provider/promotion/item_promotion_provider.dart';
import '../../../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../../../core/vendor/viewobject/product.dart';

class FlutterwaveButton extends StatelessWidget {
  const FlutterwaveButton({
    required this.product,
    required this.amount,
    required this.howManyDay,
    required this.selectedDate,
    required this.selectedTime,
    required this.provider,
    required this.appProvider,
    required this.userProvider,
  });

  final Product product;
  final String howManyDay;
  final String amount;
  final String selectedDate;
  final DateTime selectedTime;
  final ItemPromotionProvider? provider;
  final AppInfoProvider? appProvider;
  final UserProvider? userProvider;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
