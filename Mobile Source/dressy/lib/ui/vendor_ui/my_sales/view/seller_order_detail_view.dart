import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/common/ps_status.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/api_status.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/item_info.dart';
import '../../../../core/vendor/viewobject/order_summary.dart';
import '../../../../core/vendor/viewobject/order_summary_detail.dart';
import '../../../custom_ui/order_detail/component/order_detail_custom_divder.dart';
import '../../../custom_ui/order_detail/component/order_detail_list/order_detail_list.dart';
import '../../../custom_ui/order_detail/component/order_detail_summary.dart';
import '../../common/dialog/error_dialog.dart';
import '../../common/dialog/success_dialog.dart';
import '../../common/ps_button_widget_with_round_corner.dart';
import '../../order_detail/component/user_info/widgets/order_id_date_widget.dart';
import '../../order_detail/component/user_info/widgets/user_info_widget.dart';

class SellerOrderDetailView extends StatefulWidget {
  const SellerOrderDetailView({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  final String orderId;

  @override
  State<SellerOrderDetailView> createState() => _SellerOrderDetailViewState();
}

class _SellerOrderDetailViewState extends State<SellerOrderDetailView> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  OrderSummaryDetail? _orderDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetail();
    });
  }

  Future<void> _loadOrderDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<OrderSummaryModel> res =
        await apiService.getSellerOrderDetail(
      widget.orderId,
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _orderDetail = res.data?.orderSummaryDetail;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder() async {
    if (_isActionLoading) return;
    setState(() {
      _isActionLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<ApiStatus> res = await apiService.postAcceptOrder(
      <dynamic, dynamic>{'order_id': widget.orderId},
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });

      if (res.status == PsStatus.SUCCESS) {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return SuccessDialog(
              message: res.data?.message ?? 'seller__order_accepted_success'.tr,
            );
          },
        );
        _loadOrderDetail();
      } else {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: res.message ?? 'An error occurred',
            );
          },
        );
      }
    }
  }

  Future<void> _dispatchOrder() async {
    if (_isActionLoading) return;
    setState(() {
      _isActionLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<ApiStatus> res = await apiService.postDispatchOrder(
      <dynamic, dynamic>{'order_id': widget.orderId},
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });

      if (res.status == PsStatus.SUCCESS) {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return SuccessDialog(
              message: res.data?.message ?? 'seller__order_dispatched_success'.tr,
            );
          },
        );
        _loadOrderDetail();
      } else {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: res.message ?? 'An error occurred',
            );
          },
        );
      }
    }
  }

  Widget _buildActionButtons() {
    if (_orderDetail == null) return const SizedBox();

    final String status = (_orderDetail?.orderStatus ?? '').toLowerCase();
    final String statusId = _orderDetail?.orderStatusId ?? '';

    final bool isPending = statusId == '1' || status == 'pending';
    final bool isAccepted =
        statusId == '2' || status == 'approved' || status == 'accepted';

    if (!isPending && !isAccepted) {
      return const SizedBox();
    }

    if (_isActionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: PsDimens.space16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space16,
      ),
      child: Column(
        children: <Widget>[
          if (isPending)
            PSButtonWidgetRoundCorner(
              titleText: 'seller__accept_order'.tr,
              colorData: PsColors.primary500,
              hasShadow: true,
              width: double.infinity,
              height: 48,
              onPressed: _acceptOrder,
            ),
          if (isAccepted)
            PSButtonWidgetRoundCorner(
              titleText: 'seller__dispatch_order'.tr,
              colorData: PsColors.primary500,
              hasShadow: true,
              width: double.infinity,
              height: 48,
              onPressed: _dispatchOrder,
            ),
        ],
      ),
    );
  }

  Widget _buildYalidineTrackingWidget() {
    final String tracking = _orderDetail?.yalidineTracking ?? '';
    if (tracking.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: PsDimens.space16),
      padding: const EdgeInsets.all(PsDimens.space12),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context)
            ? PsColors.achromatic50
            : PsColors.achromatic800,
        borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space8)),
        border: Border.all(
          color: PsColors.primary500.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.local_shipping_outlined,
                color: PsColors.primary500,
                size: 20,
              ),
              const SizedBox(width: PsDimens.space8),
              Text(
                'seller__yalidine_tracking'.tr,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PsColors.primary500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: PsDimens.space8),
          Row(
            children: <Widget>[
              Expanded(
                child: SelectableText(
                  tracking,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'seller__copy_tracking'.tr,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tracking));
                  Fluttertoast.showToast(
                    msg: 'seller__tracking_copied'.tr,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
              ),
            ],
          ),
          if ((_orderDetail?.yalidineStatus ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: PsDimens.space4),
              child: Text(
                '${'seller__shipment_status'.tr}: ${_orderDetail?.yalidineStatus}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Utils.isLightMode(context)
                          ? PsColors.text800.withOpacity(0.7)
                          : PsColors.text50.withOpacity(0.7),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
        ),
        title: Text(
          'seller__order_detail'.tr,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Utils.isLightMode(context)
                    ? PsColors.achromatic900
                    : PsColors.achromatic50,
                fontWeight: FontWeight.w500,
                fontSize: PsDimens.space18,
              ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetail == null
              ? Center(
                  child: Text(
                    'seller__order_not_found'.tr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: <Widget>[
                    OrderIdAndDateWidget(
                      date: _orderDetail?.paymentDate,
                      id: _orderDetail?.orderCode,
                    ),

                    // Order Status Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: PsDimens.space12),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PsDimens.space12,
                            vertical: PsDimens.space4),
                        decoration: BoxDecoration(
                          color: Utils.codeToColor(
                            _orderDetail?.orderStatusColor?.toString() ?? '',
                            PsColors.primary500,
                          ).withOpacity(0.15),
                          border: Border.all(
                            color: Utils.codeToColor(
                              _orderDetail?.orderStatusColor?.toString() ?? '',
                              PsColors.primary500,
                            ),
                          ),
                          borderRadius: const BorderRadius.all(
                              Radius.circular(PsDimens.space8)),
                        ),
                        child: Text(
                          _orderDetail?.orderStatus ?? '',
                          style: TextStyle(
                            color: Utils.codeToColor(
                              _orderDetail?.orderStatusColor?.toString() ?? '',
                              PsColors.primary500,
                            ),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // Wallet Credited Badge
                    if (_orderDetail?.isWalletCredited == '1' ||
                        (_orderDetail?.walletCreditedAt ?? '').isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: PsDimens.space12),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: PsDimens.space12,
                              vertical: PsDimens.space4),
                          decoration: BoxDecoration(
                            color: PsColors.success50,
                            border: Border.all(color: PsColors.success500),
                            borderRadius: const BorderRadius.all(
                                Radius.circular(PsDimens.space8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.check_circle,
                                  color: PsColors.success500, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'seller__credited_to_wallet'.tr,
                                style: TextStyle(
                                  color: PsColors.success500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Yalidine Tracking Info (when dispatched)
                    _buildYalidineTrackingWidget(),

                    // Buyer Customer Name
                    UserInfoWidget(
                      title: 'seller__customer_name'.tr,
                      values:
                          '${_orderDetail?.shippingFirstName ?? ''} ${_orderDetail?.shippingLastName ?? ''}',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    // Buyer Email
                    UserInfoWidget(
                      title: 'edit_profile__email'.tr,
                      values: _orderDetail?.shippingEmail ?? '',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    // Payment Method & Status
                    UserInfoWidget(
                      isPayment: true,
                      title: 'check_out_payment_method'.tr,
                      values: _orderDetail?.paymentMethod ?? 'Cash on Delivery',
                      paid: _orderDetail?.paymentStatus ?? 'Unpaid',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    // Shipping Address & Phone
                    UserInfoWidget(
                      title: 'transaction_detail__shipping_address'.tr,
                      values:
                          '${_orderDetail?.shippingFirstName ?? ''} ${_orderDetail?.shippingLastName ?? ''}, ${_orderDetail?.shippingPhoneNo ?? ''}, ${_orderDetail?.shippingAddress ?? ''}, ${_orderDetail?.shippingCity ?? ''}, ${_orderDetail?.shippingState ?? ''}, ${_orderDetail?.shippingCountry ?? ''}',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    const SizedBox(height: PsDimens.space16),

                    // Ordered Items List
                    CustomOrderDetailList(
                      title: 'seller__order_items'.tr,
                      itemInfoList:
                          _orderDetail?.itemInfo ?? <ItemInfo>[],
                    ),

                    const CustomOrderDetailCustomDivider(),
                    const SizedBox(height: PsDimens.space8),

                    // Sub Total
                    CustomOrderDetailSummary(
                      title: 'basket_list__sub_total'.tr,
                      value: _orderDetail?.subTotal ?? '\$0.00',
                    ),

                    // Discount
                    if ((_orderDetail?.totalDiscount ?? '').isNotEmpty &&
                        _orderDetail?.totalDiscount != '\$0.00' &&
                        _orderDetail?.totalDiscount != '0')
                      CustomOrderDetailSummary(
                        title: 'dashboard__is_discount'.tr,
                        value: _orderDetail?.totalDiscount ?? '\$0.00',
                        isDiscount: true,
                      ),

                    // Delivery Charges
                    CustomOrderDetailSummary(
                      title: 'delivery_charges'.tr,
                      value: _orderDetail?.deliveryFee ?? '\$0.00',
                    ),

                    const CustomOrderDetailCustomDivider(),
                    const SizedBox(height: PsDimens.space6),

                    // Total
                    Padding(
                      padding: const EdgeInsets.only(bottom: PsDimens.space6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'transaction_detail__total'.tr,
                            style: TextStyle(
                              color: Utils.isLightMode(context)
                                  ? PsColors.achromatic900
                                  : PsColors.achromatic50,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _orderDetail?.total ?? '\$0.00',
                            style: TextStyle(
                              color: Utils.isLightMode(context)
                                  ? PsColors.achromatic900
                                  : PsColors.achromatic50,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: PsDimens.space12),

                    // Action buttons (Accept / Dispatch)
                    _buildActionButtons(),

                    const SizedBox(height: PsDimens.space24),
                  ],
                ),
    );
  }
}
