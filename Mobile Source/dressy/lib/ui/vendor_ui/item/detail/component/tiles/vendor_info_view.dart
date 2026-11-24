import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/intent_holder/vendor_user_intent_holder.dart';
import '../../../../common/bluemark_icon.dart';
import '../../../../common/ps_ui_widget.dart';

class VendorInfoView extends StatefulWidget {
  @override
  State<VendorInfoView> createState() => _VendorInfoViewState();
}

class _VendorInfoViewState extends State<VendorInfoView> {
  late UserProvider userProvider;

  @override
  Widget build(BuildContext context) {
    final ItemDetailProvider provider =
        Provider.of<ItemDetailProvider>(context);
    final Product product = provider.product;
    final PsValueHolder psValueHolder = Provider.of<PsValueHolder>(context);

    if (psValueHolder.vendorFeatureSetting != PsConst.ONE ||
            provider.product.vendorUser == null ||
            provider.product.vendorId == '' //item is not from vendor
        ) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverToBoxAdapter(
      child: InkWell(
        onTap: () {
          onSellerInfoClick(context, provider.product);
        },
        child: Container(
          margin: const EdgeInsets.only(
              left: PsDimens.space16,
              right: PsDimens.space16,
              top: PsDimens.space16),
          decoration: BoxDecoration(
            color: Utils.isLightMode(context)
                ? PsColors.text50
                : PsColors.achromatic700,
            borderRadius:
                const BorderRadius.all(Radius.circular(PsDimens.space4)),
          ),
          child: Padding(
              padding: const EdgeInsets.only(
                  top: PsDimens.space16,
                  bottom: PsDimens.space16,
                  left: PsDimens.space16,
                  right: PsDimens.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  //image
                  Stack(
                    children: <Widget>[
                      Container(
                        width: PsDimens.space50,
                        height: PsDimens.space50,
                        child: product.vendorUser?.expiredStatus ==
                                PsConst.EXPIRED_NOTI
                            ? Container(
                                decoration:  BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:PsColors.achromatic900,
                                ),
                                alignment: Alignment.center,
                                width: PsDimens.space40,
                                height: PsDimens.space40,
                                child: Text(
                                  'Closed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(color: PsColors.text50),
                                ),
                              )
                            : PsNetworkCircleImageForUser(
                                photoKey: '',
                                imagePath: product.vendorUser!.logo?.imgPath,
                                boxfit: BoxFit.cover,
                              ),
                      ),
                      if (product.vendorUser!.isVendorUser)
                        const Positioned(
                            right: -1, bottom: -1, child: BluemarkIcon()),
                    ],
                  ),
                  const SizedBox(
                    width: PsDimens.space16,
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Flexible(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4.0, bottom: 4.0),
                                  child: Text(
                                    provider.product.vendorUser!.name == ''
                                        ? 'default__user_name'.tr
                                        : provider.product.vendorUser!.name ??
                                            '',
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(fontSize: 16),
                                  )),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, top: 2.0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF4F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE4A4AB), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 15,
                                      color: Color(0xFF5C1A2B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (provider.product.vendorUser?.overallRating !=
                                                  null &&
                                              provider.product.vendorUser!
                                                  .overallRating!.isNotEmpty &&
                                              provider.product.vendorUser!
                                                      .overallRating !=
                                                  '0' &&
                                              provider.product.vendorUser!
                                                      .overallRating !=
                                                  '0.0')
                                          ? provider
                                              .product.vendorUser!.overallRating!
                                          : '5.0',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5C1A2B),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (int.tryParse(provider.product.vendorUser
                                                      ?.ratingCount ??
                                                  '0') ??
                                              0) >
                                              0
                                          ? '(${provider.product.vendorUser!.ratingCount} avis)'
                                          : '(Nouveau)',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6E6568),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (provider.product.vendorUser!.followerCount !=
                                      null &&
                                  provider.product.vendorUser!.followerCount !=
                                      '0') ...<Widget>[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${provider.product.vendorUser!.followerCount} ${'profile__follower'.tr}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: const Color(0xFF6E6568),
                                          fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              top: PsDimens.space2, right: PsDimens.space4),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(PsDimens.space4),
                              color: PsColors.warning500),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: PsDimens.space4,
                                  vertical: PsDimens.space2),
                              child: Text('vendor'.tr,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(color: PsColors.achromatic50))),
                        ),
                      ],
                    ),
                  ),
                  //)
                ],
              )),
        ),
      ),
    );
  }

  void onSellerInfoClick(BuildContext context, Product product) {
    Navigator.pushNamed(context, RoutePaths.userVendorDetail,
        arguments: VendorUserIntentHolder(
            vendorId: product.vendorUser!.id,
            vendorUserId: product.vendorUser!.ownerUserId,
            vendorUserName: product.vendorUser!.name ?? ''));
  }
}
