import 'package:flutter/material.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/promotion/item_promotion_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../core/vendor/viewobject/product.dart';
import '../../../common/base/ps_widget_with_appbar_with_no_provider.dart';

class PayStackView extends StatefulWidget {
  const PayStackView(
      {Key? key,
      required this.product,
      required this.amount,
      required this.howManyDay,
      required this.paymentMethod,
      required this.stripePublishableKey,
      required this.startDate,
      required this.startTimeStamp,
      required this.itemPaidHistoryProvider,
      required this.userProvider,
      required this.payStackKey})
      : super(key: key);

  final Product product;
  final String? amount;
  final String? howManyDay;
  final String paymentMethod;
  final String? stripePublishableKey;
  final String? startDate;
  final String startTimeStamp;
  final ItemPromotionProvider itemPaidHistoryProvider;
  final UserProvider userProvider;
  final String? payStackKey;

  @override
  State<StatefulWidget> createState() {
    return PayStackViewState();
  }
}

class PayStackViewState extends State<PayStackView> {
  @override
  Widget build(BuildContext context) {
    return PsWidgetWithAppBarWithNoProvider(
      appBarTitle: 'item_promote__paystack_title'.tr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Text(
            'Ce mode de promotion n\'est pas disponible pour le moment.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
