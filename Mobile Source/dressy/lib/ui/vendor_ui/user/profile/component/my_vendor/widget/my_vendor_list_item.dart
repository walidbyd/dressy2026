import 'package:flutter/material.dart';
import '../../../../../../../config/ps_colors.dart';
import '../../../../../../../config/route/route_paths.dart';
import '../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../core/vendor/viewobject/holder/intent_holder/vendor_user_intent_holder.dart';
import '../../../../../../../core/vendor/viewobject/vendor_user.dart';
import '../../../../../../vendor_ui/common/ps_ui_widget.dart';

class MyVendorListItem extends StatefulWidget {
  const MyVendorListItem(
      {Key? key,
      required this.vendorUser,
      this.animation,
      this.animationController,
      this.isLoading = false,
      this.width})
      : super(key: key);

  final VendorUser vendorUser;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final bool isLoading;
  final double? width;

  @override
  State<MyVendorListItem> createState() => _MyVendorListItemState();
}

class _MyVendorListItemState extends State<MyVendorListItem> {
  void _navigateToVendorProfile(BuildContext context) {
    if (widget.vendorUser.id != null && widget.vendorUser.id!.isNotEmpty) {
      Navigator.pushNamed(
        context,
        RoutePaths.userVendorDetail,
        arguments: VendorUserIntentHolder(
          vendorId: widget.vendorUser.id,
          vendorUserId: widget.vendorUser.ownerUserId,
          vendorUserName: widget.vendorUser.name,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.animationController?.forward();
    final bool hasStory = widget.vendorUser.hasActiveStory == true;
    final bool isLight = Utils.isLightMode(context);
    final String shopName = (widget.vendorUser.name != null && widget.vendorUser.name!.isNotEmpty)
        ? widget.vendorUser.name!
        : 'default__user_name'.tr;
    final String wilaya = (widget.vendorUser.address != null && widget.vendorUser.address!.isNotEmpty)
        ? widget.vendorUser.address!
        : '';
    final String productCount = widget.vendorUser.productCount ?? '0';

    return AnimatedBuilder(
      animation: widget.animationController!,
      child: widget.isLoading
          ? const SizedBox()
          : Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: PsDimens.space6, vertical: PsDimens.space6),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : PsColors.achromatic800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLight ? const Color(0xFFE5E7EB) : PsColors.achromatic700,
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToVendorProfile(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Circular Avatar with Coral Story Ring if active story exists
                        Container(
                          width: 72,
                          height: 72,
                          padding: EdgeInsets.all(hasStory ? 2.5 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: hasStory
                                ? Border.all(color: const Color(0xFFED7768), width: 2.5)
                                : null,
                          ),
                          child: ClipOval(
                            child: widget.vendorUser.logo?.imgPath != null
                                ? PsNetworkCircleImageForUser(
                                    photoKey: '',
                                    imagePath: widget.vendorUser.logo!.imgPath,
                                    boxfit: BoxFit.cover,
                                    onTap: () => _navigateToVendorProfile(context),
                                  )
                                : CircleAvatar(
                                    backgroundColor: const Color(0xFFFDEEEB),
                                    child: Text(
                                      shopName.isNotEmpty ? shopName[0].toUpperCase() : 'D',
                                      style: const TextStyle(
                                        color: Color(0xFFED7768),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Shop Name + Verified Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                              ),
                            ),
                            if (widget.vendorUser.isVendorUser) ...<Widget>[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFFED7768),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Star Rating & Review Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.star_rounded, color: Color(0xFFFFA000), size: 16),
                            const SizedBox(width: 2),
                            Text(
                              (widget.vendorUser.overallRating != null &&
                                      widget.vendorUser.overallRating != '' &&
                                      widget.vendorUser.overallRating != '0' &&
                                      widget.vendorUser.overallRating != '0.0')
                                  ? '${widget.vendorUser.overallRating} (${widget.vendorUser.ratingCount ?? '0'})'
                                  : 'Nouveau',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLight ? PsColors.text800 : PsColors.text200,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• $productCount art.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isLight ? PsColors.text500 : PsColors.text400,
                              ),
                            ),
                          ],
                        ),

                        // Wilaya / Location
                        if (wilaya.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: isLight ? PsColors.text500 : PsColors.text400,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  wilaya,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isLight ? PsColors.text500 : PsColors.text400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
            opacity: widget.animation ?? const AlwaysStoppedAnimation<double>(1.0),
            child: Transform(
                transform: Matrix4.translationValues(
                    0.0, 100 * (1.0 - (widget.animation?.value ?? 1.0)), 0.0),
                child: child));
      },
    );
  }
}
