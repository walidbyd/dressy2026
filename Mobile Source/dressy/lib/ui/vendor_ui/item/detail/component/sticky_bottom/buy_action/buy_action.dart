import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../config/ps_colors.dart';
import '../../../../../../../config/route/route_paths.dart';
import '../../../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../core/vendor/provider/add_to_cart/add_to_cart_provider.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/provider/order_id/order_id_provider.dart';
import '../../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../../core/vendor/utils/ps_progress_dialog.dart';
import '../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../core/vendor/viewobject/api_status.dart';
import '../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../core/vendor/viewobject/holder/add_to_cart_parameter_holder.dart';
import '../../../../../../../core/vendor/viewobject/holder/intent_holder/chat_history_intent_holder.dart';
import '../../../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../../../core/vendor/viewobject/product_relation.dart';
import '../../../../../../../core/vendor/viewobject/shopping_cart_item.dart';
import '../../../../../../custom_ui/item/detail/component/sticky_bottom/buy_action/widgets/detail_summary.dart';
import '../../../../../common/dialog/check_item_dialog.dart';
import '../../../../../common/dialog/error_dialog.dart';
import '../../../../../common/ps_button_widget_with_round_corner.dart';
import 'widgets/buy_button_widget.dart';
import 'widgets/quantity_widget.dart';

class BuyAction extends StatefulWidget {
  const BuyAction({
    Key? key,
  }) : super(key: key);

  @override
  State<BuyAction> createState() => _BuyActionState();
}

class _BuyActionState extends State<BuyAction> {
  late ItemDetailProvider itemDetailProvider;
  late OrderIdProvider orderIdProvider;
  late AddToCartProvider addToCartProvider;

  late PsValueHolder psValueHolder;
  bool isDifferentSeller = false;

  bool _checkIsDifferentSeller(Product product, List<ShoppingCartItem> cartItems, String? cartVendorId) {
    final String currentItemVendorId = product.vendorId;
    final String currentItemSellerId = product.addedUserId ?? '';

    if (cartItems.isEmpty) {
      return false;
    }

    if (cartVendorId != null &&
        cartVendorId.isNotEmpty &&
        cartVendorId != '0' &&
        currentItemVendorId.isNotEmpty &&
        currentItemVendorId != '0') {
      if (cartVendorId != currentItemVendorId) {
        return true;
      }
    }

    for (final ShoppingCartItem cartItem in cartItems) {
      if (cartItem.vendorId != null &&
          cartItem.vendorId!.isNotEmpty &&
          cartItem.vendorId != '0' &&
          currentItemVendorId.isNotEmpty &&
          currentItemVendorId != '0') {
        if (cartItem.vendorId != currentItemVendorId) {
          return true;
        }
      }
      if (cartItem.addedUserId != null &&
          cartItem.addedUserId!.isNotEmpty &&
          currentItemSellerId.isNotEmpty) {
        if (cartItem.addedUserId != currentItemSellerId) {
          return true;
        }
      }
    }
    return false;
  }
  @override
  Widget build(BuildContext context) {
    psValueHolder = Provider.of<PsValueHolder>(context, listen: false);
    orderIdProvider = Provider.of<OrderIdProvider>(context);
    itemDetailProvider = Provider.of<ItemDetailProvider>(context);
    addToCartProvider = Provider.of<AddToCartProvider>(context);

    final String currencyId =
        itemDetailProvider.itemDetail.data?.vendorUser?.currencyId ?? '';

    itemDetailProvider.product.productRelation?.forEach(
      (ProductRelation element) {
        if (element.coreKeyId == 'ps-itm00046' ||
            element.coreKeyId == 'itm00046' ||
            element.coreKeyId == 'ps-itm00010' ||
            element.coreKeyId == 'itm00010') {
          final String rawVal = (element.selectedValues != null && element.selectedValues!.isNotEmpty)
              ? element.selectedValues![0].value?.toString() ?? element.value ?? '0'
              : element.value ?? '0';
          itemDetailProvider.quantity = int.tryParse(rawVal) ?? 0;
        }
      },
    );

    final Product product = itemDetailProvider.product;
    final List<ShoppingCartItem> cartItems =
        addToCartProvider.availableShoppingCartList;
    final String? cartVendorId = addToCartProvider.shoppingCart.data?.vendorId;

    isDifferentSeller = _checkIsDifferentSeller(product, cartItems, cartVendorId);
    final bool isSoldOut = itemDetailProvider.product.isSoldOutItem;

    return IgnorePointer(
      ignoring: isSoldOut ||
          itemDetailProvider.product.vendorUser?.expiredStatus ==
              PsConst.EXPIRED_NOTI ||
          itemDetailProvider.quantity == null,
      child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: PsDimens.space16, vertical: PsDimens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isSoldOut) ...<Widget>[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.remove_shopping_cart, size: 18, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Text(
                        'Cet article a été vendu',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isSoldOut && isDifferentSeller) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, size: 14, color: PsColors.primary500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'cart_single_vendor_restriction'.tr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: PsColors.primary500,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                      child: PSButtonWidgetRoundCorner(
                    titleText: isSoldOut
                        ? 'Cet article a été vendu'
                        : 'product_buy_now'.tr,
                    colorData: isSoldOut ||
                            itemDetailProvider.product.vendorUser?.expiredStatus ==
                                PsConst.EXPIRED_NOTI ||
                            itemDetailProvider.quantity == null
                        ? Utils.isLightMode(context)
                            ? PsColors.achromatic100
                            : PsColors.achromatic700
                        : isDifferentSeller
                            ? PsColors.primary500
                            : Utils.isLightMode(context)
                                ? PsColors.achromatic100
                                : PsColors.achromatic700,
                    titleTextColor: isSoldOut ||
                            itemDetailProvider.product.vendorUser?.expiredStatus ==
                                PsConst.EXPIRED_NOTI ||
                            itemDetailProvider.quantity == null
                        ? PsColors.achromatic400
                        : isDifferentSeller
                            ? PsColors.achromatic50
                            : Utils.isLightMode(context)
                                ? PsColors.achromatic800
                                : PsColors.achromatic50,
                    onPressed: () {
                      orderIdProvider.count = 1;
                      if (currencyId == '') {
                        showDialog<dynamic>(
                            context: context,
                            builder: (BuildContext context) {
                              return CheckOutDialog(
                                title: 'vendor_set_default_currency'.tr,
                                message:
                                    'vendor_set_default_currency_description'.tr,
                              );
                            });
                      } else {
                        Utils.navigateOnUserVerificationView(context, () {
                          _showBottomSheet(context, true);
                        });
                      }
                    },
                  )),
                  if (!isDifferentSeller) ...<Widget>[
                    const SizedBox(width: PsDimens.space8),
                    Expanded(
                        child: PSButtonWidgetRoundCorner(
                      titleText: 'add_to_cart'.tr,
                      colorData: itemDetailProvider.product.isSoldOutItem ||
                              itemDetailProvider.product.vendorUser?.expiredStatus ==
                                  PsConst.EXPIRED_NOTI ||
                              itemDetailProvider.quantity == null
                          ? Utils.isLightMode(context)
                              ? PsColors.achromatic100
                              : PsColors.achromatic700
                          : PsColors.primary500,
                      titleTextColor: itemDetailProvider.product.isSoldOutItem ||
                              itemDetailProvider.product.vendorUser?.expiredStatus ==
                                  PsConst.EXPIRED_NOTI ||
                              itemDetailProvider.quantity == null
                          ? PsColors.achromatic400
                          : PsColors.achromatic50,
                      onPressed: () {
                        orderIdProvider.count = 1;
                        if (currencyId == '') {
                          showDialog<dynamic>(
                              context: context,
                              builder: (BuildContext context) {
                                return CheckOutDialog(
                                  title: 'vendor_set_default_currency'.tr,
                                  message:
                                      'vendor_set_default_currency_description'.tr,
                                );
                              });
                        } else {
                          Utils.navigateOnUserVerificationView(context, () {
                            _showBottomSheet(context, false);
                          });
                        }
                      },
                    )),
                  ],
                ],
              ),
            ],
          )),
    );
  }

  Future<void> onChatClick() async {
    if (await Utils.checkInternetConnectivity()) {
      Utils.navigateOnUserVerificationView(context, () async {
        Navigator.pushNamed(context, RoutePaths.chatView,
            arguments: ChatHistoryIntentHolder(
              chatFlag: PsConst.CHAT_FROM_SELLER,
              itemId: itemDetailProvider.product.id,
              buyerUserId: psValueHolder.loginUserId,
              sellerUserId: itemDetailProvider.product.addedUserId,
              userCoverPhoto: itemDetailProvider.product.user?.userCoverPhoto,
              userName: itemDetailProvider.product.user?.name,
              itemDetail: itemDetailProvider.product,
            ));
      });
    }
  }

  void _showBottomSheet(BuildContext context, bool isBuyNow) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: double.maxFinite,
          height: 300,
          padding: const EdgeInsets.all(PsDimens.space6),
          decoration: BoxDecoration(
              color: Utils.isLightMode(context)
                  ? PsColors.achromatic50
                  : PsColors.achromatic800,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(PsDimens.space10),
                  topRight: Radius.circular(PsDimens.space10))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                child: Container(
                  width: PsDimens.space40,
                  height: PsDimens.space4,
                  margin: const EdgeInsets.only(bottom: PsDimens.space10),
                  decoration: BoxDecoration(
                    color: PsColors.achromatic200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              //// Summary
              CustomDetailSummary(
                product: itemDetailProvider.product,
                quantity: itemDetailProvider.quantity,
              ),

              const SizedBox(height: PsDimens.space4),

              /// Quantity Title
              Text('transaction_detail__qty'.tr,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.isLightMode(context)
                          ? PsColors.achromatic900
                          : PsColors.achromatic50)),

              const SizedBox(height: PsDimens.space4),
              Selector<OrderIdProvider, int?>(
                  selector: (_, OrderIdProvider provider) => provider.count,
                  builder: (_, int? count, __) {
                    final int qty = count ?? 0;
                    return Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            if ((itemDetailProvider.product.isSoldOutItem !=
                                        true ||
                                    itemDetailProvider.quantity != null) &&
                                (itemDetailProvider.quantity != null &&
                                    orderIdProvider.count.toDouble() > 1)) {
                              orderIdProvider.decrement();
                            }
                          },
                          child: QuantityWidget(
                              icon: Icons.remove,
                              color:
                                  (itemDetailProvider.product.isSoldOutItem ||
                                          qty == 1)
                                      ? Utils.isLightMode(context)
                                          ? PsColors.achromatic100
                                          : PsColors.achromatic600
                                      : PsColors.primary500),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: PsDimens.space10),
                          child: Text(
                            count.toString(),
                            style: Theme.of(context).textTheme.titleLarge!,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if ((itemDetailProvider.product.isSoldOutItem !=
                                        true ||
                                    itemDetailProvider.quantity != null) &&
                                (itemDetailProvider.quantity != null &&
                                    itemDetailProvider.quantity!.toDouble() >
                                        orderIdProvider.count.toDouble()))
                              orderIdProvider.increment();
                          },
                          child: QuantityWidget(
                              icon: Icons.add,
                              color:
                                  (itemDetailProvider.product.isSoldOutItem ||
                                          qty >= itemDetailProvider.quantity!)
                                      ? Utils.isLightMode(context)
                                          ? PsColors.achromatic100
                                          : PsColors.achromatic600
                                      : PsColors.primary500),
                        ),
                      ],
                    );
                  }),

              const SizedBox(height: PsDimens.space16),

              if (isBuyNow)
                BuyButtonWidget(
                  onPressed: () {
                    if (itemDetailProvider.product.isSoldOutItem == true) {
                    } else if (itemDetailProvider.quantity == null) {
                      Navigator.of(context).pop();
                      showDialog<dynamic>(
                          context: context,
                          builder: (BuildContext context) {
                            return ErrorDialog(
                              message:
                                  'you_are_unable_to_purchase_this_item'.tr,
                            );
                          });
                    } else {
                      Navigator.of(context).pop();
                      final String discountPrice = (double.parse(
                                  itemDetailProvider.product.originalPrice
                                      .toString()) -
                              double.parse(itemDetailProvider
                                  .product.currentPrice
                                  .toString()))
                          .toStringAsFixed(0)
                          .toString();

                      final String subTotal = (double.parse(itemDetailProvider
                                  .product.originalPrice
                                  .toString()) *
                              orderIdProvider.count)
                          .toStringAsFixed(0)
                          .toString();

                      final List<ShoppingCartItem> shoppingCartItemList =
                          <ShoppingCartItem>[
                        ShoppingCartItem(
                            availableQuantity:
                                itemDetailProvider.quantity.toString(),
                            defaultPhoto:
                                itemDetailProvider.product.defaultPhoto,
                            discountPrice: discountPrice,
                            isSoldOut: '0',
                            itemId: itemDetailProvider.product.id,
                            itemName: itemDetailProvider.product.title,
                            originalPrice:
                                itemDetailProvider.product.originalPrice,
                            quantity: orderIdProvider.count.toString(),
                            salePrice: itemDetailProvider.product.currentPrice,
                            vendorCurrencySymbol: itemDetailProvider
                                .product.itemCurrency?.currencySymbol,
                            subTotal: subTotal)
                      ];

                      Navigator.pushNamed(context, RoutePaths.checkout,
                          arguments: <String, dynamic>{
                            'vendorId': itemDetailProvider.product.vendorId,
                            'checkoutItemList': shoppingCartItemList,
                            'isSingleItemCheckout': true
                          });
                    }
                  },
                )
              else
                PSButtonWidgetRoundCorner(
                  titleText: 'add_to_cart'.tr,
                  titleTextColor: PsColors.achromatic50,
                  onPressed: () async {
                    Navigator.of(context).pop();

                    if (isDifferentSeller) {
                      await showDialog<dynamic>(
                          context: context,
                          builder: (BuildContext context) {
                            return ErrorDialog(
                              message: 'cart_single_vendor_restriction'.tr,
                            );
                          });
                    } else {
                      await PsProgressDialog.showDialog(context);
                      _addToCart();
                    }
                  },
                )
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart() async {
    final AddToCartParameterHolder jsonMap = AddToCartParameterHolder(
        vendorId: itemDetailProvider.product.vendorId,
        itemId: itemDetailProvider.product.id,
        quantity: orderIdProvider.count.toString(),
        userId: psValueHolder.loginUserId,
        isSelect: '1');

    final PsResource<ApiStatus> respone =
        await addToCartProvider.submitAddToCart(context, jsonMap.toMap(),
            psValueHolder.loginUserId, psValueHolder.languageCode);

    if (respone.status == PsStatus.SUCCESS) {
      await addToCartProvider.loadData(
          requestPathHolder: RequestPathHolder(
              isCheckoutPage: PsConst.ZERO,
              loginUserId: psValueHolder.loginUserId ?? '',
              languageCode: psValueHolder.languageCode ?? ''));
      PsProgressDialog.dismissDialog();
      showInSnackBar('successfully_added_to_cart'.tr);
    } else if (respone.status == PsStatus.ERROR) {
      PsProgressDialog.dismissDialog();
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(message: respone.message);
          });
    }
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Utils.isLightMode(context)
            ? PsColors.achromatic50
            : PsColors.achromatic700,
        margin: const EdgeInsets.symmetric(
            vertical: PsDimens.space50, horizontal: PsDimens.space16),
        content: Row(
          children: <Widget>[
            Icon(
              Icons.check_circle,
              color: PsColors.success500,
            ),
            Text(
              message,
              style: TextStyle(
                  color: Utils.isLightMode(context)
                      ? PsColors.achromatic900
                      : PsColors.achromatic50),
            ),
          ],
        )));
  }
}
