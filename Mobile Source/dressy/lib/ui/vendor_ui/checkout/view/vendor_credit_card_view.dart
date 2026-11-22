import 'package:flutter/material.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/provider/vendor_item_bought/vendor_item_bought_provider.dart';
import '../../common/base/ps_widget_with_appbar_with_no_provider.dart';

class VendorCreditCardView extends StatefulWidget {
  const VendorCreditCardView(
      {Key? key,
      this.vendorItemBoughtProvider,
      this.vendorStripePulicKey,
      this.currencyId,
      this.orderId,
      this.paymentAmount,
      this.userId,
      this.vendorId,
      this.itemId,
      this.isSingleCheckout})
      : super(key: key);

  final VendorItemBoughtProvider? vendorItemBoughtProvider;
  final String? vendorStripePulicKey;
  final String? currencyId;
  final String? orderId;
  final String? paymentAmount;
  final String? userId;
  final String? vendorId;
  final String? itemId;
  final String? isSingleCheckout;

  @override
  State<StatefulWidget> createState() {
    return VendorCreditCardViewState();
  }
}

class VendorCreditCardViewState extends State<VendorCreditCardView> {
  @override
  Widget build(BuildContext context) {
    return PsWidgetWithAppBarWithNoProvider(
      appBarTitle: 'item_promote__credit_card_title'.tr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Text(
            'Ce mode de paiement n\'est pas disponible pour le moment. Veuillez utiliser le paiement à la livraison.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
