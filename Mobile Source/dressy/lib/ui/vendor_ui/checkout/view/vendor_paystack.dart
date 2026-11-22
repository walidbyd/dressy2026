import 'package:flutter/material.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../core/vendor/provider/vendor_item_bought/vendor_item_bought_provider.dart';
import '../../common/base/ps_widget_with_appbar_with_no_provider.dart';

class VendorPayStackView extends StatefulWidget {
  const VendorPayStackView(
      {Key? key,
      this.vendorItemBoughtProvider,
      this.currencyId,
      this.orderId,
      this.amount,
      this.userId,
      this.vendorId,
      this.isSingleCheckout,
      this.vendorPayStackKey,
      this.userProvider,
      this.itemDetailProvider})
      : super(key: key);

  final VendorItemBoughtProvider? vendorItemBoughtProvider;
  final String? vendorId;
  final String? currencyId;
  final String? userId;
  final String? amount;
  final String? vendorPayStackKey;
  final String? orderId;
  final String? isSingleCheckout;
  final UserProvider? userProvider;
  final ItemDetailProvider? itemDetailProvider;

  @override
  State<StatefulWidget> createState() {
    return VendorPayStackViewState();
  }
}

class VendorPayStackViewState extends State<VendorPayStackView> {
  @override
  Widget build(BuildContext context) {
    return PsWidgetWithAppBarWithNoProvider(
      appBarTitle: 'item_promote__paystack_title'.tr,
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
