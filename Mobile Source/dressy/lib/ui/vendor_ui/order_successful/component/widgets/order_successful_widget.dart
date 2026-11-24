import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/ps_colors.dart';
import '../../../../../config/route/route_paths.dart';
import '../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/provider/order_id/order_id_provider.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../common/ps_button_widget_with_round_corner.dart';
import 'order_success_photo_widget.dart';

class OrderSuccessfulWidget extends StatelessWidget {
  const OrderSuccessfulWidget({
    Key? key,
    required this.orderId,
    this.totalPrice = '',
    this.currencySymbol = 'DA',
  }) : super(key: key);

  final String orderId;
  final String totalPrice;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);
    final String sym = currencySymbol.isNotEmpty ? currencySymbol : 'DA';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PsDimens.space20, vertical: PsDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Top Bar Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isLight ? PsColors.text800 : PsColors.text50,
                  ),
                  onPressed: () {
                    Provider.of<OrderIdProvider>(context, listen: false).clearAddress();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RoutePaths.home,
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ),

              // Hero Illustration
              OrderSuccessfulPhotoWidget(),
              const SizedBox(height: PsDimens.space16),

              // Title: "Thank you for your order!"
              Text(
                'order_successful__thank_you'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLight ? PsColors.text900 : PsColors.text50,
                    ),
              ),
              const SizedBox(height: PsDimens.space8),

              // Order Code Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: PsDimens.space16, vertical: PsDimens.space6),
                decoration: BoxDecoration(
                  color: isLight ? PsColors.primary50 : PsColors.achromatic800,
                  borderRadius: BorderRadius.circular(PsDimens.space20),
                  border: Border.all(color: PsColors.primary500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.receipt_long, size: 18, color: PsColors.primary500),
                    const SizedBox(width: PsDimens.space6),
                    Text(
                      '${'order_successful__order_code'.tr}: #$orderId',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: PsColors.primary500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PsDimens.space20),

              // Order Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PsDimens.space16),
                decoration: BoxDecoration(
                  color: isLight ? PsColors.achromatic50 : PsColors.achromatic800,
                  borderRadius: BorderRadius.circular(PsDimens.space12),
                  border: Border.all(
                      color: isLight ? PsColors.achromatic100 : PsColors.achromatic700),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'order_successful__total_to_pay'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isLight ? PsColors.text600 : PsColors.text300,
                              ),
                        ),
                        Text(
                          totalPrice.isNotEmpty ? '$totalPrice $sym' : '-- $sym',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: PsColors.primary500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PsDimens.space12),
                    Divider(
                      height: 1,
                      color: isLight ? PsColors.achromatic200 : PsColors.achromatic700,
                    ),
                    const SizedBox(height: PsDimens.space12),
                    Row(
                      children: <Widget>[
                        Icon(Icons.local_shipping_outlined,
                            size: 20, color: PsColors.primary500),
                        const SizedBox(width: PsDimens.space8),
                        Expanded(
                          child: Text(
                            'order_successful__yalidine_notice'.tr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isLight ? PsColors.text700 : PsColors.text200,
                                  height: 1.3,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PsDimens.space20),

              // Next Steps Guidance Timeline
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PsDimens.space16),
                decoration: BoxDecoration(
                  color: isLight ? PsColors.achromatic50 : PsColors.achromatic800,
                  borderRadius: BorderRadius.circular(PsDimens.space12),
                  border: Border.all(
                      color: isLight ? PsColors.achromatic100 : PsColors.achromatic700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'order_successful__next_steps_title'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLight ? PsColors.text900 : PsColors.text50,
                          ),
                    ),
                    const SizedBox(height: PsDimens.space14),
                    _buildStepRow(
                      context,
                      stepNumber: '1',
                      title: 'order_step_1_title'.tr,
                      desc: 'order_step_1_desc'.tr,
                      isLight: isLight,
                    ),
                    const SizedBox(height: PsDimens.space12),
                    _buildStepRow(
                      context,
                      stepNumber: '2',
                      title: 'order_step_2_title'.tr,
                      desc: 'order_step_2_desc'.tr,
                      isLight: isLight,
                    ),
                    const SizedBox(height: PsDimens.space12),
                    _buildStepRow(
                      context,
                      stepNumber: '3',
                      title: 'order_step_3_title'.tr,
                      desc: 'order_step_3_desc'.tr,
                      isLight: isLight,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PsDimens.space24),

              // Primary Action: Track My Order
              PSButtonWidgetRoundCorner(
                titleTextColor: PsColors.text50,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RoutePaths.orderDetail,
                    arguments: <String, dynamic>{
                      'orderId': orderId,
                    },
                  );
                },
                titleText: 'order_successful__track_order'.tr,
              ),
              const SizedBox(height: PsDimens.space12),

              // Secondary Action: Continue Shopping
              SizedBox(
                width: double.infinity,
                height: PsDimens.space44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: PsColors.primary500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PsDimens.space24),
                    ),
                  ),
                  onPressed: () {
                    Provider.of<OrderIdProvider>(context, listen: false).clearAddress();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RoutePaths.home,
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text(
                    'order_successful_continue_shopping'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: PsColors.primary500,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: PsDimens.space20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String desc,
    required bool isLight,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 12,
          backgroundColor: PsColors.primary500,
          child: Text(
            stepNumber,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(width: PsDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLight ? PsColors.text800 : PsColors.text100,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLight ? PsColors.text500 : PsColors.text400,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
