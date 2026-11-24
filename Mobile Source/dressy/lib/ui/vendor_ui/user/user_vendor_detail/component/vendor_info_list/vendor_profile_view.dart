import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/vendor_application/vendor_branch_provider.dart';
import '../../../../../../core/vendor/provider/vendor_application/vendor_user_detail_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../custom_ui/user/user_vendor_detail/component/detail_info/widgets/other_user_vendor_logo_photo.dart';
import '../../../../../custom_ui/user/user_vendor_detail/component/vendor_info_list/vendor_branch/vendor_branch_item.dart';
import '../../../../item/detail/component/info_widgets/vendor_expired_widget.dart';

class VendorProfileView extends StatefulWidget {
  @override
  State<VendorProfileView> createState() => _VendorProfileViewState();
}

class _VendorProfileViewState extends State<VendorProfileView> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final VendorUserDetailProvider provider =
        Provider.of<VendorUserDetailProvider>(context);
    final VendorBranchProvider vendorBranchProvider =
        Provider.of<VendorBranchProvider>(context);
    return provider.hasData
        ? ListView(children: <Widget>[
            if (provider.vendorUserDetail.data?.expiredStatus ==
                PsConst.EXPIRED_NOTI)
              Container(
                  margin: const EdgeInsets.only(
                      left: PsDimens.space12,
                      right: PsDimens.space12,
                      top: PsDimens.space4),
                  child: VendorExpiredWidget(
                      vendorExpText: 'vendor_expired_text'.tr))
            else
              const SizedBox(),
            Container(
                margin: const EdgeInsets.all(PsDimens.space12),
                padding: const EdgeInsets.only(
                    left: PsDimens.space10,
                    right: PsDimens.space10,
                    top: PsDimens.space24),
                decoration: BoxDecoration(
                    color: Utils.isLightMode(context)
                        ? PsColors.achromatic50
                        : PsColors.achromatic700,
                    border: Border.all(
                        color: Utils.isLightMode(context)
                            ? PsColors.achromatic100
                            : PsColors.achromatic700)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          CustomOtherUserVendorLogoPhoto(),
                          Positioned(
                            bottom: 0,
                            right: -1,
                            child: Icon(
                              Icons.verified_user,
                              color: PsColors.info500,
                              size: PsDimens.space16,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            provider.vendorUserDetail.data!.name ?? '',
                            textAlign: TextAlign.start,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                            maxLines: 1,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: PsDimens.space4),
                            child: Image.asset(
                              'assets/images/storefont.png',
                              width: PsDimens.space16,
                              height: PsDimens.space16,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            provider.vendorUserDetail.data!.productCount ?? '0',
                            textAlign: TextAlign.start,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: PsDimens.space4),
                            child: Text(
                              'vendor_page_products'.tr,
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400),
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            width: PsDimens.space1,
                            height: PsDimens.space10,
                            color: PsColors.achromatic500,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: PsDimens.space4),
                            child: Text(
                              'vendor_page_joned_date'.tr,
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400),
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            provider.vendorUserDetail.data?.addedDate == ''
                                ? ''
                                : Utils.getDateFormat(
                                    provider.vendorUserDetail.data?.addedDate,
                                    'dd/MM/yyyy'),
                            textAlign: TextAlign.start,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                          ),
                        ],
                      ),
                      if ((provider.vendorUserDetail.data!.description ?? '').isNotEmpty)
                        Text(provider.vendorUserDetail.data!.description ?? '',
                            textAlign: TextAlign.start,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                    fontWeight: FontWeight.w400, fontSize: 14)),
                    ])),
            if (vendorBranchProvider.hasData)
              Padding(
                padding: const EdgeInsets.only(
                    left: PsDimens.space12,
                    right: PsDimens.space8,
                    bottom: PsDimens.space4,
                    top: PsDimens.space8),
                child: Text('vendor_branches'.tr,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ListView.builder(
                shrinkWrap: true,
                controller: scrollController,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vendorBranchProvider.vendorBranchList.data!.length,

                /// modifty later
                itemBuilder: (BuildContext context, int index) {
                  return CustomVendorBranchItem(
                    vendorBranch:
                        vendorBranchProvider.vendorBranchList.data![index],
                    onTap: () {},
                  );
                }),
          ])
        : const SizedBox();
  }
}
