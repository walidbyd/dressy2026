import 'package:flutter/material.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';

class MySalesMenuWidget extends StatelessWidget {
  const MySalesMenuWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Icon(
          Icons.storefront_outlined,
          size: 23,
          color: Utils.isLightMode(context)
              ? PsColors.achromatic800
              : PsColors.achromatic50,
        ),
        minLeadingWidth: 0,
        title: Text(
          'home__menu_drawer_my_sales'.tr,
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.w400),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, RoutePaths.mySales);
        });
  }
}
