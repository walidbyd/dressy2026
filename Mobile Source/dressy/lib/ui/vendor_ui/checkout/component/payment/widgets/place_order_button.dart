import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import '../../../../../../config/ps_config.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../core/vendor/provider/add_to_cart/add_to_cart_provider.dart';
import '../../../../../../core/vendor/provider/default_billing_and_shipping/default_shipping_billing_provider.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/order_id/get_orderId_provider.dart';
import '../../../../../../core/vendor/provider/order_id/order_id_provider.dart';
import '../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../core/vendor/provider/vendor_info/vendor_info_provider.dart';
import '../../../../../../core/vendor/provider/vendor_item_bought/vendor_item_bought_provider.dart';
import '../../../../../../core/vendor/provider/vendor_paypal_token/vendor_paypal_token_provider.dart';
import '../../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../../core/vendor/utils/ps_progress_dialog.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/order_and_billing_parameter_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/payment_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/vendor_item_bought_parameter_holder.dart';
import '../../../../../../core/vendor/viewobject/item_info.dart';
import '../../../../../../core/vendor/viewobject/order_id.dart';
import '../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../../core/vendor/viewobject/product_relation.dart';
import '../../../../../../core/vendor/viewobject/shopping_cart_item.dart';
import '../../../../../../core/vendor/viewobject/vendor_item_bought_status.dart';
import '../../../../../../core/vendor/viewobject/vendor_paypal_token.dart';
import '../../../../../../ui/vendor_ui/common/dialog/error_dialog.dart';
import '../../../../common/dialog/check_item_dialog.dart';
import '../../../../common/dialog/warning_dialog_view.dart';
import '../../order_place/widgets/order_place_button.dart';

class PlaceOrderButton extends StatefulWidget {
  const PlaceOrderButton(
      {Key? key,
      required this.shoppingCartList,
      required this.defaultShippingAndBilling,
      required this.isSingleItemCheckout,
      required this.totalPrice,
      required this.currencySymbol,
      required this.vendorCurrencyShortForm,
      required this.vendorId,
      required this.vendorExpOrSoldOut,
      required this.color,
      this.titleTextColor,
      this.deliveryType,
      this.deliveryFee,
      this.toWilayaId,
      this.fromWilayaId,
      this.toCommuneName,
      this.yalidineStopDeskId,
      this.recipientName,
      this.recipientPhone,
      this.toWilayaName,
      this.stopDeskName,
      this.walletAmountUsed,
      this.isWalletOnly = false})
      : super(key: key);

  final List<ShoppingCartItem> shoppingCartList;
  final bool defaultShippingAndBilling;
  final bool isSingleItemCheckout;
  final String? totalPrice;
  final String? currencySymbol;
  final String? vendorCurrencyShortForm;
  final String? vendorId;
  final bool vendorExpOrSoldOut;
  final Color color;
  final Color? titleTextColor;
  final String? deliveryType;
  final String? deliveryFee;
  final String? toWilayaId;
  final String? fromWilayaId;
  final String? toCommuneName;
  final String? yalidineStopDeskId;
  final String? recipientName;
  final String? recipientPhone;
  final String? toWilayaName;
  final String? stopDeskName;
  final String? walletAmountUsed;
  final bool isWalletOnly;
  @override
  State<PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends State<PlaceOrderButton> {
  late AddToCartProvider addToCartProvider;

  VendorInfoProvider? vendorInfoProvider;

  OrderIdProvider? orderIdProvider;

  DefaultBillingAndShippingProvider? defaultBillingAndShippingProvider;

  ItemDetailProvider? itemDetailProvider;

  GetOrderIdProvider? getOrderIdProvider;

  VendorPayPalTokenProvider? vendorPayPalTokenProvider;

  UserProvider? userProvider;

  VendorItemBoughtProvider? vendorItemBoughtProvider;

  PsValueHolder? psValueHolder;
  UserRepository? userRepository;
  late String isSingleCheckout;

  @override
  Widget build(BuildContext context) {
    addToCartProvider = Provider.of<AddToCartProvider>(context);
    vendorInfoProvider = Provider.of<VendorInfoProvider>(context);
    getOrderIdProvider = Provider.of<GetOrderIdProvider>(context);
    orderIdProvider = Provider.of<OrderIdProvider>(context);
    itemDetailProvider = Provider.of<ItemDetailProvider>(context);
    vendorPayPalTokenProvider = Provider.of<VendorPayPalTokenProvider>(context);
    vendorItemBoughtProvider = Provider.of<VendorItemBoughtProvider>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);
    defaultBillingAndShippingProvider =
        Provider.of<DefaultBillingAndShippingProvider>(context);
    userRepository = Provider.of<UserRepository>(context);

    isSingleCheckout = widget.isSingleItemCheckout ? '1' : '0';

    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<UserProvider?>(
          lazy: false,
          create: (BuildContext context) {
            userProvider = UserProvider(
                repo: userRepository, psValueHolder: psValueHolder);

            userProvider?.getUser(psValueHolder?.loginUserId,
                psValueHolder?.languageCode ?? 'en');

            return userProvider;
          },
        ),
      ],
      child: OrderPlaceButtonWidget(
          titleTextColor: widget.titleTextColor,
          color: widget.color,
          onPressed: !widget.vendorExpOrSoldOut
              ? () async {
                  int itemQuantity = 0;

                  /// Payment need (default to COD = 5)
                  if (vendorInfoProvider?.selectedValue == 0) {
                    vendorInfoProvider?.updateSelectedValue(5);
                  }

                  /// Address-free Yalidine checkout validation:
                  /// Require ONLY Recipient Name, Phone, Wilaya, and Commune (or Stop-Desk)
                  final String cleanName = (widget.recipientName ?? '').trim();
                  final String cleanPhone = (widget.recipientPhone ?? '').trim();
                  final String cleanWilayaId = (widget.toWilayaId ?? '').trim();
                  final String cleanCommune = (widget.toCommuneName ?? '').trim();
                  final bool isStopDesk = widget.deliveryType == 'stopdesk' ||
                      widget.deliveryType == 'stop_desk';

                  if (cleanName.length < 2) {
                    showDialog<dynamic>(
                        context: context,
                        builder: (BuildContext context) {
                          return const WarningDialog(
                              message:
                                  'Veuillez saisir votre nom complet (destinataire).');
                        });
                    return;
                  }

                  final String phoneDigits =
                      cleanPhone.replaceAll(RegExp(r'\D+'), '');
                  if (phoneDigits.length < 9) {
                    showDialog<dynamic>(
                        context: context,
                        builder: (BuildContext context) {
                          return const WarningDialog(
                              message:
                                  'Veuillez saisir un numéro de téléphone valide (ex: 05/06/07...).');
                        });
                    return;
                  }

                  if (cleanWilayaId.isEmpty) {
                    showDialog<dynamic>(
                        context: context,
                        builder: (BuildContext context) {
                          return const WarningDialog(
                              message: 'Veuillez choisir votre Wilaya.');
                        });
                    return;
                  }

                  if (isStopDesk &&
                      (widget.yalidineStopDeskId == null ||
                          widget.yalidineStopDeskId!.trim().isEmpty)) {
                    showDialog<dynamic>(
                        context: context,
                        builder: (BuildContext context) {
                          return const WarningDialog(
                              message:
                                  'Veuillez sélectionner un bureau Yalidine Stop-Desk.');
                        });
                    return;
                  }

                  if (!isStopDesk && cleanCommune.isEmpty) {
                    showDialog<dynamic>(
                        context: context,
                        builder: (BuildContext context) {
                          return const WarningDialog(
                              message: 'Veuillez sélectionner votre Commune.');
                        });
                    return;
                  }

                  await PsProgressDialog.showDialog(context,
                      message: 'progressloading_ordering'.tr);

                  try {
                    final List<ItemInfo> itemInfoList = <ItemInfo>[];
                    bool isNotSoldOut = true;

                    for (ShoppingCartItem item in widget.shoppingCartList) {
                      final PsResource<Product>? product =
                          await itemDetailProvider?.onlyCheckItemBought(
                              requestPathHolder: RequestPathHolder(
                        loginUserId: psValueHolder?.loginUserId,
                        itemId: item.itemId,
                        languageCode: psValueHolder?.languageCode ?? 'en',
                      ));

                      /// Item Quantity
                      product?.data?.productRelation
                          ?.forEach((ProductRelation element) {
                        if (element.coreKeyId == 'ps-itm00046' ||
                            element.coreKeyId == 'itm00046' ||
                            element.coreKeyId == 'ps-itm00010' ||
                            element.coreKeyId == 'itm00010') {
                          final int parsedQty =
                              int.tryParse(element.value?.toString() ?? '0') ?? 0;
                          if (parsedQty > 0 || itemQuantity == 0) {
                            itemQuantity = parsedQty;
                          }
                        }
                      });

                      if (product?.data?.isSoldOutItem == true) {
                        isNotSoldOut = false;
                        await PsProgressDialog.dismissDialog();
                        if (mounted) {
                          showDialog<dynamic>(
                              context: context,
                              builder: (BuildContext context) {
                                return CheckOutDialog(
                                  title: 'dashboard__sold_out'.tr,
                                  message: 'check_out_sold_out_message'.tr,
                                );
                              });
                        }
                        break;
                      } else if (item.quantity != '0' &&
                          (int.tryParse(item.quantity ?? '0') ?? 0) >
                              itemQuantity) {
                        isNotSoldOut = false;
                        await PsProgressDialog.dismissDialog();
                        if (mounted) {
                          showDialog<dynamic>(
                              context: context,
                              builder: (BuildContext context) {
                                return CheckOutDialog(
                                  title: 'check_out_limt_item'.tr,
                                  message: 'check_out_limit_item_message'.tr,
                                );
                              });
                        }
                        break;
                      } else {
                        final ItemInfo itemInfo = ItemInfo(
                            itemId: item.itemId,
                            itemName: item.itemName,
                            quantity: item.quantity,
                            originalPrice: item.originalPrice,
                            salePrice: item.salePrice,
                            subTotal: item.subTotal,
                            discountPrice: item.discountPrice);

                        itemInfoList.add(itemInfo);
                      }
                    }
                    if (isNotSoldOut) {
                      await _continueCheckout(
                          itemInfoList, widget.totalPrice ?? '0.00');
                    }
                  } catch (e) {
                    print('PlaceOrderButton Error: $e');
                    await PsProgressDialog.dismissDialog();
                    if (mounted) {
                      showDialog<dynamic>(
                          context: context,
                          builder: (BuildContext context) {
                            return CheckOutDialog(
                              title: 'checkout__payment_fail'.tr,
                              message: e.toString(),
                            );
                          });
                    }
                  } finally {
                    if (PsProgressDialog.isShowing()) {
                      await PsProgressDialog.dismissDialog();
                    }
                  }
                }
              : null,
          totalPrice: () {
            if (widget.totalPrice == null || widget.totalPrice == '') {
              return '${widget.currencySymbol ?? 'DA'} 0';
            }
            final double gross = double.tryParse(widget.totalPrice!) ?? 0.0;
            final double walletUsed =
                double.tryParse(widget.walletAmountUsed ?? '0') ?? 0.0;
            if (widget.isWalletOnly || (walletUsed >= gross && gross > 0)) {
              return '0 ${widget.currencySymbol ?? 'DA'} (Wallet)';
            } else if (walletUsed > 0) {
              final double remaining = gross - walletUsed > 0 ? gross - walletUsed : 0.0;
              return '${Utils.getPriceFormat(remaining.toStringAsFixed(0), psValueHolder?.priceFormat ?? '#,##0')} ${widget.currencySymbol ?? 'DA'}';
            }
            return '${Utils.getPriceFormat(widget.totalPrice!, psValueHolder?.priceFormat ?? '#,##0')} ${widget.currencySymbol ?? 'DA'}';
          }()),
    );
  }

  Future<void> _continueCheckout(
      List<ItemInfo> itemInfo, String totalPrice) async {
    try {
      final String fullName = (widget.recipientName ??
              userProvider?.user.data?.name ??
              psValueHolder?.loginUserName ??
              'Client Dressy')
          .trim();
      final List<String> nameParts =
          fullName.split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
      final String firstName = nameParts.isNotEmpty ? nameParts.first : 'Client';
      final String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '-';

      final String phoneNo = (widget.recipientPhone ??
              userProvider?.user.data?.userPhone ??
              '')
          .trim();
      final String emailRaw = (userProvider?.user.data?.userEmail ??
              psValueHolder?.userEmail ??
              defaultBillingAndShippingProvider
                  ?.defaultBillingAndShipping.data?.shippingEmail ??
              '')
          .trim();
      final String email = emailRaw.contains('@')
          ? emailRaw
          : 'buyer${psValueHolder?.loginUserId ?? '0'}@dressy-dz.com';

      final String wilayaCodeStr = (widget.toWilayaId ?? '16').trim();
      final String wilayaName =
          (widget.toWilayaName ?? 'Alger').trim().isNotEmpty
              ? widget.toWilayaName!.trim()
              : 'Alger';
      final String communeName =
          (widget.toCommuneName ?? wilayaName).trim().isNotEmpty
              ? widget.toCommuneName!.trim()
              : wilayaName;
      final bool isStopDesk = widget.deliveryType == 'stopdesk' ||
          widget.deliveryType == 'stop_desk';
      final String stopDeskName = (widget.stopDeskName ?? '').trim();
      final String composedAddress = (isStopDesk && stopDeskName.isNotEmpty)
          ? '$stopDeskName, $wilayaName'
          : '$communeName, $wilayaName';
      final String postalCode = '${wilayaCodeStr.padLeft(2, '0')}000';

      final OrderAndBillingParameterHolder orderAndBillingParameterHolder =
          OrderAndBillingParameterHolder(
              vendorId: widget.vendorId,
              recipientName: fullName,
              billingAddress: composedAddress,
              shippingAddress: composedAddress,
              billingCity: communeName,
              billingCountry: 'Algeria',
              billingEmail: email,
              billingFirstName: firstName,
              billingLastName: lastName,
              billingPhoneNo: phoneNo,
              billingPostalCode: postalCode,
              billingState: wilayaName,
              isSaveBillingInfoForNextTime: '0',
              isSaveShippingInfoForNextTime: '0',
              shippingCity: communeName,
              shippingCountry: 'Algeria',
              shippingEmail: email,
              shippingFirstName: firstName,
              shippingLastName: lastName,
              shippingPhoneNo: phoneNo,
              shippingPostalCode: postalCode,
              shippingState: wilayaName,
              totalPrice: totalPrice,
              itemInfo: itemInfo,
              deliveryType: isStopDesk ? 'stopdesk' : 'home',
              deliveryFee: widget.deliveryFee,
              toWilayaId: wilayaCodeStr,
              fromWilayaId: widget.fromWilayaId,
              toCommuneName: communeName,
              yalidineStopDeskId:
                  isStopDesk ? widget.yalidineStopDeskId : null,
              stopDeskName: isStopDesk ? stopDeskName : null,
              walletAmountUsed: widget.walletAmountUsed);

      if (!PsProgressDialog.isShowing()) {
        await PsProgressDialog.showDialog(context,
            message: 'progressloading_ordering'.tr);
      }

      final PsResource<OrderId>? data = await getOrderIdProvider?.postData(
        requestBodyHolder: orderAndBillingParameterHolder,
        requestPathHolder: RequestPathHolder(
            loginUserId: psValueHolder?.loginUserId ?? '',
            languageCode: psValueHolder?.languageCode ?? 'en',
            headerToken: psValueHolder?.headerToken ?? ''),
      );

      if (data == null ||
          data.data?.orderId == null ||
          data.data!.orderId!.isEmpty) {
        await PsProgressDialog.dismissDialog();
        if (mounted) {
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return CheckOutDialog(
                  title: 'checkout__payment_fail'.tr,
                  message: (data?.message != null && data!.message.isNotEmpty)
                      ? data.message
                      : 'check_out_payment_fail_message'.tr,
                );
              });
        }
        return;
      }

      final String orderId = data.data!.orderId!;

      if (vendorInfoProvider?.selectedValue == 1) {
        await payWithPaypal(
            context,
            vendorPayPalTokenProvider,
            psValueHolder,
            widget.vendorId,
            vendorInfoProvider?.vendorInfo.data?.vendorCurrencyId,
            totalPrice,
            userProvider,
            orderId,
            vendorItemBoughtProvider,
            itemDetailProvider);
      } else if (vendorInfoProvider?.selectedValue == 2 ||
          vendorInfoProvider?.selectedValue == 3 ||
          vendorInfoProvider?.selectedValue == 4) {
        await PsProgressDialog.dismissDialog();
        if (mounted) {
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return const WarningDialog(
                  message:
                      'Ce moyen de paiement n\'est pas disponible pour le moment. Veuillez choisir le paiement à la livraison.',
                );
              });
        }
      } else if (vendorInfoProvider?.selectedValue == 5) {
        await cashOnDelivery(
          context,
          psValueHolder,
          widget.vendorId,
          vendorInfoProvider?.vendorInfo.data?.vendorCurrencyId,
          totalPrice,
          orderId,
          vendorItemBoughtProvider,
        );
      } else if (vendorInfoProvider?.selectedValue == 6) {
        await payWithFlutterwave(
            orderId, vendorInfoProvider?.vendorInfo.data?.vendorCurrencyId);
      }
    } finally {
      if (PsProgressDialog.isShowing()) {
        await PsProgressDialog.dismissDialog();
      }
    }
  }

  Future<void> payWithPaypal(
      BuildContext context,
      VendorPayPalTokenProvider? vendorPayPalTokenProvider,
      PsValueHolder? psValueHolder,
      String? vendorId,
      String? itemCurrencyId,
      String? totalPrice,
      UserProvider? userProvider,
      String? orderId,
      VendorItemBoughtProvider? vendorItemBoughtProvider,
      ItemDetailProvider? itemDetailProvider) async {
    await PsProgressDialog.dismissDialog();
    if (mounted) {
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return const WarningDialog(
              message:
                  'Ce moyen de paiement n\'est pas disponible pour le moment. Veuillez choisir le paiement à la livraison.',
            );
          });
    }
  }

  Future<void> cashOnDelivery(
      BuildContext context,
      PsValueHolder? psValueHolder,
      String? vendorId,
      String? itemCurrencyId,
      String? totalPrice,
      String? orderId,
      VendorItemBoughtProvider? vendorItemBoughtProvider) async {
    try {
      final VendorItemBoughtParameterHolder vendorItemBoughtParameterHolder =
          VendorItemBoughtParameterHolder(
              currencyId: itemCurrencyId,
              isPaystack: '',
              orderId: orderId,
              paymentAmount: totalPrice,
              paymentMethod: widget.isWalletOnly ? 'wallet' : PsConst.CASH_ON_DELIVERY_METHOD,
              paymentMethodNonce: '',
              razorId: '',
              userId: psValueHolder?.loginUserId,
              vendorId: vendorId,
              isSingleCheckout: isSingleCheckout,
              walletAmountUsed: widget.walletAmountUsed);

      if (!PsProgressDialog.isShowing()) {
        await PsProgressDialog.showDialog(context,
            message: 'progressloading_ordering'.tr);
      }

      final PsResource<VendorItemBoughtApiStatus>? vendorItemBoughtData =
          await vendorItemBoughtProvider?.vendorItemBought(
              requestBodyHolder: vendorItemBoughtParameterHolder,
              requestPathHolder: RequestPathHolder(
                  loginUserId: Utils.checkUserLoginId(psValueHolder),
                  headerToken: psValueHolder?.headerToken,
                  languageCode: psValueHolder?.languageCode ?? 'en'));

      await PsProgressDialog.dismissDialog();

      if (vendorItemBoughtData?.data?.status == 'success' ||
          vendorItemBoughtData?.status == PsStatus.SUCCESS) {
        addToCartProvider.clearCart();
        try {
          Provider.of<OrderIdProvider>(context, listen: false).clearAddress();
        } catch (_) {}

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(RoutePaths.orderSuccessful,
              arguments: <String, dynamic>{
                'orderId': orderId,
                'totalPrice': totalPrice,
                'currencySymbol': widget.currencySymbol ?? 'DA',
              });
        }
      } else {
        if (mounted) {
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return CheckOutDialog(
                  title: 'checkout__payment_fail'.tr,
                  message: vendorItemBoughtData?.message.isNotEmpty == true
                      ? vendorItemBoughtData!.message
                      : 'check_out_payment_fail_message'.tr,
                );
              });
        }
      }
    } catch (e) {
      print('CashOnDelivery Error: $e');
      await PsProgressDialog.dismissDialog();
      if (mounted) {
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return CheckOutDialog(
                title: 'checkout__payment_fail'.tr,
                message: e.toString(),
              );
            });
      }
    } finally {
      if (PsProgressDialog.isShowing()) {
        await PsProgressDialog.dismissDialog();
      }
    }
  }

  Future<void> payWithRaZor(
      BuildContext context,
      String? itemCurrencyId,
      String? vendorId,
      String? orderId,
      String? totalPrice,
      VendorItemBoughtProvider? vendorItemBoughtProvider,
      UserProvider? userProvider,
      PsValueHolder? psValueHolder,
      ItemDetailProvider? itemDetailProvider,
      VendorInfoProvider? vendorInfoProvider) async {
    await PsProgressDialog.dismissDialog();
    if (mounted) {
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return const WarningDialog(
              message:
                  'Ce moyen de paiement n\'est pas disponible pour le moment. Veuillez choisir le paiement à la livraison.',
            );
          });
    }
  }

  Future<void> payWithFlutterwave(
      String? orderId, String? itemCurrencyId) async {
    await PsProgressDialog.dismissDialog();
    if (mounted) {
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return const WarningDialog(
              message:
                  'Ce moyen de paiement n\'est pas disponible pour le moment. Veuillez choisir le paiement à la livraison.',
            );
          });
    }
  }
}
