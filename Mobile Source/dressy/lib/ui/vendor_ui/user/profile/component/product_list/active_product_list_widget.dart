import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../core/vendor/db/common/ps_data_source_manager.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/product/added_item_provider.dart';
import '../../../../../../core/vendor/utils/ps_animation.dart';
import '../../../../../../core/vendor/viewobject/holder/intent_holder/item_list_intent_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../custom_ui/item/list_item/product_horizontal_list_widget.dart';
import '../../../../../custom_ui/item/list_item/product_vertical_list_item.dart';
import '../../../../common/ps_list_header_widget.dart';

class ActiveProductListWidget extends StatelessWidget {
  const ActiveProductListWidget({Key? key, required this.animationController})
      : super(key: key);

  final AnimationController? animationController;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animation = curveAnimation(animationController!);
    return SliverToBoxAdapter(child: Consumer<AddedItemProvider>(builder:
        (BuildContext context, AddedItemProvider productProvider,
            Widget? child) {
      final bool isLoading =
          productProvider.currentStatus == PsStatus.BLOCK_LOADING;
      final int itemCount =
          isLoading ? 4 : (productProvider.itemList.data?.length ?? 0);
      return AnimatedBuilder(
          animation: animationController!,
          child: (isLoading || productProvider.hasData)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    PsListHeaderWidget(
                      headerName: 'profile__listing'.tr,
                      viewAllClicked: () {
                        Navigator.pushNamed(context, RoutePaths.userItemList,
                            arguments: ItemListIntentHolder(
                                userId:
                                    productProvider.psValueHolder!.loginUserId,
                                status: '1',
                                title: 'profile__listing'.tr));
                      },
                    ),
                    if (itemCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 0.58,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (BuildContext context, int index) {
                            return CustomProductVeticalListItem(
                              isLoading: isLoading,
                              coreTagKey: productProvider.hashCode.toString(),
                              product: isLoading
                                  ? Product()
                                  : productProvider.itemList.data![index],
                              animation: curveAnimation(animationController!,
                                  index: index, count: itemCount),
                              animationController: animationController!,
                              onTap: () {
                                if (productProvider.psValueHolder?.loginUserId != null) {
                                  productProvider.addedUserParameterHolder.addedUserId =
                                      productProvider.psValueHolder!.loginUserId;
                                  productProvider.addedUserParameterHolder.status = '1';
                                  productProvider.loadDataList(
                                    dataConfig: DataConfiguration(
                                        dataSourceType: DataSourceType.SERVER_DIRECT),
                                    requestPathHolder: RequestPathHolder(
                                        loginUserId: productProvider.psValueHolder!.loginUserId,
                                        languageCode: productProvider.psValueHolder!.languageCode),
                                    requestBodyHolder: productProvider.addedUserParameterHolder,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    // Keep horizontal list hidden cleanly to preserve existing widget
                    Visibility(
                      visible: false,
                      maintainState: true,
                      child: CustomProductHorizontalListWidget(
                        isLoading: isLoading,
                        productList: productProvider.itemList.data,
                        tagKey: productProvider.hashCode.toString(),
                      ),
                    ),
                  ],
                )
              : const SizedBox(),
          builder: (BuildContext context, Widget? child) {
            return FadeTransition(
                opacity: animation!,
                child: Transform(
                    transform: Matrix4.translationValues(
                        0.0, 100 * (1.0 - animation.value), 0.0),
                    child: child));
          });
    }));
  }
}
