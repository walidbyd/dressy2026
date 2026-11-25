import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../core/vendor/viewobject/message.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/common/give_review_button.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/common/item_been_bought_msg.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/common/item_been_sold_msg.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/receiver/receiver_image_widget.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/receiver/receiver_text_msg.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/sender/mark_as_sold_button.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/sender/sender_image_widget.dart';
import '../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/sender/sender_text_msg.dart';
import 'common/order_chat_card_widget.dart';
import 'receiver/receiver_blocked_widget.dart';
import 'sender/sender_blocked_widget.dart';

class ConversationListItem extends StatelessWidget {
  const ConversationListItem(
      {required this.messageObj,
      required this.updateDataToFireBase,
      required this.insertDataToFireBase,
      required this.deleteDataToFireBase,
      required this.index,
      required this.isUserOnline,
      required this.otherUserId,
      this.buyerUserId,
      this.sellerUserId,
      this.chatFlag});
  final Message messageObj;
  final Function updateDataToFireBase;
  final Function insertDataToFireBase;
  final Function deleteDataToFireBase;
  final int index;
  final String? isUserOnline;
  final String? otherUserId;
  final String? buyerUserId;
  final String? sellerUserId;
  final String? chatFlag;

  @override
  Widget build(BuildContext context) {
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);

    // Render interactive Order Confirmation & Order Status cards
    final String msgType = messageObj.messageType ?? '';
    final String text = messageObj.message ?? '';
    final bool isConfirmationRequest = msgType == 'order_confirmation_request' ||
        text.startsWith('Nouvelle commande #') ||
        text.contains('confirmer la disponibilité');
    final bool isOrderStatusUpdate = msgType == 'order_status_update' ||
        text.startsWith('Commande #');

    // Rule: The buyer MUST NOT see the initial seller order confirmation request card!
    // When an order is placed, ONLY the seller receives the confirmation request.
    // The buyer only receives order status messages once the seller confirms (Accepted, Shipped, etc.).
    final String loginUserId = psValueHolder.loginUserId ?? '';
    final bool isBuyer = chatFlag == PsConst.CHAT_FROM_BUYER ||
        (loginUserId.isNotEmpty && loginUserId == buyerUserId) ||
        (sellerUserId != null && sellerUserId!.isNotEmpty && loginUserId != sellerUserId && otherUserId == sellerUserId);
    final bool isSeller = chatFlag == PsConst.CHAT_FROM_SELLER ||
        (sellerUserId != null && sellerUserId!.isNotEmpty && loginUserId == sellerUserId);

    if (isConfirmationRequest && (isBuyer || !isSeller)) {
      return const SizedBox.shrink();
    }

    if (isConfirmationRequest || isOrderStatusUpdate) {
      return OrderChatCardWidget(
        messageObj: messageObj,
        updateDataToFireBase: updateDataToFireBase,
        buyerUserId: buyerUserId,
        sellerUserId: sellerUserId,
        chatFlag: chatFlag,
      );
    }

    // Checking User id
    if (psValueHolder.loginUserId == '' || messageObj.sendByUserId == '') {
      return const SizedBox();
    }

    if (psValueHolder.loginUserId == messageObj.sendByUserId) {
      // sender
      if (messageObj.type == PsConst.CHAT_TYPE_TEXT ||
          (messageObj.type == null && (messageObj.message ?? '').isNotEmpty)) {
        if (messageObj.offerStatus == PsConst.CHAT_STATUS_OFFER ||
            messageObj.offerStatus == PsConst.CHAT_STATUS_ACCEPT ||
            messageObj.offerStatus == PsConst.CHAT_STATUS_REJECT) {
          return const SizedBox.shrink();
        } else {
          return CustomSenderTextMsg(
            messageObj: messageObj,
            deleteDataToFireBase: deleteDataToFireBase,
          );
        }
      } else if (messageObj.type == PsConst.CHAT_TYPE_OFFER) {
        return const SizedBox.shrink();
      } else if (messageObj.type == PsConst.CHAT_TYPE_BOUGHT) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            CustomItemHasBeenBoughtMsg(messageObj: messageObj),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        CustomGiveReviewButton(),
                        CustomMarkAsSoldButton(
                            messageObj: messageObj,
                            updateDataToFireBase: updateDataToFireBase,
                            insertDataToFireBase: insertDataToFireBase)
                      ]),
                ),
              ),
            ),
          ],
        );
      } else if (messageObj.type == PsConst.CHAT_TYPE_SOLD) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    CustomItemHasBeenBoughtMsg(messageObj: messageObj),
                    CustomItemHasBeenSoldMsg(messageObj: messageObj),
                  ]),
              CustomGiveReviewButton(),
            ]);
      } else if (messageObj.type == PsConst.CHAT_TYPE_IMAGE) {
        return CustomSenderImageWidget(
          messageObj: messageObj,
          deleteDataToFireBase: deleteDataToFireBase,
        );
      } else if (messageObj.type == PsConst.CHAT_TYPE_IS_BLOCKED) {
        return SenderBlockedWidget(
            messageObj: messageObj,
            otherUserId: otherUserId!,
            updateDataToFireBase: updateDataToFireBase);
      } else if (messageObj.type == PsConst.CHAT_TYPE_IS_UNBLOCKED) {
        return const SizedBox();
      } else {
        return const SizedBox();
      }
    } else {
      //receiver
      if (messageObj.type == PsConst.CHAT_TYPE_TEXT ||
          (messageObj.type == null && (messageObj.message ?? '').isNotEmpty)) {
        if (messageObj.offerStatus == PsConst.CHAT_STATUS_OFFER ||
            messageObj.offerStatus == PsConst.CHAT_STATUS_ACCEPT ||
            messageObj.offerStatus == PsConst.CHAT_STATUS_REJECT) {
          return const SizedBox.shrink();
        } else {
          return CustomReceiverTextMsg(
            messageObj: messageObj,
          );
        }
      } else if (messageObj.type == PsConst.CHAT_TYPE_OFFER) {
        return const SizedBox.shrink();
      } else if (messageObj.type == PsConst.CHAT_TYPE_SOLD) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    CustomItemHasBeenBoughtMsg(messageObj: messageObj),
                    CustomItemHasBeenSoldMsg(messageObj: messageObj),
                  ]),
              CustomGiveReviewButton(),
            ]);
      } else if (messageObj.type == PsConst.CHAT_TYPE_IMAGE) {
        return CustomReceiverImageMsg(messageObj: messageObj);
      } else if (messageObj.type == PsConst.CHAT_TYPE_BOUGHT) {
        return Column(
          children: <Widget>[
            CustomItemHasBeenBoughtMsg(messageObj: messageObj),
            CustomGiveReviewButton(),
          ],
        );
      } else if (messageObj.type == PsConst.CHAT_TYPE_IS_BLOCKED) {
        return ReceiverBlockedWidget();
      } else if (messageObj.type == PsConst.CHAT_TYPE_IS_UNBLOCKED) {
        return const SizedBox();
      } else {
        return const SizedBox();
      }
    }
  }
}
