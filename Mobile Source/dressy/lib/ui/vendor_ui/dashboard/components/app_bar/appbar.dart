import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/constant/ps_constants.dart';

import '../../../../../config/route/route_paths.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../custom_ui/add_to_cart/components/appbar_shopping_cart_icon.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    required this.appBarTitle,
    required this.appBarTitleName,
    required this.currentIndex,
  });
  final String appBarTitle;
  final String appBarTitleName;
  final int? currentIndex;

  @override
  Widget build(BuildContext context) {
    final PsValueHolder valueHolder = Provider.of<PsValueHolder>(context);
    final bool hideAppbar = (Utils.showFavoriteProduct(currentIndex) &&
            !Utils.isLoginUserEmpty(valueHolder)) ||
        Utils.showPopularProductView(currentIndex) ||
        Utils.showFeaturedProductView(currentIndex) ||
        Utils.showNotificationsView(currentIndex) ||
        Utils.showProfileView(currentIndex, valueHolder) ||
        Utils.showChatListView(currentIndex);

    if (hideAppbar) {
      return const SizedBox();
    }
    final bool isHome = Utils.showHomeDashboardView(currentIndex);
    final String locationText = (valueHolder.locactionName != null &&
            valueHolder.locactionName!.isNotEmpty)
        ? valueHolder.locactionName!
        : (valueHolder.locationTownshipName.isNotEmpty
            ? valueHolder.locationTownshipName
            : 'Alger, DZ');

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: isHome
          ? Builder(
              builder: (BuildContext ctx) => IconButton(
                icon: const Icon(Icons.menu),
                color: Utils.isLightMode(context)
                    ? PsColors.achromatic900
                    : PsColors.achromatic50,
                onPressed: () {
                  Scaffold.of(ctx).openDrawer();
                },
              ),
            )
          : null,
      title: isHome
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 28, maxWidth: 120),
              child: Image.asset(
                'assets/images/LOGO_DRESSY.png',
                fit: BoxFit.contain,
              ),
            )
          : Text(
              appBarTitleName == '' ? appBarTitle : appBarTitleName,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Utils.isLightMode(context)
                      ? PsColors.achromatic900
                      : PsColors.achromatic50),
            ),
      titleSpacing: isHome ? 0 : 0,
      elevation: 0,
      iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      titleTextStyle: const TextStyle(
          fontFamily: PsConst.ps_default_font_family,
          fontWeight: FontWeight.bold,
          fontSize: 18),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
      ),
      actions: isHome
          ? <Widget>[
              // Location indicator cleanly hidden on home app bar
              Visibility(
                visible: false,
                maintainState: true,
                child: Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RoutePaths.itemLocationList,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Utils.isLightMode(context)
                            ? PsColors.achromatic100
                            : PsColors.achromatic700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: PsColors.burgundy,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 85),
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Utils.isLightMode(context)
                                    ? PsColors.text800
                                    : PsColors.text100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Top-Right Chabit AI Assistant Button
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Utils.navigateOnUserVerificationView(context, () async {
                        Navigator.pushNamed(context, RoutePaths.chabitChat);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: PsColors.burgundy.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: PsColors.burgundy.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: PsColors.burgundy,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PsColors.burgundy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CustomAppbarShoppingCartIcon(),
              const SizedBox(
                width: 12,
              )
            ]
          : null,
    );
  }

  @override
  Size get preferredSize =>
      Utils.showChatListView(currentIndex)
          ? Size.zero
          : const Size.fromHeight(kToolbarHeight);
}
