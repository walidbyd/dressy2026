import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/vendor/provider/chat/user_unread_message_provider.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../core/vendor/provider/product/item_entry_provider.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../core/vendor/viewobject/vendor_list.dart';

class BottomNaviationWidget extends StatefulWidget {
  const BottomNaviationWidget(
      {required this.currentIndex,
      required this.updateSelectedIndexWithAnimation});
  final int? currentIndex;
  final Function updateSelectedIndexWithAnimation;
  @override
  BottomNavigationWidgetState<BottomNaviationWidget> createState() =>
      BottomNavigationWidgetState<BottomNaviationWidget>();
}

class BottomNavigationWidgetState<T extends BottomNaviationWidget>
    extends State<BottomNaviationWidget> {
  late PsValueHolder psValueHolder;
  late UserProvider provider;
  late AppLocalization langProvider;
  late ItemEntryFieldProvider itemEntryFieldProvider;

  @override
  Widget build(BuildContext context) {
    psValueHolder = Provider.of<PsValueHolder>(context);
    provider = Provider.of<UserProvider>(context);
    langProvider = Provider.of<AppLocalization>(context);
    itemEntryFieldProvider = Provider.of<ItemEntryFieldProvider>(context);

    if (!isCorrectIndex()) {
      return const SizedBox();
    }

    int unreadCount = 0;
    try {
      final UserUnreadMessageProvider? unreadProvider =
          Provider.of<UserUnreadMessageProvider?>(context, listen: false);
      if (unreadProvider?.userUnreadMessage.data != null) {
        unreadCount = (int.tryParse(unreadProvider!.userUnreadMessage.data!.sellerUnreadCount ?? '0') ?? 0) +
            (int.tryParse(unreadProvider.userUnreadMessage.data!.buyerUnreadCount ?? '0') ?? 0);
      }
    } catch (_) {}

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final int navIndex = getBottonNavigationIndex(widget.currentIndex);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(
              top: BorderSide(
                color: Color(0xFFEAE2D8),
                width: 1.0,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x0D2A151B),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: <Widget>[
                  _buildNavItem(
                    index: 0,
                    label: 'Accueil',
                    inactiveIcon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    currentIndex: navIndex,
                  ),
                  _buildNavItem(
                    index: 1,
                    label: 'Messages',
                    inactiveIcon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    currentIndex: navIndex,
                    showBadge: unreadCount > 0,
                  ),
                  const Expanded(
                    child: SizedBox(height: 68),
                  ),
                  _buildNavItem(
                    index: 3,
                    label: 'Favoris',
                    inactiveIcon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    currentIndex: navIndex,
                  ),
                  _buildNavItem(
                    index: 4,
                    label: 'Profil',
                    inactiveIcon: Icons.person_outline,
                    activeIcon: Icons.person,
                    currentIndex: navIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: bottomPadding + 10,
          child: _buildCenterSellButton(),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData inactiveIcon,
    required IconData activeIcon,
    required int currentIndex,
    bool showBadge = false,
  }) {
    final bool isSelected = currentIndex == index;
    const Color activeColor = Color(0xFF5C1A2B);
    const Color inactiveColor = Color(0xFF6E6568);
    final Color itemColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: () {
            final dynamic returnValue =
                getIndexFromBottonNavigationIndex(index);
            widget.updateSelectedIndexWithAnimation(
                returnValue[0], returnValue[1]);
          },
          splashColor: const Color(0x1A5C1A2B),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    size: 22,
                    color: itemColor,
                  ),
                  if (showBadge)
                    Positioned(
                      top: -1,
                      right: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5C1A2B),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: itemColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterSellButton() {
    return GestureDetector(
      onTap: () {
        final dynamic returnValue = getIndexFromBottonNavigationIndex(2);
        widget.updateSelectedIndexWithAnimation(
            returnValue[0], returnValue[1]);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF5C1A2B),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x335C1A2B),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Vendre',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C1A2B),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  int getBottonNavigationIndexWithoutAddIcon(int? param) {
    int index = 0;
    switch (param) {
      case PsConst.REQUEST_CODE__MENU_HOME_FRAGMENT:
        index = 0;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_MESSAGE_FRAGMENT:
        index = 1;
        break;
      case PsConst.REQUEST_CODE__MENU_FAVOURITE_FRAGMENT:
        index = 2;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_SELECT_WHICH_USER_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_REGISTER_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_FORGOT_PASSWORD_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_VERIFY_FORGOT_PASSWORD_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_UPDATE_FORGOT_PASSWORD_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_LOGIN_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_VERIFY_EMAIL_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_USER_PROFILE_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_PHONE_SIGNIN_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_PHONE_VERIFY_FRAGMENT:
        index = 3;
        break;
      default:
        index = 0;
        break;
    }
    return index;
  }

  int getBottonNavigationIndex(int? param) {
    int index = 0;
    switch (param) {
      case PsConst.REQUEST_CODE__MENU_HOME_FRAGMENT:
        index = 0;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_MESSAGE_FRAGMENT:
        index = 1;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_ITEM_UPLOAD_FRAGMENT:
        index = 2;
        break;
      case PsConst.REQUEST_CODE__MENU_FAVOURITE_FRAGMENT:
        index = 3;
        break;
      case PsConst.REQUEST_CODE__DASHBOARD_USER_PROFILE_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_SELECT_WHICH_USER_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_LOGIN_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_REGISTER_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_FORGOT_PASSWORD_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_VERIFY_FORGOT_PASSWORD_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_UPDATE_FORGOT_PASSWORD_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_VERIFY_EMAIL_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_PHONE_SIGNIN_FRAGMENT:
      case PsConst.REQUEST_CODE__DASHBOARD_PHONE_VERIFY_FRAGMENT:
        index = 4;
        break;
      default:
        index = 0;
        break;
    }
    return index;
  }

  dynamic getIndexFromBottonNavigationIndex(int param) {
    int index = PsConst.REQUEST_CODE__MENU_HOME_FRAGMENT;
    String title;
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    // 5 items are always present: 0: Home, 1: Message, 2: Sell (+), 3: Favs, 4: Profile
    switch (param) {
      case 0:
        index = PsConst.REQUEST_CODE__MENU_HOME_FRAGMENT;
        title = 'app_name'.tr;
        break;
      case 1:
        index = PsConst.REQUEST_CODE__DASHBOARD_MESSAGE_FRAGMENT;
        title = Utils.isLoginUserEmpty(psValueHolder)
            ? 'home_login'.tr
            : 'dashboard__bottom_navigation_message'.tr;
        break;
      case 2:
        index = PsConst.REQUEST_CODE__DASHBOARD_ITEM_UPLOAD_FRAGMENT;
        title = Utils.isLoginUserEmpty(psValueHolder) ? 'home_login'.tr : ''.tr;
        break;
      case 3:
        index = PsConst.REQUEST_CODE__MENU_FAVOURITE_FRAGMENT;
        title = Utils.isLoginUserEmpty(psValueHolder)
            ? 'home_login'.tr
            : 'home__menu_drawer_favourite'.tr;
        break;
      case 4:
        index = PsConst.REQUEST_CODE__DASHBOARD_SELECT_WHICH_USER_FRAGMENT;
        title = Utils.isLoginUserEmpty(psValueHolder)
            ? 'home_login'.tr
            : 'home__bottom_app_bar_login'.tr;
        break;

      default:
        index = 0;
        title = ''; //Utils.getString(context, 'app_name');
        break;
    }
    return <dynamic>[title, index];
  }

  bool isCorrectIndex() {
    return widget.currentIndex == PsConst.REQUEST_CODE__MENU_HOME_FRAGMENT ||
        widget.currentIndex == PsConst.REQUEST_CODE__DASHBOARD_MESSAGE_FRAGMENT ||
        widget.currentIndex == PsConst.REQUEST_CODE__MENU_FAVOURITE_FRAGMENT ||
        widget.currentIndex == PsConst.REQUEST_CODE__DASHBOARD_USER_PROFILE_FRAGMENT ||
        widget.currentIndex == PsConst.REQUEST_CODE__DASHBOARD_SELECT_WHICH_USER_FRAGMENT ||
        widget.currentIndex == PsConst.REQUEST_CODE__DASHBOARD_LOGIN_FRAGMENT;
  }

  bool get isUserHasVendor {
    final List<VendorList> vendorList =
        itemEntryFieldProvider.itemEntryField.data?.vendorList ??
            <VendorList>[];
    if (psValueHolder.loginUserId == '1') {
      return true;
    } else if (vendorList.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  bool get isUserValid {
    //allow all users, if logined or not
    if (psValueHolder.uploadSetting == PsConst.UPLOAD_SETTING_ALL) {
      return true;
    } else {
      if (Utils.isLoginUserEmpty(psValueHolder)) {
        //login user is empty, don't show item-add button
        return false;
      } else {
        /*load user data*/
        if (provider.hasData &&
            provider.data.data!.userId != psValueHolder.loginUserId) {
          provider.getUser(psValueHolder.loginUserId ?? '',
              langProvider.currentLocale.languageCode);
        }

        //only admin and bluemark users are allowed
        if (psValueHolder.uploadSetting ==
            PsConst.UPLOAD_SETTING_ADMIN_AND_BLUEMARK) {
          return provider.hasData &&
              (provider.user.data!.roleId == PsConst.ONE ||
                  provider.user.data!.isVefifiedBlueMarkUser);
        }
        //only admin is allowed
        else if (psValueHolder.uploadSetting ==
            PsConst.UPLOAD_SETTING_ONLY_ADMIN) {
          return provider.hasData && provider.user.data!.roleId == PsConst.ONE;
        } else if (psValueHolder.uploadSetting == 'vendor-only') {
          return isUserHasVendor;
        } else {
          return false;
        }
      }
    }
  }
}
