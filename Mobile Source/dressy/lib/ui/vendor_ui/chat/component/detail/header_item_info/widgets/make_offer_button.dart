import 'package:flutter/material.dart';

import '../../../../../../../core/vendor/provider/chat/get_chat_history_provider.dart';
import '../../../../../../../core/vendor/viewobject/product.dart';

class MakeOfferButton extends StatefulWidget {
  const MakeOfferButton({
    required this.isUserOnline,
    required this.insertDataToFireBase,
    required this.sessionId,
    required this.buyerUserId,
    required this.sellerUserId,
    this.itemDetail,
    this.getChatHistoryProvider,
  });
  final String isUserOnline;
  final Function insertDataToFireBase;
  final String sessionId;
  final String? buyerUserId;
  final String? sellerUserId;
  final Product? itemDetail;
  final GetChatHistoryProvider? getChatHistoryProvider;

  @override
  State<StatefulWidget> createState() => _MakeOfferButtonState();
}

class _MakeOfferButtonState extends State<MakeOfferButton> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
