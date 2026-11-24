import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../config/ps_colors.dart';
import '../../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../../core/vendor/provider/chat/get_chat_history_provider.dart';
import '../../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../../core/vendor/viewobject/holder/make_is_user_bought_parameter_holde.dart';
import '../../../../../../../../core/vendor/viewobject/message.dart';
import '../../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/sender/sender_accept_or_rejected_msg.dart';

class OfferAcceptedMsgWithUserBought extends StatelessWidget {
  const OfferAcceptedMsgWithUserBought(
      {required this.messageObj,
      required this.updateDataToFireBase,
      required this.insertDataToFireBase,
      required this.loginUserId,
      required this.isUserOnline});
  final Message messageObj;
  final Function updateDataToFireBase;
  final Function insertDataToFireBase;
  final String? loginUserId;

  final String? isUserOnline;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
