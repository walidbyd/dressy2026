import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/ps_colors.dart';
import '../../../../../config/route/route_paths.dart';
import '../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../core/vendor/provider/delete_task/delete_task_provider.dart';
import '../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../core/vendor/repository/delete_task_repository.dart';
import '../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/activity_log_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/header_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/header_with_profile_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/home_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/log_out_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/login_header_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/my_orders_menu_widget.dart';
import 'widgets/my_sales_menu_widget.dart';
import 'widgets/seller_transactions_menu_widget.dart';
import 'widgets/wallet_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/notifications_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/rate_this_app_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/setting_menu_widget.dart';
import '../../../../custom_ui/dashboard/components/drawer/widgets/share_this_app_menu_widget.dart';

class DrawerWidgetList extends StatefulWidget {
  const DrawerWidgetList(
      {required this.updateSelectedIndexWithAnimation,
      required this.callLogout,
      required this.deleteTaskProvider,
      required this.scaffoldKey});
  final Function updateSelectedIndexWithAnimation;
  final Function callLogout;
  final DeleteTaskProvider deleteTaskProvider;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  DrawerWidgetState<DrawerWidgetList> createState() =>
      DrawerWidgetState<DrawerWidgetList>();
}

class DrawerWidgetState<T extends DrawerWidgetList>
    extends State<DrawerWidgetList> {
  DeleteTaskRepository? deleteTaskRepository;
  UserRepository? userRepository;
  UserProvider? userProvider;
  @override
  Widget build(BuildContext context) {
    final PsValueHolder valueHolder = Provider.of<PsValueHolder>(context);
    return Drawer(
      child: Consumer<UserProvider>(
        builder: (BuildContext context, UserProvider provider, Widget? child) {
          print(provider.psValueHolder!.loginUserId);
          /**
             * UI SECTION 
             */
          return ListView(padding: EdgeInsets.zero, children: <Widget>[
            CustomDrawerHeaderWidget(),
            if (!Utils.isLoginUserEmpty(valueHolder))
              CustomDrawerHeaderWidgetWithUserProfile()
            else
              CustomLoginHeaderMenuWidget(
                updateSelectedIndexWithAnimation:
                    widget.updateSelectedIndexWithAnimation,
              ),
            if (!Utils.isLoginUserEmpty(valueHolder))
              const Divider(
                height: PsDimens.space1,
              ),
            CustomHomeMenuWidget(
              updateSelectedIndexWithAnimation:
                  widget.updateSelectedIndexWithAnimation,
            ),
            ListTile(
              leading: Icon(Icons.grid_view_rounded,
                  size: 22,
                  color: Utils.isLightMode(context)
                      ? PsColors.achromatic800
                      : PsColors.achromatic50),
              minLeadingWidth: 0,
              title: Text(
                'home_menu_drawer_category'.tr,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(fontWeight: FontWeight.w400),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RoutePaths.categoryList,
                    arguments: '');
              },
            ),
            if (valueHolder.vendorFeatureSetting == PsConst.ONE &&
                valueHolder.checkoutFeatureOn == PsConst.ONE)
              CustomNotificationsMenuWidget(
                updateSelectedIndexWithAnimation:
                    widget.updateSelectedIndexWithAnimation,
              ),
            const Divider(
              height: PsDimens.space1,
            ),
            if (!Utils.isLoginUserEmpty(valueHolder)) ...<Widget>[
              if (valueHolder.vendorFeatureSetting == PsConst.ONE &&
                  valueHolder.checkoutFeatureOn == PsConst.ONE) ...<Widget>[
                CustomMyOrdersMenuWidget(
                  updateSelectedIndexWithAnimation:
                      widget.updateSelectedIndexWithAnimation,
                ),
                const MySalesMenuWidget(),
                const SellerTransactionsMenuWidget(),
              ],
              const WalletMenuWidget(),
              ListTile(
                leading: Icon(Icons.local_offer_outlined,
                    size: 22,
                    color: Utils.isLightMode(context)
                        ? PsColors.achromatic800
                        : PsColors.achromatic50),
                minLeadingWidth: 0,
                title: Text(
                  'coupon__my_coupons'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.w400),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, RoutePaths.myCoupons);
                },
              ),
              ListTile(
                leading: Icon(Icons.card_giftcard_outlined,
                    size: 22,
                    color: Utils.isLightMode(context)
                        ? PsColors.achromatic800
                        : PsColors.achromatic50),
                minLeadingWidth: 0,
                title: Text(
                  'affiliation__menu_title'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.w400),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, RoutePaths.inviteFriend);
                },
              ),
            ],
            if (!Utils.isLoginUserEmpty(valueHolder))
              CustomActivityLogMenuWidget(
                updateSelectedIndexWithAnimation:
                    widget.updateSelectedIndexWithAnimation,
              ),
            const Divider(
              height: PsDimens.space1,
            ),
            CustomSettingMenuWidget(
              updateSelectedIndexWithAnimation:
                  widget.updateSelectedIndexWithAnimation,
            ),
            CustomRateThisAppMenuWidget(),
            CustomShareThisAppMenuWidget(),
            const Divider(
              height: PsDimens.space1,
            ),
            if (!Utils.isLoginUserEmpty(valueHolder))
              CustomLogoutMenuWidget(
                scaffoldKey: widget.scaffoldKey,
                callLogout: widget.callLogout,
                deleteTaskProvider: widget.deleteTaskProvider,
              ),
          ]);
        },
      ),
      //)
    );
  }
}
