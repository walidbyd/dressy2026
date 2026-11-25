import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/message.dart';
import '../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../custom_ui/chat/component/detail/conversation_list/widgets/conversation_list_item.dart';
import '../../../../../custom_ui/chat/component/detail/conversation_list/widgets/date_widget.dart';

class ConversationList extends StatelessWidget {
  const ConversationList(
      {required this.messagesRef,
      required this.sessionId,
      required this.isUserOnline,
      required this.updateDataToFireBase,
      required this.insertDataToFireBase,
      required this.deleteDataToFireBase,
      required this.otherUserId,
      this.buyerUserId,
      this.sellerUserId,
      this.chatFlag});
  final DatabaseReference messagesRef;
  final String? sessionId;
  final String isUserOnline;
  final Function updateDataToFireBase;
  final Function insertDataToFireBase;
  final Function deleteDataToFireBase;
  final String? otherUserId;
  final String? buyerUserId;
  final String? sellerUserId;
  final String? chatFlag;

  List<Message> _extractMessages(
      dynamic rawValue, bool isOrderScopedSession, String effectiveItemId) {
    final List<Message> list = <Message>[];
    if (rawValue is Map) {
      rawValue.forEach((dynamic key, dynamic val) {
        final Message? msg = Message().fromMap(val);
        if (msg != null) {
          msg.id ??= key?.toString();
          list.add(msg);
        }
      });
    } else if (rawValue is List) {
      for (final dynamic val in rawValue) {
        final Message? msg = Message().fromMap(val);
        if (msg != null) {
          list.add(msg);
        }
      }
    }

    final List<Message> filtered = list.where((Message msg) {
      if (!isOrderScopedSession &&
          effectiveItemId.isNotEmpty &&
          (msg.itemId ?? '').trim().isNotEmpty &&
          msg.itemId!.trim() != effectiveItemId) {
        return false;
      }
      return true;
    }).toList();

    // Sort newest first because ListView.builder uses reverse: true
    filtered.sort((Message a, Message b) {
      final int tsB = b.addedDateTimeStamp ?? 0;
      final int tsA = a.addedDateTimeStamp ?? 0;
      return tsB.compareTo(tsA);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final ItemDetailProvider itemDetailProvider =
        Provider.of<ItemDetailProvider>(context);
    final Product itemDetail = itemDetailProvider.product;

    if (sessionId == null || sessionId!.isEmpty) {
      return const Expanded(child: SizedBox());
    }

    final bool isOrderScopedSession = sessionId!.contains('_order_');
    final String effectiveItemId = (itemDetail.id ?? '').trim().isNotEmpty
        ? itemDetail.id!.trim()
        : (Utils.activeChatItemId ?? '').trim();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: PsDimens.space8),
        child: StreamBuilder<DatabaseEvent>(
          key: ValueKey<String>(sessionId!),
          stream: messagesRef.child(sessionId!).onValue,
          builder:
              (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(PsDimens.space16),
                  child: Text(
                    'chat_view__load_error'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<Message> messages = _extractMessages(
              snapshot.data?.snapshot.value,
              isOrderScopedSession,
              effectiveItemId,
            );

            if (messages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(PsDimens.space16),
                  child: Text(
                    'chat_view__no_messages'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            }

            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(
                top: PsDimens.space8,
                bottom: PsDimens.space8,
              ),
              itemCount: messages.length,
              itemBuilder: (BuildContext context, int index) {
                final Message msg = messages[index];
                final int ts = msg.addedDateTimeStamp ?? 0;
                final String currentDate = Utils.convertTimeStampToDate(ts);
                final bool isOldestOrDateChanged;
                if (index == messages.length - 1) {
                  isOldestOrDateChanged = true;
                } else {
                  final int olderTs =
                      messages[index + 1].addedDateTimeStamp ?? 0;
                  final String olderDate =
                      Utils.convertTimeStampToDate(olderTs);
                  isOldestOrDateChanged = currentDate != olderDate;
                }

                final Widget itemWidget = CustomConversationListItem(
                  messageObj: msg,
                  updateDataToFireBase: updateDataToFireBase,
                  insertDataToFireBase: insertDataToFireBase,
                  deleteDataToFireBase: deleteDataToFireBase,
                  index: index,
                  isUserOnline: isUserOnline,
                  otherUserId: otherUserId,
                  buyerUserId: buyerUserId,
                  sellerUserId: sellerUserId,
                  chatFlag: chatFlag,
                );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isOldestOrDateChanged && currentDate.isNotEmpty)
                      CustomDateWidget(lastTimeStamp: currentDate),
                    itemWidget,
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
