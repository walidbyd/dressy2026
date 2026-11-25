import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/repository/product_repository.dart';
import '../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../core/vendor/viewobject/holder/favourite_parameter_holder.dart';
import '../../../../../../../core/vendor/viewobject/holder/intent_holder/product_detail_intent_holder.dart';
import '../../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../common/ps_ui_widget.dart';
import '../../common/shimmer_item.dart';

class ProductVerticalListItemForFilter extends StatefulWidget {
  const ProductVerticalListItemForFilter(
      {Key? key,
      required this.product,
      this.onTap,
      this.coreTagKey,
      required this.animationController,
      required this.animation,
      this.isLoading = false})
      : super(key: key);

  final Product product;
  final Function? onTap;
  final AnimationController animationController;
  final Animation<double> animation;
  final String? coreTagKey;
  final bool isLoading;

  @override
  State<ProductVerticalListItemForFilter> createState() =>
      _ProductVerticalListItemForFilterState();
}

class _ProductVerticalListItemForFilterState
    extends State<ProductVerticalListItemForFilter> {
  Widget _buildSellerAvatar(BuildContext context) {
    final String? sellerAvatar = (widget.product.vendorUser?.logo?.imgPath != null &&
            widget.product.vendorUser!.logo!.imgPath!.isNotEmpty)
        ? widget.product.vendorUser!.logo!.imgPath
        : widget.product.user?.userCoverPhoto;
    final String sellerName = (widget.product.vendorUser?.name != null &&
            widget.product.vendorUser!.name!.isNotEmpty)
        ? widget.product.vendorUser!.name!
        : (widget.product.user?.userName ?? '');

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Utils.isLightMode(context)
              ? const Color(0xFFE5E7EB)
              : PsColors.achromatic600,
          width: 1,
        ),
      ),
      child: ClipOval(
        child: (sellerAvatar != null && sellerAvatar.isNotEmpty)
            ? PsNetworkCircleImageForUser(
                photoKey: '',
                imagePath: sellerAvatar,
                boxfit: BoxFit.cover,
                onTap: () {},
              )
            : CircleAvatar(
                backgroundColor: const Color(0xFFFDEEEB),
                child: Text(
                  sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFED7768),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.animationController.forward();
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
            opacity: widget.animation,
            child: Transform(
                transform: Matrix4.translationValues(
                    0.0, 100 * (1.0 - widget.animation.value), 0.0),
                child: child));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: PsDimens.space4, vertical: PsDimens.space4),
        child: widget.isLoading
            ? const ShimmerItem()
            : GestureDetector(
                onTap: () {
                  onDetailClick(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Utils.isLightMode(context)
                        ? Colors.white
                        : PsColors.achromatic800,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                      color: Utils.isLightMode(context)
                          ? PsColors.cardBorderColor
                          : PsColors.achromatic700,
                      width: 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Product Photo: Rounded corners, crisp BoxFit.cover
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                              child: PsNetworkImage(
                                photoKey:
                                    '${widget.coreTagKey}${widget.product.id}${PsConst.HERO_TAG__IMAGE}',
                                defaultPhoto: widget.product.defaultPhoto,
                                boxfit: BoxFit.cover,
                                imageAspectRation: PsConst.Aspect_Ratio_3x,
                                onTap: () {
                                  onDetailClick(context);
                                },
                              ),
                            ),
                            if (widget.product.isSoldOut == '1')
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14)),
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.2),
                                ),
                              ),
                            // "Vendu" badge top-left
                            if (widget.product.isSoldOut == '1')
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F2937)
                                        .withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.check_circle,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3.5),
                                      Text(
                                        'Vendu',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (widget.product.isSponsoredItem)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F1635)
                                        .withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFFFD166), width: 1),
                                  ),
                                  child: Text(
                                    'ads__sponsored_badge'.tr,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD166),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            // Floating circular frosted favourite heart button top-right inside photo
                            if (!Utils.isOwnerItem(valueHolder, widget.product))
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    _toggleFavorite(context, valueHolder);
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      shape: BoxShape.circle,
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        widget.product.isFavourited ==
                                                    PsConst.ZERO ||
                                                Utils.isLoginUserEmpty(
                                                    valueHolder)
                                            ? Icons.favorite_border_rounded
                                            : Icons.favorite_rounded,
                                        color: widget.product.isFavourited ==
                                                    PsConst.ZERO ||
                                                Utils.isLoginUserEmpty(
                                                    valueHolder)
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFED7768),
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Footer: Exactly 2 lines, NO title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Line 1: Bold price on left + seller avatar (22x22 px) on right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _getDisplayPrice(valueHolder),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Utils.isLightMode(context)
                                          ? const Color(0xFF1F2937)
                                          : PsColors.achromatic50,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildSellerAvatar(context),
                              ],
                            ),
                            const SizedBox(height: 3.5),
                            // Line 2: Size value on left + Brand name on right in clean muted text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    _getSize().isNotEmpty
                                        ? _getSize()
                                        : 'Taille Unique',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Utils.isLightMode(context)
                                          ? PsColors.text600
                                          : PsColors.text300,
                                    ),
                                  ),
                                ),
                                if (_getBrand().isNotEmpty) ...<Widget>[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _getBrand(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Utils.isLightMode(context)
                                            ? PsColors.text400
                                            : PsColors.text500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _toggleFavorite(
      BuildContext context, PsValueHolder valueHolder) async {
    if (Utils.isLoginUserEmpty(valueHolder)) {
      Navigator.pushNamed(context, RoutePaths.login_container);
      return;
    }
    if (await Utils.checkInternetConnectivity()) {
      final ProductRepository repo =
          Provider.of<ProductRepository>(context, listen: false);
      final AppLocalization langProvider =
          Provider.of<AppLocalization>(context, listen: false);
      final String loginUserId = valueHolder.loginUserId ?? '';
      final bool wasFav = widget.product.isFavourited == '1';
      setState(() {
        widget.product.isFavourited = wasFav ? '0' : '1';
      });
      final FavouriteParameterHolder holder = FavouriteParameterHolder(
        userId: loginUserId,
        itemId: widget.product.id,
      );
      final PsResource<Product> res = await repo.postFavourite(
        holder.toMap(),
        true,
        PsStatus.PROGRESS_LOADING,
        loginUserId,
        valueHolder.headerToken ?? '',
        langProvider.currentLocale.languageCode,
      );
      if (res.status != PsStatus.SUCCESS) {
        setState(() {
          widget.product.isFavourited = wasFav ? '1' : '0';
        });
      }
    }
  }

  String _getDisplayPrice(PsValueHolder valueHolder) {
    final bool isLoginUserEmpty = Utils.isLoginUserEmpty(valueHolder);
    if (valueHolder.hidePriceSetting == PsConst.ONE && isLoginUserEmpty) {
      return '*****';
    }
    final String? price = (widget.product.isDiscountedItem == true &&
            widget.product.currentPrice != null &&
            widget.product.currentPrice != '')
        ? widget.product.currentPrice
        : widget.product.originalPrice;
    if (price == null || price == '' || price == '0') {
      return 'item_price_free'.tr;
    }
    final String formattedPrice =
        Utils.getPriceFormat(price, valueHolder.priceFormat!);
    final String symbol = (widget.product.itemCurrency?.currencySymbol != null &&
            widget.product.itemCurrency!.currencySymbol!.isNotEmpty)
        ? widget.product.itemCurrency!.currencySymbol!
        : 'DA';
    return '$formattedPrice $symbol';
  }

  String _getSize() {
    for (final String sizeKey in <String>[
      'itm00037',
      'ps-itm00037',
      'itm00033',
      'ps-itm00033',
    ]) {
      final String val =
          widget.product.selectedValuesOfProductRelation(sizeKey).trim();
      if (val.isNotEmpty) {
        return val;
      }
    }
    return '';
  }

  String _getBrand() {
    for (final String brandKey in <String>[
      'ps-itm00001',
      'itm00039',
      'ps-itm00002',
      'ps-itm00003',
      'ps-itm00005',
    ]) {
      final String val =
          widget.product.selectedValuesOfProductRelation(brandKey).trim();
      if (val.isNotEmpty) {
        return val;
      }
    }
    return '';
  }

  Future<void> onDetailClick(BuildContext context) async {
    if (!widget.isLoading) {
      final ProductDetailIntentHolder holder = ProductDetailIntentHolder(
          productId: widget.product.id,
          heroTagImage:
              widget.coreTagKey! + widget.product.id! + PsConst.HERO_TAG__IMAGE,
          heroTagTitle: widget.coreTagKey! +
              widget.product.id! +
              PsConst.HERO_TAG__TITLE);
      final dynamic result = await Navigator.pushNamed(
          context, RoutePaths.productDetail,
          arguments: holder);
      if (result == true && widget.onTap != null) {
        widget.onTap!();
      }
    } else if (widget.onTap != null) {
      widget.onTap!();
    }
  }
}
