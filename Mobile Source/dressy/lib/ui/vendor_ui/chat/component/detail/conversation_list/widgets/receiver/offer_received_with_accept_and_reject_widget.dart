import 'package:flutter/material.dart';

import '../../../../../../../../core/vendor/viewobject/message.dart';

class OfferReceivedBoxWithAcceptAndRejectWidget extends StatelessWidget {
  const OfferReceivedBoxWithAcceptAndRejectWidget({
    required this.messageObj,
    required this.updateDataToFireBase,
    required this.insertDataToFireBase,
    required this.isUserOnline,
  });
  final Message messageObj;
  final Function updateDataToFireBase;
  final Function insertDataToFireBase;
  final String? isUserOnline;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
