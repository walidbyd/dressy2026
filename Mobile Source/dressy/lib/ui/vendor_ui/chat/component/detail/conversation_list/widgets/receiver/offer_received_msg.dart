import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../../config/ps_colors.dart';
import '../../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../../core/vendor/viewobject/message.dart';
import '../../../../../../../custom_ui/chat/component/detail/conversation_list/widgets/common/chat_price_widget.dart';

class OfferReceivedMsg extends StatelessWidget {
  const OfferReceivedMsg({
    required this.messageObj,
  });
  final Message messageObj;
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
