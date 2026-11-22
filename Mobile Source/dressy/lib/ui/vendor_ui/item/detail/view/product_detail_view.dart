import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../config/ps_colors.dart';
import '../../../../../config/route/route_paths.dart';
import '../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../core/vendor/constant/ps_provider_const.dart';
import '../../../../../core/vendor/db/common/ps_data_source_manager.dart';
import '../../../../../core/vendor/provider/add_to_cart/add_to_cart_provider.dart';
import '../../../../../core/vendor/provider/category/category_provider.dart';
import '../../../../../core/vendor/provider/gallery/gallery_provider.dart';
import '../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/provider/order_id/order_id_provider.dart';
import '../../../../../core/vendor/provider/product/favourite_item_provider.dart';
import '../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../core/vendor/provider/product/related_product_provider.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../core/vendor/viewobject/default_photo.dart';
import '../../../../../core/vendor/viewobject/holder/billing_address_holder.dart';
import '../../../../../core/vendor/viewobject/holder/favourite_parameter_holder.dart';
import '../../../../../core/vendor/viewobject/holder/intent_holder/user_intent_holder.dart';
import '../../../../../core/vendor/viewobject/holder/intent_holder/vendor_user_intent_holder.dart';
import '../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../core/vendor/viewobject/holder/shipping_address_holder.dart';
import '../../../../../core/vendor/viewobject/holder/widget_provider_dyanmic.dart';
import '../../../../../core/vendor/viewobject/product.dart';
import '../../../../../core/vendor/viewobject/shopping_cart_item.dart';
import '../../../../custom_ui/item/detail/component/sticky_bottom/owner_action/owner_actions_widget.dart';
import '../../../../custom_ui/item/related_item/component/horizontal/related_product_list_widget.dart';
import '../../../common/bluemark_icon.dart';
import '../../../common/dialog/check_item_dialog.dart';
import '../../../common/ps_ui_widget.dart';
import '../../../sort_widget/ps_dynamic_provider.dart';

class ProductDetailView extends StatefulWidget {
  const ProductDetailView(
      {required this.productId,
      required this.heroTagImage,
      required this.heroTagTitle});

  final String? productId;
  final String? heroTagImage;
  final String? heroTagTitle;

  @override
  ProductDetailState<ProductDetailView> createState() =>
      ProductDetailState<ProductDetailView>();
}

class ProductDetailState<T extends ProductDetailView>
    extends State<ProductDetailView> with SingleTickerProviderStateMixin {
  RelatedProductProvider? relatedProductProvider;
  PsValueHolder? psValueHolder;
  AnimationController? animationController;
  final ScrollController scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  AddToCartProvider? addToCartProvider;

  bool isFirstTime = true;
  WidgetProviderDynamic? widgetProviderDynamic = WidgetProviderDynamic(
      providerList: <String>[''], widgetList: <String>['']);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    animationController?.dispose();
    _pageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String _getCondition(Product product) {
    for (final String key in <String>['ps-itm00004', 'itm00004']) {
      final String val = product.selectedValuesOfProductRelation(key).trim();
      if (val.isNotEmpty) {
        return val;
      }
    }
    return '';
  }

  String _getSize(Product product) {
    for (final String sizeKey in <String>[
      'itm00037',
      'ps-itm00037',
      'itm00033',
      'ps-itm00033',
    ]) {
      final String val =
          product.selectedValuesOfProductRelation(sizeKey).trim();
      if (val.isNotEmpty) {
        return val;
      }
    }
    return '';
  }

  String _getBrand(Product product) {
    for (final String brandKey in <String>[
      'ps-itm00001',
      'itm00039',
      'ps-itm00002',
      'ps-itm00003',
      'ps-itm00005',
    ]) {
      final String val =
          product.selectedValuesOfProductRelation(brandKey).trim();
      if (val.isNotEmpty) {
        return val;
      }
    }
    return '';
  }

  String _getDisplayPrice(Product product, PsValueHolder valueHolder) {
    final bool isLoginUserEmpty = Utils.isLoginUserEmpty(valueHolder);
    if (valueHolder.hidePriceSetting == PsConst.ONE && isLoginUserEmpty) {
      return '*****';
    }
    final String? price = (product.isDiscountedItem == true &&
            product.currentPrice != null &&
            product.currentPrice != '')
        ? product.currentPrice
        : product.originalPrice;
    if (price == null || price == '' || price == '0') {
      return 'item_price_free'.tr;
    }
    final String formattedPrice =
        Utils.getPriceFormat(price, valueHolder.priceFormat!);
    final String symbol = (product.itemCurrency?.currencySymbol != null &&
            product.itemCurrency!.currencySymbol!.isNotEmpty)
        ? product.itemCurrency!.currencySymbol!
        : 'DA';
    return '$formattedPrice $symbol';
  }

  void _onCommanderToutDeSuite(
      BuildContext context,
      Product product,
      ItemDetailProvider itemDetailProvider,
      OrderIdProvider orderIdProvider,
      PsValueHolder psValueHolder) {
    if (Utils.isLoginUserEmpty(psValueHolder)) {
      Navigator.pushNamed(context, RoutePaths.login_container);
      return;
    }

    orderIdProvider.count = 1;
    final String currencyId =
        itemDetailProvider.itemDetail.data?.vendorUser?.currencyId ?? '';
    if (currencyId == '' &&
        product.vendorId.isNotEmpty &&
        product.vendorId != '0') {
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return CheckOutDialog(
              title: 'vendor_set_default_currency'.tr,
              message: 'vendor_set_default_currency_description'.tr,
            );
          });
      return;
    }

    Utils.navigateOnUserVerificationView(context, () {
      final String discountPrice = (product.isDiscountedItem == true &&
              product.currentPrice != null &&
              product.currentPrice != '')
          ? product.currentPrice!
          : (product.originalPrice ?? '0');
      final String subTotal =
          (double.parse(discountPrice) * orderIdProvider.count)
              .toStringAsFixed(0);

      final List<ShoppingCartItem> shoppingCartItemList = <ShoppingCartItem>[
        ShoppingCartItem(
          availableQuantity: '1',
          defaultPhoto: product.defaultPhoto,
          discountPrice: discountPrice,
          isSoldOut: '0',
          itemId: product.id,
          itemName: product.title,
          originalPrice: product.originalPrice,
          quantity: '1',
          salePrice: product.currentPrice,
          vendorCurrencySymbol:
              product.itemCurrency?.currencySymbol ?? 'DA',
          subTotal: subTotal,
        )
      ];

      Navigator.pushNamed(context, RoutePaths.checkout, arguments: <String, dynamic>{
        'vendorId': product.vendorId,
        'checkoutItemList': shoppingCartItemList,
        'isSingleItemCheckout': true,
      });
    });
  }

  Widget _buildBottomCTA(
      BuildContext context,
      Product product,
      ItemDetailProvider itemDetailProvider,
      OrderIdProvider orderIdProvider,
      PsValueHolder psValueHolder) {
    final bool isOwner = Utils.isOwnerItem(psValueHolder, product);
    final bool isSoldOut = product.isSoldOutItem;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context) ? Colors.white : PsColors.achromatic900,
        border: Border(
          top: BorderSide(
            color: Utils.isLightMode(context)
                ? PsColors.achromatic100
                : PsColors.achromatic700,
            width: 1,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isOwner
            ? CustomOwnerActionButtonsWidget()
            : isSoldOut
                ? Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Cet article a été vendu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED7768),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        _onCommanderToutDeSuite(
                          context,
                          product,
                          itemDetailProvider,
                          orderIdProvider,
                          psValueHolder,
                        );
                      },
                      child: Text(
                        'order_now'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final OrderIdProvider orderIdProvider =
        Provider.of<OrderIdProvider>(context);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);
    psValueHolder = Provider.of<PsValueHolder>(context);
    final bool isLight = Utils.isLightMode(context);
    animationController!.forward();

    if (isFirstTime) {
      widgetProviderDynamic!.providerList!.addAll(<String>[
        PsProviderConst.init_item_detail_provider,
        PsProviderConst.init_user_provider,
        PsProviderConst.init_history_provider,
        PsProviderConst.init_appinfo_provider,
        PsProviderConst.init_mark_soldout_item_provider,
        PsProviderConst.init_touch_count_provider,
        PsProviderConst.init_about_us_provider,
        PsProviderConst.init_favourite_item_provider,
        PsProviderConst.init_gallery_provider,
      ]);
      isFirstTime = false;
    }

    widgetProviderDynamic!.providerList =
        widgetProviderDynamic!.providerList!.toSet().toList();

    Future<bool> _requestPop() {
      animationController!.reverse().then<dynamic>(
        (void data) {
          if (!mounted) {
            return Future<bool>.value(false);
          }
          Navigator.pop(context, true);
          return Future<bool>.value(true);
        },
      );
      return Future<bool>.value(false);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? dynamic) async {
        if (didPop) {
          return;
        }
        _requestPop();
      },
      child: Scaffold(
        backgroundColor: isLight ? Colors.white : PsColors.achromatic900,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: isLight ? Colors.white : PsColors.achromatic900,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isLight ? const Color(0xFF1F2937) : Colors.white,
            ),
            onPressed: () {
              orderIdProvider.count = 1;
              orderIdProvider.shippingAddressHolder = ShippingAddressHolder();
              orderIdProvider.billingAddressHolder = BillingAddressHolder();
              Navigator.pop(context, true);
            },
          ),
          title: Text(
            'product_detail__title'.tr,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: isLight ? const Color(0xFF1F2937) : Colors.white,
            ),
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.share_outlined,
                size: 22,
                color: isLight ? const Color(0xFF1F2937) : Colors.white,
              ),
              onPressed: () {
                final String shareUrl =
                    'https://dressy-dz.com/item/${widget.productId}';
                SharePlus.instance.share(
                  ShareParams(
                    text: 'Découvrez cet article sur Dressy !\n$shareUrl',
                  ),
                );
              },
            ),
          ],
        ),
        body: MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<AddToCartProvider>(
                lazy: false,
                create: (BuildContext context) {
                  addToCartProvider = AddToCartProvider(context: context);
                  addToCartProvider?.loadData(
                      dataConfig: DataConfiguration(
                          dataSourceType: DataSourceType.SERVER_DIRECT),
                      requestPathHolder: RequestPathHolder(
                          isCheckoutPage: PsConst.ZERO,
                          loginUserId: psValueHolder?.loginUserId ?? '',
                          languageCode: psValueHolder?.languageCode ?? ''));
                  return addToCartProvider!;
                }),
            ...psDynamicProvider(context, (Function fn) {},
                productId: widget.productId,
                categoryProvider: (CategoryProvider pro) {},
                providerList: widgetProviderDynamic!.providerList!)
          ],
          child: Consumer3<ItemDetailProvider, FavouriteItemProvider,
              GalleryProvider>(
            builder: (BuildContext context,
                ItemDetailProvider provider,
                FavouriteItemProvider favProvider,
                GalleryProvider galleryProvider,
                Widget? child) {
              if (!provider.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFED7768)),
                  ),
                );
              }

              final Product product = provider.product;
              final bool isFav = product.isFavorite;

              // Collect image list
              final List<String> imageList = <String>[];
              if (product.defaultPhoto?.imgPath != null &&
                  product.defaultPhoto!.imgPath!.isNotEmpty) {
                imageList.add(product.defaultPhoto!.imgPath!);
              }
              if (galleryProvider.galleryList.data != null) {
                for (final DefaultPhoto p in galleryProvider.galleryList.data!) {
                  if (p.imgPath != null &&
                      p.imgPath!.isNotEmpty &&
                      !imageList.contains(p.imgPath)) {
                    imageList.add(p.imgPath!);
                  }
                }
              }

              // Seller info
              final String? sellerAvatar =
                  (product.vendorUser?.logo?.imgPath != null &&
                          product.vendorUser!.logo!.imgPath!.isNotEmpty)
                      ? product.vendorUser!.logo!.imgPath
                      : product.user?.userCoverPhoto;
              final String sellerName = (product.vendorUser?.name != null &&
                      product.vendorUser!.name!.isNotEmpty)
                  ? product.vendorUser!.name!
                  : (product.user?.userName ?? 'Vendeur Dressy');
              final bool isVerified =
                  product.user?.isVerifyBlueMark == '1' ||
                      product.user?.isVefifiedBlueMarkUser == true;
              final String sellerCity = product.itemLocation?.name ??
                  product.user?.userAddress ??
                  '';
              final double? rating =
                  double.tryParse(product.user?.overallRating ?? '');
              final int reviewCount =
                  int.tryParse(product.user?.ratingCount ?? '0') ?? 0;

              // Dynamic attributes
              final String condition = _getCondition(product);
              final String size = _getSize(product);
              final String brand = _getBrand(product);

              return Stack(
                children: <Widget>[
                  CustomScrollView(
                    controller: scrollController,
                    slivers: <Widget>[
                      // Hero Carousel & Dots
                      SliverToBoxAdapter(
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: 380,
                              width: double.infinity,
                              child: Stack(
                                children: <Widget>[
                                  if (imageList.isNotEmpty)
                                    PageView.builder(
                                      controller: _pageController,
                                      itemCount: imageList.length,
                                      onPageChanged: (int index) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context,
                                                RoutePaths.galleryGrid,
                                                arguments: product);
                                          },
                                          child: PsNetworkImageWithUrl(
                                            photoKey: '',
                                            width: double.infinity,
                                            height: 380,
                                            imageAspectRation:
                                                PsConst.Aspect_Ratio_1x,
                                            imagePath: imageList[index],
                                            boxfit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Container(
                                      color: isLight
                                          ? const Color(0xFFF3F4F6)
                                          : PsColors.achromatic800,
                                      child: const Center(
                                        child: Icon(Icons.image,
                                            size: 64, color: Colors.grey),
                                      ),
                                    ),
                                  // Floating Favorite button on Hero
                                  if (!Utils.isOwnerItem(
                                      psValueHolder!, product))
                                    Positioned(
                                      top: 14,
                                      right: 14,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (Utils.isLoginUserEmpty(
                                              psValueHolder!)) {
                                            Navigator.pushNamed(context,
                                                RoutePaths.login_container);
                                            return;
                                          }
                                          setState(() {
                                            product.isFavourited =
                                                isFav ? '0' : '1';
                                          });
                                          final FavouriteParameterHolder
                                              holder =
                                              FavouriteParameterHolder(
                                            userId: psValueHolder!.loginUserId,
                                            itemId: product.id,
                                          );
                                          final PsResource<Product> res =
                                              await favProvider.postFavourite(
                                            holder.toMap(),
                                            psValueHolder!.loginUserId!,
                                            psValueHolder!.headerToken!,
                                            langProvider
                                                .currentLocale.languageCode,
                                          );
                                          if (res.status != PsStatus.SUCCESS) {
                                            setState(() {
                                              product.isFavourited =
                                                  isFav ? '1' : '0';
                                            });
                                          }
                                        },
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.92),
                                            shape: BoxShape.circle,
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              isFav
                                                  ? Icons.favorite_rounded
                                                  : Icons.favorite_border_rounded,
                                              color: isFav
                                                  ? const Color(0xFFED7768)
                                                  : const Color(0xFF374151),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Dots Indicator
                                  if (imageList.length > 1)
                                    Positioned(
                                      bottom: 12,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List<Widget>.generate(
                                            imageList.length, (int index) {
                                          final bool isActive =
                                              _currentImageIndex == index;
                                          return AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3),
                                            width: isActive ? 18 : 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? const Color(0xFFED7768)
                                                  : Colors.white
                                                      .withValues(alpha: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content details
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Title & Price Header
                              Text(
                                product.title ?? '',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isLight
                                      ? const Color(0xFF1F2937)
                                      : PsColors.achromatic50,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getDisplayPrice(product, psValueHolder!),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFED7768),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Seller / Vendor Row
                              InkWell(
                                onTap: () {
                                  if (product.vendorId.isNotEmpty &&
                                      product.vendorId != '0') {
                                    Navigator.pushNamed(
                                      context,
                                      RoutePaths.userVendorDetail,
                                      arguments: VendorUserIntentHolder(
                                        vendorId: product.vendorId,
                                        vendorUserName: sellerName,
                                        vendorUserId: product.vendorUser?.id,
                                      ),
                                    );
                                  } else {
                                    Navigator.pushNamed(
                                      context,
                                      RoutePaths.userDetail,
                                      arguments: UserIntentHolder(
                                        userId: product.addedUserId ?? '',
                                        userName: sellerName,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: isLight
                                        ? const Color(0xFFF9FAFB)
                                        : PsColors.achromatic800,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isLight
                                          ? const Color(0xFFE5E7EB)
                                          : PsColors.achromatic700,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      // Seller circular avatar
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isLight
                                                ? const Color(0xFFE5E7EB)
                                                : PsColors.achromatic600,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: (sellerAvatar != null &&
                                                  sellerAvatar.isNotEmpty)
                                              ? PsNetworkCircleImageForUser(
                                                  photoKey: '',
                                                  imagePath: sellerAvatar,
                                                  boxfit: BoxFit.cover,
                                                  onTap: () {},
                                                )
                                              : CircleAvatar(
                                                  backgroundColor:
                                                      const Color(0xFFFDEEEB),
                                                  child: Text(
                                                    sellerName.isNotEmpty
                                                        ? sellerName[0]
                                                            .toUpperCase()
                                                        : 'D',
                                                    style: const TextStyle(
                                                      color: Color(0xFFED7768),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Seller name & city
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Flexible(
                                                  child: Text(
                                                    sellerName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isLight
                                                          ? const Color(
                                                              0xFF1F2937)
                                                          : PsColors
                                                              .achromatic50,
                                                    ),
                                                  ),
                                                ),
                                                if (isVerified) ...<Widget>[
                                                  const SizedBox(width: 4),
                                                  const BluemarkIcon(),
                                                ],
                                              ],
                                            ),
                                            if (sellerCity.isNotEmpty) ...<Widget>[
                                              const SizedBox(height: 2),
                                              Text(
                                                sellerCity,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: PsColors.text500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Rating or New Seller
                                      if (rating != null &&
                                          rating > 0 &&
                                          reviewCount > 0)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Icon(Icons.star_rounded,
                                                size: 17,
                                                color: Color(0xFFFFB800)),
                                            const SizedBox(width: 3),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isLight
                                                    ? const Color(0xFF1F2937)
                                                    : PsColors.achromatic50,
                                              ),
                                            ),
                                            Text(
                                              ' ($reviewCount)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: PsColors.text400,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: isLight
                                                ? const Color(0xFFF3F4F6)
                                                : const Color(0xFF374151),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'new_seller'.tr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PsColors.text600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Attribute Pills
                              if (condition.isNotEmpty ||
                                  size.isNotEmpty ||
                                  brand.isNotEmpty) ...<Widget>[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    if (condition.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isLight
                                              ? const Color(0xFFF5F5F7)
                                              : PsColors.achromatic800,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isLight
                                                ? const Color(0xFFE5E7EB)
                                                : PsColors.achromatic700,
                                          ),
                                        ),
                                        child: Text(
                                          '${'condition'.tr} : $condition',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: isLight
                                                ? const Color(0xFF374151)
                                                : PsColors.achromatic100,
                                          ),
                                        ),
                                      ),
                                    if (size.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isLight
                                              ? const Color(0xFFF5F5F7)
                                              : PsColors.achromatic800,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isLight
                                                ? const Color(0xFFE5E7EB)
                                                : PsColors.achromatic700,
                                          ),
                                        ),
                                        child: Text(
                                          '${'size'.tr} : $size',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: isLight
                                                ? const Color(0xFF374151)
                                                : PsColors.achromatic100,
                                          ),
                                        ),
                                      ),
                                    if (brand.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isLight
                                              ? const Color(0xFFF5F5F7)
                                              : PsColors.achromatic800,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isLight
                                                ? const Color(0xFFE5E7EB)
                                                : PsColors.achromatic700,
                                          ),
                                        ),
                                        child: Text(
                                          '${'brand'.tr} : $brand',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: isLight
                                                ? const Color(0xFF374151)
                                                : PsColors.achromatic100,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Location pin line
                              if (product.itemLocation?.name != null &&
                                  product.itemLocation!.name!.isNotEmpty) ...<Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: PsColors.text400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.itemLocation!.name!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: PsColors.text600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Description
                              if (product.description != null &&
                                  product.description!.isNotEmpty) ...<Widget>[
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isLight
                                        ? const Color(0xFF1F2937)
                                        : PsColors.achromatic50,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isLight
                                        ? const Color(0xFF4B5563)
                                        : PsColors.text200,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Yalidine Delivery Line
                              const Divider(height: 24, thickness: 1),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFDEEEB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_outlined,
                                      color: Color(0xFFED7768),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'yalidine_delivery_text'.tr,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isLight
                                            ? const Color(0xFF1F2937)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // Related Products
                      CustomRelatedProductListWidget(),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),

                  // Bottom Sticky CTA Button
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomCTA(
                      context,
                      product,
                      provider,
                      orderIdProvider,
                      psValueHolder!,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
