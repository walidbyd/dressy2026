import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/order_history.dart';
import '../../../custom_ui/my_orders/component/widget/order_item_widget.dart';
import '../../../custom_ui/my_orders/component/widget/order_tab_widget.dart';

class MySalesListView extends StatefulWidget {
  const MySalesListView({Key? key}) : super(key: key);

  @override
  State<MySalesListView> createState() => _MySalesListViewState();
}

class _MySalesListViewState extends State<MySalesListView> {
  bool _isLoading = true;
  List<OrderHistory> _allOrders = <OrderHistory>[];
  List<OrderHistory> _pendingOrders = <OrderHistory>[];
  List<OrderHistory> _approvedOrders = <OrderHistory>[];
  List<OrderHistory> _deliveringOrders = <OrderHistory>[];
  List<OrderHistory> _deliveredOrders = <OrderHistory>[];
  List<OrderHistory> _cancelledOrders = <OrderHistory>[];
  List<OrderHistory> _returnedOrders = <OrderHistory>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
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

    final PsResource<List<OrderHistory>> res = await apiService.getSellerOrders(
      <dynamic, dynamic>{'noPagination': '1'},
      loginUserId,
      100,
      0,
      languageCode,
    );

    if (mounted) {
      if (res.data != null) {
        final List<OrderHistory> all = res.data!;
        final List<OrderHistory> pending = <OrderHistory>[];
        final List<OrderHistory> approved = <OrderHistory>[];
        final List<OrderHistory> delivering = <OrderHistory>[];
        final List<OrderHistory> delivered = <OrderHistory>[];
        final List<OrderHistory> cancelled = <OrderHistory>[];
        final List<OrderHistory> returned = <OrderHistory>[];

        for (final OrderHistory order in all) {
          final String status = (order.orderStatus ?? '').toLowerCase();
          final String statusId = order.orderStatusId ?? '';
          if (statusId == '1' || status == 'pending') {
            pending.add(order);
          } else if (statusId == '2' || status == 'approved' || status == 'accepted') {
            approved.add(order);
          } else if (statusId == '3' || status == 'delivering' || status == 'dispatched') {
            delivering.add(order);
          } else if (statusId == '4' || status == 'delivered') {
            delivered.add(order);
          } else if (statusId == '5' || status == 'cancelled') {
            cancelled.add(order);
          } else if (statusId == '6' || status == 'returned') {
            returned.add(order);
          }
        }

        setState(() {
          _allOrders = all;
          _pendingOrders = pending;
          _approvedOrders = approved;
          _deliveringOrders = delivering;
          _deliveredOrders = delivered;
          _cancelledOrders = cancelled;
          _returnedOrders = returned;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allOrders = <OrderHistory>[];
          _pendingOrders = <OrderHistory>[];
          _approvedOrders = <OrderHistory>[];
          _deliveringOrders = <OrderHistory>[];
          _deliveredOrders = <OrderHistory>[];
          _cancelledOrders = <OrderHistory>[];
          _returnedOrders = <OrderHistory>[];
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildOrderList(List<OrderHistory> orders) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Text(
                    'seller__no_orders'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Utils.isLightMode(context)
                              ? PsColors.text800
                              : PsColors.achromatic50,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
            horizontal: PsDimens.space12, vertical: PsDimens.space8),
        itemCount: orders.length,
        itemBuilder: (BuildContext context, int index) {
          final OrderHistory order = orders[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.of(context).pushNamed(
                RoutePaths.sellerOrderDetail,
                arguments: <String, dynamic>{
                  'orderId': order.id,
                },
              );
              _loadOrders();
            },
            child: CustomOrderItemWidget(
              itemCount: order.itemCount,
              orderCode: order.orderCode,
              orderStatus: order.orderStatus,
              paymentDate: order.paymentDate,
              total: order.total,
              orderStatusColor: order.orderStatusColor,
              isDeliveredAndPaid: order.isDeliveredAndPaid,
              deliveredAndPaidLabel: order.deliveredAndPaidLabel,
              itemInfo: order.itemInfo,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
          ),
          title: Text(
            'home__menu_drawer_my_sales'.tr,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Utils.isLightMode(context)
                      ? PsColors.achromatic900
                      : PsColors.achromatic50,
                  fontWeight: FontWeight.w500,
                  fontSize: PsDimens.space18,
                ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'seller_sales_transactions_title'.tr,
              onPressed: () {
                Navigator.of(context).pushNamed(RoutePaths.sellerTransactions);
              },
            ),
          ],
          bottom: TabBar(
            tabAlignment: TabAlignment.start,
            labelStyle: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            isScrollable: true,
            labelColor: PsColors.primary500,
            indicatorColor: PsColors.primary500,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: <Widget>[
              CustomOrderTabWidget(text: 'order_all'.tr),
              CustomOrderTabWidget(text: 'order_pending'.tr),
              CustomOrderTabWidget(text: 'order_approved'.tr),
              CustomOrderTabWidget(text: 'order_delivering'.tr),
              CustomOrderTabWidget(text: 'order_delivered'.tr),
              CustomOrderTabWidget(text: 'order_cancelled'.tr),
              CustomOrderTabWidget(text: 'order_returned'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildOrderList(_allOrders),
            _buildOrderList(_pendingOrders),
            _buildOrderList(_approvedOrders),
            _buildOrderList(_deliveringOrders),
            _buildOrderList(_deliveredOrders),
            _buildOrderList(_cancelledOrders),
            _buildOrderList(_returnedOrders),
          ],
        ),
      ),
    );
  }
}
