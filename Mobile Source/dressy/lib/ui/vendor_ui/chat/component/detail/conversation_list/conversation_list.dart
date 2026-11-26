import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../../../config/ps_config.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/message.dart';
import '../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../custom_ui/chat/component/detail/conversation_list/widgets/conversation_list_item.dart';
import '../../../../../custom_ui/chat/component/detail/conversation_list/widgets/date_widget.dart';

class ConversationList extends StatefulWidget {
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

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  Future<List<Message>>? _restFallbackFuture;
  String? _restFallbackSessionId;

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

    final List<Message> result =
        filtered.isNotEmpty ? filtered : list;

    // Sort newest first because ListView.builder uses reverse: true
    result.sort((Message a, Message b) {
      final int tsB = b.addedDateTimeStamp ?? 0;
      final int tsA = a.addedDateTimeStamp ?? 0;
      return tsB.compareTo(tsA);
    });

    return result;
  }

  Future<List<Message>> _fetchViaBackend(
      String sessionId, bool isOrderScopedSession, String effectiveItemId) async {
    final PsValueHolder vh = Provider.of<PsValueHolder>(context, listen: false);
    final String fallbackSession = isOrderScopedSession && sessionId.contains('_order_')
        ? sessionId.split('_order_').first
        : '';
    final String fbParam = fallbackSession.isNotEmpty
        ? '&fallback_session_id=$fallbackSession'
        : '';
    final String participants =
        '&login_user_id=${vh.loginUserId ?? ''}&buyer_user_id=${widget.buyerUserId ?? ''}&seller_user_id=${widget.sellerUserId ?? ''}&item_id=$effectiveItemId';
    final Uri uri = Uri.parse(
        '${PsConfig.ps_app_url}chat/messages?session_id=$sessionId$fbParam$participants');
    final http.Response res = await http.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': PsConfig.ps_bearer_token,
        'header-token': vh.headerToken ?? '',
      },
    ).timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final dynamic decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) {
        return _extractMessages(
            decoded['messages'], isOrderScopedSession, effectiveItemId);
      }
    }
    return <Message>[];
  }

  Widget _buildMessageList(List<Message> messages) {
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
          final int olderTs = messages[index + 1].addedDateTimeStamp ?? 0;
          final String olderDate = Utils.convertTimeStampToDate(olderTs);
          isOldestOrDateChanged = currentDate != olderDate;
        }

        final Widget itemWidget = CustomConversationListItem(
          messageObj: msg,
          updateDataToFireBase: widget.updateDataToFireBase,
          insertDataToFireBase: widget.insertDataToFireBase,
          deleteDataToFireBase: widget.deleteDataToFireBase,
          index: index,
          isUserOnline: widget.isUserOnline,
          otherUserId: widget.otherUserId,
          buyerUserId: widget.buyerUserId,
          sellerUserId: widget.sellerUserId,
          chatFlag: widget.chatFlag,
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
  }

  @override
  Widget build(BuildContext context) {
    final ItemDetailProvider itemDetailProvider =
        Provider.of<ItemDetailProvider>(context);
    final Product itemDetail = itemDetailProvider.product;

    if (widget.sessionId == null || widget.sessionId!.isEmpty) {
      return const Expanded(child: SizedBox());
    }

    final String sessionId = widget.sessionId!;
    final bool isOrderScopedSession = sessionId.contains('_order_');
    final String effectiveItemId = (itemDetail.id ?? '').trim().isNotEmpty
        ? itemDetail.id!.trim()
        : (Utils.activeChatItemId ?? '').trim();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: PsDimens.space8),
        child: StreamBuilder<DatabaseEvent>(
          key: ValueKey<String>(sessionId),
          stream: widget.messagesRef.child(sessionId).onValue,
          builder:
              (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.hasError) {
              if (_restFallbackSessionId != sessionId ||
                  _restFallbackFuture == null) {
                _restFallbackSessionId = sessionId;
                _restFallbackFuture = _fetchViaBackend(
                    sessionId, isOrderScopedSession, effectiveItemId);
              }
              return FutureBuilder<List<Message>>(
                future: _restFallbackFuture,
                builder: (BuildContext ctx, AsyncSnapshot<List<Message>> restSnap) {
                  if (restSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (restSnap.hasError) {
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
                  return _buildMessageList(restSnap.data ?? <Message>[]);
                },
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
              if (_restFallbackSessionId != sessionId ||
                  _restFallbackFuture == null) {
                _restFallbackSessionId = sessionId;
                _restFallbackFuture = _fetchViaBackend(
                    sessionId, isOrderScopedSession, effectiveItemId);
              }
              return FutureBuilder<List<Message>>(
                future: _restFallbackFuture,
                builder: (BuildContext ctx, AsyncSnapshot<List<Message>> restSnap) {
                  if (restSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildMessageList(restSnap.data ?? <Message>[]);
                },
              );
            }

            return _buildMessageList(messages);
          },
        ),
      ),
    );
  }
}
