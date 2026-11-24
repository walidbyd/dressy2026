import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';

import '../../../../../../core/vendor/provider/category/category_provider.dart';
import '../../../../../../core/vendor/provider/chat/user_unread_message_provider.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/product/search_product_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/product_parameter_holder.dart';
import '../../../../../config/ps_config.dart';
import '../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../core/vendor/viewobject/holder/user_unread_message_parameter_holder.dart';
import '../../../../../core/vendor/viewobject/holder/widget_provider_dyanmic.dart';
import '../../../common/dialog/set_user_name_and_pwd_dialog.dart';
import '../../../sort_widget/ps_dynamic_provider.dart';
import '../../../sort_widget/ps_dynamic_widget.dart';
import '../component/detail_info/widgets/profile_pop_up.dart';

class ProfileView extends StatefulWidget {
  const ProfileView(
      {Key? key,
      required this.animationController,
      required this.flag,
      required this.userId,
      required this.scaffoldKey,
      required this.callLogoutCallBack,
      required this.onDeactivate,
      required this.loadUserData,
      required this.isJustLogined,
      required this.changeIsJustLoginToFalse})
      : super(key: key);

  final AnimationController animationController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final int? flag;
  final String? userId;
  final Function callLogoutCallBack, onDeactivate, loadUserData;
  final bool isJustLogined;
  final Function changeIsJustLoginToFalse;
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  PsValueHolder? psValueHolder;

  bool firstTime = true;
  ScrollController scrollController = ScrollController();
  AnimationController? animationControllerForFab;
  late AppLocalization langProvider;
  bool isFirstTime = true;
  WidgetProviderDynamic? widgetProviderDynamic = WidgetProviderDynamic(
      providerList: <String>[''], widgetList: <String>['']);

  @override
  void initState() {
    animationControllerForFab = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this, value: 1);

    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (animationControllerForFab != null) {
          animationControllerForFab!.reverse();
        }
      }
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (animationControllerForFab != null) {
          animationControllerForFab!.forward();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (psValueHolder?.loginUserId == null ||
          psValueHolder?.loginUserId == '' ||
          psValueHolder?.loginUserId == 'nologinuser') {
        if (widget.userId != null &&
            widget.userId!.isNotEmpty &&
            widget.userId != 'nologinuser') {
          widget.loadUserData(widget.userId!);
        }
      } else {
        widget.loadUserData(psValueHolder!.loginUserId);
      }

      if (psValueHolder != null && !Utils.isLoginUserEmpty(psValueHolder!)) {
        final UserUnreadMessageProvider userUnreadMessageProvider =
            Provider.of<UserUnreadMessageProvider>(context, listen: false);
        final UserUnreadMessageParameterHolder userUnreadMessageHolder =
            UserUnreadMessageParameterHolder(
                userId: psValueHolder!.loginUserId,
                deviceToken: psValueHolder!.deviceToken);
        userUnreadMessageProvider.loadData(
            requestPathHolder: RequestPathHolder(
                loginUserId: psValueHolder!.loginUserId,
                headerToken: psValueHolder!.headerToken),
            requestBodyHolder: userUnreadMessageHolder);
      }
      
      if (widget.isJustLogined && psValueHolder!.isUserNameNeeded &&
          !psValueHolder!.isAppleLoginUser) {
        widget.changeIsJustLoginToFalse();
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext contet) {
              return SetUserNameAndPwdDialog(
                userId: psValueHolder!.loginUserId!,
              );
            });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    psValueHolder = Provider.of<PsValueHolder>(context);
    widget.animationController.forward();

    if (isFirstTime) {
      final WidgetProviderDynamic widgetprovider =
          Utils.psWidgetToProvider(PsConfig.profileDetailsWidgetList);
      widgetProviderDynamic!.widgetList!.addAll(widgetprovider.widgetList!);
      widgetProviderDynamic!.providerList!.addAll(widgetprovider.providerList!);
      widgetProviderDynamic!.widgetList!.add('sizedbox_80');

      isFirstTime = false;
    }

    widgetProviderDynamic!.widgetList =
        widgetProviderDynamic!.widgetList!.toSet().toList();

    return MultiProvider(
        providers: psDynamicProvider(context, (Function fn) {},
            categoryProvider: (CategoryProvider pro) {},
            providerList: widgetProviderDynamic!.providerList!,
            searchProductProvider: (SearchProductProvider pro) {},
            productParameterHolder:
                ProductParameterHolder().getPopularParameterHolder(),
            userId: widget.userId),
        child: SafeArea(
          bottom: false,
          child: Scaffold(
            appBar: AppBar(
              primary: false,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              toolbarHeight: 60,
              leading: IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.menu),
                color: Utils.isLightMode(context)
                    ? PsColors.achromatic900
                    : PsColors.achromatic50,
                onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                'profile__title'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Utils.isLightMode(context)
                          ? PsColors.achromatic900
                          : PsColors.achromatic50,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              centerTitle: false,
              actions: <Widget>[
                IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.share_outlined, size: 22),
                  tooltip: 'share_profile'.tr,
                  onPressed: () {
                    final String shareUserId =
                        psValueHolder?.loginUserId ?? widget.userId ?? '';
                    final String profileUrl =
                        'https://dressy-dz.com/profile/$shareUserId';
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Découvrez mon dressing sur Dressy !\n$profileUrl',
                      ),
                    );
                  },
                ),
                IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  tooltip: 'edit_profile__title'.tr,
                  onPressed: () async {
                    final dynamic result = await Navigator.pushNamed(
                        context, RoutePaths.editProfile);
                    if (result == true) {
                      widget.loadUserData(psValueHolder?.loginUserId);
                    }
                  },
                ),
                ProfilePopUpWidget(
                  callLogout: widget.callLogoutCallBack,
                  onDeactivate: widget.onDeactivate,
                  scaffoldKey: widget.scaffoldKey,
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: PsDynamicWidget(
                isGrid: true,
                animationController: widget.animationController,
                scrollController: scrollController,
                widgetList: widgetProviderDynamic!.widgetList,
                callLogoutCallBack: widget.callLogoutCallBack),
          ),
        ));
  }
}
