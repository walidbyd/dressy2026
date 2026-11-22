import 'package:flutter/material.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/promotion/item_promotion_provider.dart';
import '../../../../../core/vendor/viewobject/product.dart';
import '../../../common/base/ps_widget_with_appbar_with_no_provider.dart';

class CreditCardView extends StatefulWidget {
  const CreditCardView(
      {Key? key,
      required this.product,
      required this.amount,
      required this.howManyDay,
      required this.paymentMethod,
      required this.stripePublishableKey,
      required this.startDate,
      required this.startTimeStamp,
      required this.itemPaidHistoryProvider})
      : super(key: key);

  final Product product;
  final String? amount;
  final String? howManyDay;
  final String paymentMethod;
  final String? stripePublishableKey;
  final String? startDate;
  final String startTimeStamp;
  final ItemPromotionProvider itemPaidHistoryProvider;

  @override
  State<StatefulWidget> createState() {
    return CreditCardViewState();
  }
}

class CreditCardViewState extends State<CreditCardView> {
  @override
  Widget build(BuildContext context) {
    return PsWidgetWithAppBarWithNoProvider(
      appBarTitle: 'item_promote__credit_card_title'.tr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Text(
            'Ce mode de promotion par carte bancaire n\'est pas disponible pour le moment.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
