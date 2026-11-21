import 'package:flutter/material.dart';

import '../../../../vendor_ui/user/phone/view/phone_sign_in_container_view.dart';

class CustomPhoneSignInContainerView extends StatefulWidget {
  const CustomPhoneSignInContainerView(
      {Key? key, this.isSignUp = false, this.initialPhone})
      : super(key: key);
  final bool isSignUp;
  final String? initialPhone;

  @override
  _CityPhoneSignInContainerViewState createState() =>
      _CityPhoneSignInContainerViewState();
}

class _CityPhoneSignInContainerViewState
    extends State<CustomPhoneSignInContainerView> {
  @override
  Widget build(BuildContext context) {
    return PhoneSignInContainerView(
      isSignUp: widget.isSignUp,
      initialPhone: widget.initialPhone,
    );
  }
}
