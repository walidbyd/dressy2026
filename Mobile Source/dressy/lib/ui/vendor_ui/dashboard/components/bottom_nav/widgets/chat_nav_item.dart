import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../core/vendor/provider/chat/user_unread_message_provider.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../common/dialog/chat_noti_dialog.dart';

class ChatIconWithUnreadCount extends StatefulWidget {
  const ChatIconWithUnreadCount(
      {required this.updateSelectedIndexWithAnimation});
  final Function updateSelectedIndexWithAnimation;
  @override
  State<StatefulWidget> createState() =>
      ChatIconWithUnreadCountState<ChatIconWithUnreadCount>();
}

class ChatIconWithUnreadCountState<T extends ChatIconWithUnreadCount>
    extends State<ChatIconWithUnreadCount> {
  int sellerCount = 0;
  int buyerCount = 0;
  late UserUnreadMessageProvider provider;
  @override
  Widget build(BuildContext context) {
    final PsValueHolder psValueHolder = Provider.of<PsValueHolder>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(
                  Icons.chat_outlined,
                  size: 22,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
            Positioned(
                top: -3,
                right: -6,
                child: Consumer<UserUnreadMessageProvider>(builder:
                    (BuildContext context,
                        UserUnreadMessageProvider userUnreadMessageProvider,
                        Widget? child) {
                  if (userUnreadMessageProvider.userUnreadMessage.data !=
                      null) {
                    provider = userUnreadMessageProvider;
                    sellerCount = int.parse(userUnreadMessageProvider
                        .userUnreadMessage.data!.sellerUnreadCount!);
                    buyerCount = int.parse(userUnreadMessageProvider
                        .userUnreadMessage.data!.buyerUnreadCount!);
                    userUnreadMessageProvider.totalUnreadCount =
                        sellerCount + buyerCount;
                    if (Utils.isLoginUserEmpty(psValueHolder) ||
                        userUnreadMessageProvider.totalUnreadCount == 0) {
                      return const SizedBox();
                    } else {
                      if (userUnreadMessageProvider.totalUnreadCount > 0) {
                        Future<dynamic>.delayed(
                            Duration.zero, () => showMessageDialog(context));
                      }
                      return Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        child: Center(
                          child: Text(
                            userUnreadMessageProvider.totalUnreadCount > 9
                                ? '9+'
                                : userUnreadMessageProvider.totalUnreadCount
                                    .toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    fontSize: 9,
                                    color: Utils.isLightMode(context)
                                        ? PsColors.achromatic50
                                        : PsColors.achromatic800),
                            maxLines: 1,
                          ),
                        ),
                      );
                    }
                  } else {
                    return const SizedBox();
                  }
                })),
          ],
        ),
      ],
    );
  }

  Future<dynamic> showMessageDialog(BuildContext context) async {
    if (!Utils.isShowNotiFromToolbar() && !provider.isShowMessageDialog) {
      showDialog<dynamic>(
          context: context,
          builder: (_) {
            return ChatNotiDialog(
                description: 'noti_message__new_message'.tr,
                leftButtonText: 'chat_noti__cancel'.tr,
                rightButtonText: 'chat_noti__open'.tr,
                onAgreeTap: () {
                  widget.updateSelectedIndexWithAnimation(
                      'dashboard__bottom_navigation_message'.tr,
                      PsConst.REQUEST_CODE__DASHBOARD_MESSAGE_FRAGMENT);
                });
          });
      provider.isShowMessageDialog = true;
    }
  }
}
