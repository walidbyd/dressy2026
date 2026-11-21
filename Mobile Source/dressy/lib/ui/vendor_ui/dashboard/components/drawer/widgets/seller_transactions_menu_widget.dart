import 'package:flutter/material.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';

class SellerTransactionsMenuWidget extends StatelessWidget {
  const SellerTransactionsMenuWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: ListTile(
        leading: Icon(
          Icons.receipt_long_outlined,
          size: 20,
          color: Utils.isLightMode(context)
              ? PsColors.achromatic700
              : PsColors.achromatic100,
        ),
        minLeadingWidth: 0,
        title: Text(
          'seller_sales_transactions_title'.tr,
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.w400, fontSize: 13),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, RoutePaths.sellerTransactions);
        },
      ),
    );
  }
}
