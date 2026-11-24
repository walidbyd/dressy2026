import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/provider/vendor_application/vendor_item_provider.dart';
import '../../../../../../../core/vendor/provider/vendor_application/vendor_user_detail_provider.dart';
import '../../../../../../../core/vendor/utils/ps_animation.dart';
import '../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../../custom_ui/item/list_item/product_vertical_list_item.dart';
import '../../../../../common/ps_ui_widget.dart';
import '../../../../../common/shimmer_item.dart';
import '../../../../../item/detail/component/info_widgets/vendor_expired_widget.dart';

class OtherUserVendorItemCardWidget extends StatefulWidget {
  const OtherUserVendorItemCardWidget({Key? key, required this.isLoading})
      : super(key: key);
  final bool isLoading;

  @override
  State<OtherUserVendorItemCardWidget> createState() =>
      _OtherUserVendorItemCardWidgetState();
}

class _OtherUserVendorItemCardWidgetState
    extends State<OtherUserVendorItemCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PsValueHolder psValueHolder = Provider.of<PsValueHolder>(context);
    final VendorItemProvider vendorItemProvider =
        Provider.of<VendorItemProvider>(context);
    final VendorUserDetailProvider vendorUserDetailProvider =
        Provider.of<VendorUserDetailProvider>(context);

    final int itemCount = widget.isLoading
        ? (psValueHolder.loadingShimmerItemCount ?? 6)
        : (vendorItemProvider.vendorItemList.data?.length ?? 0);

    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.symmetric(
              horizontal: PsDimens.space10, vertical: PsDimens.space4),
          child: Column(
            children: <Widget>[
              if (vendorUserDetailProvider.vendorUserDetail.data?.expiredStatus ==
                  PsConst.EXPIRED_NOTI)
                VendorExpiredWidget(vendorExpText: 'vendor_expired_text'.tr)
              else
                const SizedBox(),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (BuildContext context, int index) {
                    if (widget.isLoading) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: PsDimens.space4,
                            vertical: PsDimens.space8),
                        child: const ShimmerItem(),
                      );
                    }
                    if (!vendorItemProvider.hasData) {
                      return const SizedBox.shrink();
                    }
                    final Product product =
                        vendorItemProvider.vendorItemList.data?[index] ??
                            Product();
                    return CustomProductVeticalListItem(
                      isLoading: false,
                      coreTagKey: vendorItemProvider.hashCode.toString(),
                      product: product,
                      animation: curveAnimation(_animationController,
                          index: index, count: itemCount),
                      animationController: _animationController,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        PSProgressIndicator(vendorItemProvider.currentStatus),
      ],
    );
  }
}
