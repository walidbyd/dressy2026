import 'package:flutter/material.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../common/ps_app_bar_widget.dart';

class PackageShopInAppPurchaseView extends StatefulWidget {
  const PackageShopInAppPurchaseView(
      {required this.androidKeyList, required this.iosKeyList});
  final String? androidKeyList;
  final String? iosKeyList;

  @override
  _PackageShopInAppPurchaseViewState createState() =>
      _PackageShopInAppPurchaseViewState();
}

class _PackageShopInAppPurchaseViewState
    extends State<PackageShopInAppPurchaseView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PsAppbarWidget(
        appBarTitle: 'package__packages'.tr,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Text(
            'Les packs d\'annonces intégrés ne sont pas activés pour cette version.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
