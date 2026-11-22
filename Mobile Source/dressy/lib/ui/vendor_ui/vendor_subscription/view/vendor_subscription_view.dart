import 'package:flutter/material.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../common/ps_app_bar_widget.dart';

class VendorSubscriptionView extends StatefulWidget {
  const VendorSubscriptionView(
      {Key? key, this.androidKeyList, this.iosKeyList, required this.vendorId})
      : super(key: key);

  final String? androidKeyList;
  final String? iosKeyList;
  final String? vendorId;
  @override
  State<VendorSubscriptionView> createState() => _VendorSubscriptionViewState();
}

class _VendorSubscriptionViewState extends State<VendorSubscriptionView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PsAppbarWidget(
        appBarTitle: 'vendor_subscription__subscription'.tr,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Text(
            'Les abonnements intégrés ne sont pas activés pour cette version.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
