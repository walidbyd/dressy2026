import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../../../vendor_ui/chat/component/detail/conversation_list/conversation_list.dart';

class CustomConversationList extends StatelessWidget {
  const CustomConversationList({
    required this.messagesRef,
    required this.sessionId,
    required this.isUserOnline,
    required this.updateDataToFireBase,
    required this.insertDataToFireBase,
    required this.deleteDataToFireBase,
    required this.otherUserId,
    this.buyerUserId,
    this.sellerUserId,
    this.chatFlag,
  });
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
  Widget build(BuildContext context) {
    return ConversationList(
        messagesRef: messagesRef,
        sessionId: sessionId,
        isUserOnline: isUserOnline,
        updateDataToFireBase: updateDataToFireBase,
        insertDataToFireBase: insertDataToFireBase,
        deleteDataToFireBase: deleteDataToFireBase,
        otherUserId: otherUserId,
        buyerUserId: buyerUserId,
        sellerUserId: sellerUserId,
        chatFlag: chatFlag);
  }
}
