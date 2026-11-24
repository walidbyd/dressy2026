import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../core/vendor/api/ps_api_service.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/order_detail/order_detail_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/api_status.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../../core/vendor/viewobject/order_summary_detail.dart';
import '../../../../config/ps_colors.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../../../core/vendor/db/common/ps_data_source_manager.dart';
import '../../../../core/vendor/repository/product_repository.dart';
import '../../../../core/vendor/viewobject/holder/intent_holder/chat_history_intent_holder.dart';
import '../../../../core/vendor/viewobject/item_info.dart';
import '../../../custom_ui/order_detail/component/order_detail_custom_divder.dart';
import '../../../custom_ui/order_detail/component/order_detail_list/order_detail_list.dart';
import '../../../custom_ui/order_detail/component/order_detail_summary.dart';
import '../../common/ps_button_widget_with_round_corner.dart';
import '../../common/ps_ui_widget.dart';
import '../component/track_order_dialog.dart';
import '../component/user_info/widgets/order_id_date_widget.dart';
import '../component/user_info/widgets/user_info_widget.dart';

class OrderDetailView extends StatefulWidget {
  const OrderDetailView({
    Key? key,
    required this.orderId,
    //  required this.vendorId
  }) : super(key: key);

  final String orderId;
  // final String vendorId;

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  PsValueHolder? valueHolder;

  bool isConnectedToInternet = false;

  bool isSuccessfullyLoaded = true;

  late AppLocalization langProvider;

  ProductRepository? productRepository;
  OrderDetailProvider? orderDetailProvider;
  // VendorInfoProvider? vendorInfoProvider;
  // VendorInfoRepository? vendorInfoRepository;

  @override
  Widget build(BuildContext context) {
    productRepository = Provider.of<ProductRepository>(context);
    // vendorInfoRepository = Provider.of<VendorInfoRepository>(context);

    langProvider = Provider.of<AppLocalization>(context);
    valueHolder = Provider.of<PsValueHolder>(context);
    // ignore: always_specify_types

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
        ),
        title: Text(
          'order_details'.tr,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Utils.isLightMode(context)
                  ? PsColors.achromatic900
                  : PsColors.achromatic50,
              fontWeight: FontWeight.w500,
              fontSize: PsDimens.space18),
        ),
      ),
      body: MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<OrderDetailProvider?>(
              lazy: false,
              create: (BuildContext context) {
                orderDetailProvider = OrderDetailProvider(context: context);
                orderDetailProvider?.loadData(
                    dataConfig: DataConfiguration(
                        dataSourceType: DataSourceType.SERVER_DIRECT),
                    requestPathHolder: RequestPathHolder(
                        loginUserId: Utils.checkUserLoginId(valueHolder),
                        languageCode: langProvider.currentLocale.languageCode,
                        orderId: widget.orderId));
                return orderDetailProvider;
              }),
          // ChangeNotifierProvider<VendorInfoProvider?>(
          //     lazy: false,
          //     create: (BuildContext context) {
          //       vendorInfoProvider = VendorInfoProvider(
          //         repo: vendorInfoRepository,
          //       );

          //       vendorInfoProvider?.loadData(
          //           requestPathHolder: RequestPathHolder(
          //               loginUserId: valueHolder?.loginUserId,
          //               vendorId: widget.vendorId));
          //       return vendorInfoProvider;
          //     }),
        ],
        child: Consumer<OrderDetailProvider>(
          builder: (BuildContext context,
              OrderDetailProvider orderDetailProvider, Widget? child) {
            final OrderSummaryDetail? orderSummaryDetail =
                orderDetailProvider.orderSummaryModel.data?.orderSummaryDetail;
            return Stack(children: <Widget>[
              if (orderDetailProvider.hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    children: <Widget>[
                      OrderIdAndDateWidget(
                        date: orderSummaryDetail?.paymentDate,
                        id: orderSummaryDetail?.orderCode,
                      ),

                      // Order Status Badge
                      if ((orderSummaryDetail?.orderStatus ?? '').isNotEmpty)
                        Builder(
                          builder: (BuildContext context) {
                            final bool isDeliveredPaid =
                                orderSummaryDetail?.isDeliveredAndPaid == '1' ||
                                (orderSummaryDetail?.orderStatusId == '4') ||
                                (orderSummaryDetail?.orderStatus ?? '')
                                    .toLowerCase()
                                    .contains('livré et payé') ||
                                (orderSummaryDetail?.orderStatus ?? '')
                                    .toLowerCase()
                                    .contains('delivered & paid') ||
                                (orderSummaryDetail?.orderStatus ?? '')
                                    .contains('تم التوصيل والدفع');

                            if (isDeliveredPaid) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: PsDimens.space12),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: PsDimens.space16,
                                      vertical: PsDimens.space6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    border: Border.all(
                                      color: const Color(0xFF10B981),
                                      width: 1.5,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(PsDimens.space8)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(Icons.done_all,
                                          size: 18, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Text(
                                        orderSummaryDetail?.deliveredAndPaidLabel ??
                                            (orderSummaryDetail?.orderStatus ?? 'Livré et payé'),
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: PsDimens.space12),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: PsDimens.space12,
                                    vertical: PsDimens.space4),
                                decoration: BoxDecoration(
                                  color: Utils.codeToColor(
                                    orderSummaryDetail?.orderStatusColor?.toString() ?? '',
                                    PsColors.primary500,
                                  ).withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: Utils.codeToColor(
                                      orderSummaryDetail?.orderStatusColor?.toString() ?? '',
                                      PsColors.primary500,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(PsDimens.space8)),
                                ),
                                child: Text(
                                  orderSummaryDetail?.orderStatus ?? '',
                                  style: TextStyle(
                                    color: Utils.codeToColor(
                                      orderSummaryDetail?.orderStatusColor?.toString() ?? '',
                                      PsColors.primary500,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Status Reason Banner (if cancelled or returned)
                      if ((orderSummaryDetail?.statusReason ?? '').isNotEmpty ||
                          orderSummaryDetail?.orderStatusId == '5' ||
                          orderSummaryDetail?.orderStatusId == '6' ||
                          (orderSummaryDetail?.orderStatus ?? '').toLowerCase() == 'cancelled' ||
                          (orderSummaryDetail?.orderStatus ?? '').toLowerCase() == 'returned')
                        Container(
                          margin: const EdgeInsets.only(bottom: PsDimens.space16),
                          padding: const EdgeInsets.all(PsDimens.space12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space8)),
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(Icons.info_outline, color: Colors.red, size: 20),
                              const SizedBox(width: PsDimens.space8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      orderSummaryDetail?.orderStatusId == '6' ||
                                              (orderSummaryDetail?.orderStatus ?? '').toLowerCase() == 'returned'
                                          ? 'order__status_returned'.tr
                                          : 'order__status_cancelled'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if ((orderSummaryDetail?.statusReason ?? '').isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${'order__reason'.tr}: ${orderSummaryDetail?.statusReason}',
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Yalidine Tracking Info (when dispatched)
                      if ((orderSummaryDetail?.yalidineTracking ?? '').isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: PsDimens.space16),
                          padding: const EdgeInsets.all(PsDimens.space14),
                          decoration: BoxDecoration(
                            color: Utils.isLightMode(context)
                                ? PsColors.achromatic50
                                : PsColors.achromatic800,
                            borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space10)),
                            border: Border.all(
                              color: PsColors.primary500.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        'seller__yalidine_tracking'.tr.isNotEmpty && 'seller__yalidine_tracking'.tr != 'seller__yalidine_tracking'
                                            ? 'seller__yalidine_tracking'.tr
                                            : 'Suivi Yalidine Express',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: PsColors.primary500,
                                            ),
                                      ),
                                    ],
                                  ),
                                  // Live Delivery Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (orderSummaryDetail?.deliveryType == 'stop_desk')
                                          ? Colors.amber.withOpacity(0.15)
                                          : Colors.blue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (orderSummaryDetail?.deliveryType == 'stop_desk')
                                          ? '🏢 Point Relais Yalidine'
                                          : '🏠 Livraison à Domicile',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: (orderSummaryDetail?.deliveryType == 'stop_desk')
                                            ? Colors.amber[900]
                                            : Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: PsDimens.space10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: SelectableText(
                                      orderSummaryDetail!.yalidineTracking!,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            letterSpacing: 1.2,
                                            fontFamily: 'monospace',
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    tooltip: 'seller__copy_tracking'.tr,
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text: orderSummaryDetail.yalidineTracking!));
                                      Fluttertoast.showToast(
                                        msg: 'seller__tracking_copied'.tr.isNotEmpty && 'seller__tracking_copied'.tr != 'seller__tracking_copied'
                                            ? 'seller__tracking_copied'.tr
                                            : 'Numéro de suivi copié !',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if ((orderSummaryDetail.yalidineStatus ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: PsDimens.space4),
                                  child: Text(
                                    '${'seller__shipment_status'.tr}: ${orderSummaryDetail.yalidineStatus}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Utils.isLightMode(context)
                                              ? PsColors.text800.withOpacity(0.7)
                                              : PsColors.text50.withOpacity(0.7),
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      // Buyer Track Order Button (replaces Bordereau for buyers)
                      if (orderSummaryDetail != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: PsDimens.space16),
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PsColors.primary500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(PsDimens.space8),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.track_changes_rounded, size: 20),
                            label: Text(
                              'order__track_order'.tr.isNotEmpty &&
                                      'order__track_order'.tr != 'order__track_order'
                                  ? 'order__track_order'.tr
                                  : 'Suivre la commande',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () {
                              TrackOrderDialog.show(
                                context,
                                orderId: orderSummaryDetail.id ?? widget.orderId,
                                orderCode: orderSummaryDetail.orderCode ?? widget.orderId,
                                initialTracking: orderSummaryDetail.yalidineTracking ?? '',
                                initialStatusId: int.tryParse(orderSummaryDetail.orderStatusId ?? '1') ?? 1,
                                initialYalidineStatus: orderSummaryDetail.yalidineStatus ?? '',
                              );
                            },
                          ),
                        ),
                      UserInfoWidget(
                        title: 'home_search__product_name_hint'.tr,
                        values:
                            '${orderSummaryDetail?.shippingFirstName.toString()} ${orderSummaryDetail?.shippingLastName}',
                      ),
                      const CustomOrderDetailCustomDivider(),
                      UserInfoWidget(
                        title: 'edit_profile__email'.tr,
                        values: orderSummaryDetail?.shippingEmail,
                      ),
                      const CustomOrderDetailCustomDivider(),
                      UserInfoWidget(
                        isPayment: true,
                        title: 'check_out_payment_method'.tr,
                        values: orderSummaryDetail?.paymentMethod,
                        paid: orderSummaryDetail?.paymentStatus,
                      ),
                      const CustomOrderDetailCustomDivider(),
                      UserInfoWidget(
                          title: 'transaction_detail__shipping_address'.tr,
                          values:
                              '${orderSummaryDetail?.shippingFirstName.toString()} ${orderSummaryDetail?.shippingLastName}, (${orderSummaryDetail?.shippingPhoneNo?.split('-').first})${orderSummaryDetail?.shippingPhoneNo?.split('-').last} , ${orderSummaryDetail?.shippingEmail}, ${orderSummaryDetail?.shippingAddress}, ${orderSummaryDetail?.shippingCountry}, ${orderSummaryDetail?.shippingState}, ${orderSummaryDetail?.shippingCity}, ${orderSummaryDetail?.shippingPostalCode}'),
                      const CustomOrderDetailCustomDivider(),

                      UserInfoWidget(
                          title: 'transaction_detail__billing_address'.tr,
                          values:
                              '${orderSummaryDetail?.billingFirstName.toString()} ${orderSummaryDetail?.billingLastName}, (${orderSummaryDetail?.billingPhoneNo?.split('-').first}) ${orderSummaryDetail?.billingPhoneNo?.split('-').last}, ${orderSummaryDetail?.billingEmail}, ${orderSummaryDetail?.billingAddress}, ${orderSummaryDetail?.billingCountry}, ${orderSummaryDetail?.billingState}, ${orderSummaryDetail?.billingCity}, ${orderSummaryDetail?.billingPostalCode}'),
                      const SizedBox(height: PsDimens.space16),

                      /// Order detail Items List
                      CustomOrderDetailList(
                          title: orderSummaryDetail?.vendorName ?? '',
                          itemInfoList:
                              orderSummaryDetail?.itemInfo ?? <ItemInfo>[]),

                      const CustomOrderDetailCustomDivider(),
                      const SizedBox(height: PsDimens.space8),

                      /// Sub Total
                      CustomOrderDetailSummary(
                          title: 'basket_list__sub_total'.tr,
                          value: orderSummaryDetail?.subTotal ?? '\$0.00'),

                      /// Discount
                      CustomOrderDetailSummary(
                        title: 'dashboard__is_discount'.tr,
                        value: orderSummaryDetail?.totalDiscount ?? '\$0.00',
                        isDiscount: true,
                      ),

                      /// Delivery Charges
                      CustomOrderDetailSummary(
                          title: 'delivery_charges'.tr,
                          value: orderSummaryDetail?.deliveryFee ?? '\$0.00'),
                      const CustomOrderDetailCustomDivider(),
                      const SizedBox(height: PsDimens.space6),

                      ///Total
                      Padding(
                        padding: const EdgeInsets.only(bottom: PsDimens.space6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('transaction_detail__total'.tr,
                                style: TextStyle(
                                    color: Utils.isLightMode(context)
                                        ? PsColors.achromatic900
                                        : PsColors.achromatic50,
                                    fontSize: 18)),
                            Text(orderSummaryDetail?.total ?? '\$0.00',
                                style: TextStyle(
                                    color: Utils.isLightMode(context)
                                        ? PsColors.achromatic900
                                        : PsColors.achromatic50,
                                    fontSize: 18)),
                          ],
                        ),
                      ),

                      const SizedBox(height: PsDimens.space6),

                      const SizedBox(height: PsDimens.space16),

                      /// Review Button or Published Badge if Delivered
                      if ((orderSummaryDetail?.orderStatusId == '4') ||
                          (orderSummaryDetail?.orderStatus?.toLowerCase() == 'delivered') ||
                          (orderSummaryDetail?.orderStatus?.toLowerCase() == 'livrée') ||
                          (orderSummaryDetail?.orderStatus?.toLowerCase() == 'livree') ||
                          (orderSummaryDetail?.yalidineStatus?.toLowerCase() == 'livré') ||
                          (orderSummaryDetail?.yalidineStatus?.toLowerCase() == 'livre') ||
                          (orderSummaryDetail?.yalidineStatus?.toLowerCase() == 'delivered'))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: PsDimens.space16, vertical: PsDimens.space4),
                          child: (orderSummaryDetail?.isReviewed == '1')
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBF4F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE4A4AB), width: 1.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFF5C1A2B), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '★ ${(orderSummaryDetail?.reviewRating != null && orderSummaryDetail!.reviewRating!.isNotEmpty) ? orderSummaryDetail!.reviewRating : '5.0'} — Avis publié',
                                        style: const TextStyle(
                                          color: Color(0xFF5C1A2B),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(
                                  height: 48,
                                  child: PSButtonWidgetWithIconRoundCorner(
                                    icon: Icons.star_rate_rounded,
                                    iconColor: Colors.white,
                                    colorData: PsColors.burgundy,
                                    width: double.infinity,
                                    titleText: 'Laisser un avis',
                                    onPressed: () {
                                      _showReviewBottomSheet(
                                          context, orderSummaryDetail!);
                                    },
                                  ),
                                ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PsDimens.space16, vertical: PsDimens.space6),
                        child: SizedBox(
                          height: 48,
                          child: PSButtonWidgetWithIconRoundCorner(
                            icon: Icons.chat_outlined,
                            iconColor: Colors.white,
                            colorData: PsColors.burgundy,
                            width: double.infinity,
                            titleText: 'order__chat_with_seller'.tr.isNotEmpty &&
                                  'order__chat_with_seller'.tr !=
                                      'order__chat_with_seller'
                              ? 'order__chat_with_seller'.tr
                              : 'Contacter le vendeur',
                          onPressed: () {
                            final String itemId = (orderSummaryDetail
                                        ?.itemInfo?.isNotEmpty ==
                                    true)
                                ? (orderSummaryDetail!.itemInfo!.first.itemId ??
                                    '')
                                : '';
                            final String sellerId =
                                orderSummaryDetail?.sellerUserId ?? '';
                            final String loginUserId =
                                Utils.checkUserLoginId(valueHolder);

                            Navigator.pushNamed(
                              context,
                              RoutePaths.chatView,
                              arguments: ChatHistoryIntentHolder(
                                chatFlag: PsConst.CHAT_FROM_BUYER,
                                itemId: itemId,
                                buyerUserId: loginUserId,
                                sellerUserId: sellerId,
                                userName:
                                    orderSummaryDetail?.vendorName ?? 'Vendeur',
                              ),
                            );
                          },
                        ),
                      )),
                      const SizedBox(height: PsDimens.space24),
                    ],
                  ),
                ),
              PSProgressIndicator(orderDetailProvider.currentStatus)
            ]);
          },
        ),
      ),
    );
  }

  void _showReviewBottomSheet(
      BuildContext context, OrderSummaryDetail orderSummaryDetail) {
    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> ratingLabels = <String>[
              'Décevant',
              'Moyen',
              'Bien',
              'Très bien',
              'Excellent',
            ];

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE2D8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Laisser un avis',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF1E191B),
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comment s\'est passée votre commande avec ${orderSummaryDetail.vendorName ?? 'le vendeur'} ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6E6568),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(5, (int index) {
                        final int starValue = index + 1;
                        return IconButton(
                          iconSize: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () {
                            setModalState(() {
                              selectedRating = starValue;
                            });
                          },
                          icon: Icon(
                            starValue <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFF5C1A2B),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ratingLabels[selectedRating - 1],
                          style: const TextStyle(
                            color: Color(0xFF5C1A2B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Partagez votre avis sur l\'article et la livraison... (optionnel)',
                        hintStyle: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 13),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFD8C7CC)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFD8C7CC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF5C1A2B), width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF7F2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C1A2B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() {
                                  isSubmitting = true;
                                });

                                final String loginUserId =
                                    Utils.checkUserLoginId(valueHolder);
                                final Map<String, dynamic> jsonMap =
                                    <String, dynamic>{
                                  'order_id': orderSummaryDetail.id,
                                  'from_user_id': loginUserId,
                                  'to_user_id':
                                      orderSummaryDetail.sellerUserId,
                                  'rating': selectedRating,
                                  'title':
                                      'Avis commande #${orderSummaryDetail.orderCode ?? ''}',
                                  'description': commentController.text.trim(),
                                };

                                final PsApiService apiService = PsApiService();
                                final PsResource<ApiStatus> response =
                                    await apiService.submitOrderReview(
                                  jsonMap,
                                  loginUserId,
                                  valueHolder?.headerToken ?? '',
                                  langProvider.currentLocale.languageCode,
                                );

                                if (!mounted) return;

                                if (response.status == PsStatus.SUCCESS) {
                                  Navigator.pop(sheetContext);
                                  setState(() {
                                    orderSummaryDetail.isReviewed = '1';
                                    orderSummaryDetail.reviewRating =
                                        selectedRating.toStringAsFixed(1);
                                  });
                                  Fluttertoast.showToast(
                                    msg: 'Merci pour votre avis !',
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                  );
                                } else {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                  Fluttertoast.showToast(
                                    msg: response.message.isNotEmpty
                                        ? response.message
                                        : 'Erreur lors de l\'envoi de l\'avis',
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Envoyer l\'avis',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
