import 'package:flutter/material.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/viewobject/ps_app_info.dart';
import '../../../common/base/ps_widget_with_appbar_with_no_provider.dart';

class InAppPurchaseView extends StatefulWidget {
  const InAppPurchaseView(this.itemId, this.appInfo);
  final String? itemId;
  final PSAppInfo? appInfo;
  @override
  _InAppPurchaseViewState createState() => _InAppPurchaseViewState();
}

class _InAppPurchaseViewState extends State<InAppPurchaseView> {
  @override
  Widget build(BuildContext context) {
    return PsWidgetWithAppBarWithNoProvider(
      appBarTitle: 'item_promote__in_app_purchase'.tr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Text(
            'Les achats intégrés Google Play ne sont pas activés pour cette version.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
