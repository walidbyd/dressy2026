import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../config/ps_colors.dart';
import '../../../../../../../../config/route/route_paths.dart';
import '../../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../../../core/vendor/viewobject/holder/intent_holder/item_entry_intent_holder.dart';
import '../../../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../../custom_ui/item/detail/component/sticky_bottom/owner_action/widgets/delete_widget.dart';

class OwnerActionButtonsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ItemDetailProvider provider = Provider.of<ItemDetailProvider>(context);
    final Product product = provider.product;

    if (!product.isSoldOutItem) {
      return CustomDeleteItemWidget();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: PsColors.primary500,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                RoutePaths.itemEntry,
                arguments: ItemEntryIntentHolder(
                  flag: PsConst.ADD_NEW_ITEM,
                  item: product,
                  categoryId: product.catId ?? '',
                  categoryName: product.category?.catName ?? '',
                ),
              );
            },
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: Text(
              'item_detail__sell_again'.tr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomDeleteItemWidget(),
      ],
    );
  }
}
