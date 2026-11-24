import 'package:flutter/material.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';

class WalletMenuWidget extends StatelessWidget {
  const WalletMenuWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Icon(
          Icons.account_balance_wallet_outlined,
          size: 23,
          color: Utils.isLightMode(context)
              ? PsColors.achromatic800
              : PsColors.achromatic50,
        ),
        minLeadingWidth: 0,
        title: Text(
          'home__menu_drawer_wallet'.tr,
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.w400),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, RoutePaths.wallet);
        });
  }
}
