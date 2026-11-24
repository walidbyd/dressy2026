import 'package:flutter/material.dart';

import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../common/ps_textfield_widget.dart';

class PhoneNoWidget extends StatefulWidget {
  const PhoneNoWidget({required this.phoneController});
  final TextEditingController phoneController;

  @override
  State<StatefulWidget> createState() => _PhoneNoWidgetState();
}

class _PhoneNoWidgetState extends State<PhoneNoWidget> {
  @override
  Widget build(BuildContext context) {
    return PsTextFieldWidget(
      titleText: 'Mobile'.tr,
      hintText: 'Mobile'.tr,
      keyboardType: TextInputType.phone,
      textAboutMe: false,
      textEditingController: widget.phoneController,
    );
  }
}
