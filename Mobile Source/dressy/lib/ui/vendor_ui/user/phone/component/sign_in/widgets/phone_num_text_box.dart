import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../config/ps_colors.dart';
import '../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';

class PhoneNumTextBox extends StatefulWidget {
  const PhoneNumTextBox({
    required this.phoneController,
  });

  final TextEditingController phoneController;

  @override
  __PhoneNumTextBoxState createState() => __PhoneNumTextBoxState();
}

class __PhoneNumTextBoxState extends State<PhoneNumTextBox> {
  UserProvider? provider;
  PsValueHolder? psValueHolder;
  bool bindDataFirstTime = true;

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<UserProvider>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);
    if (bindDataFirstTime) {
      provider!.selectedCountryCode = '+213';
      provider!.selectedCountryName = 'Algeria';
      bindDataFirstTime = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'edit_profile__phone'.tr,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w500,
              color: Utils.isLightMode(context)
                  ? PsColors.text800
                  : PsColors.achromatic50),
        ),
        Container(
            margin: const EdgeInsets.only(
              top: PsDimens.space8,
            ),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                border: Border.all(color: PsColors.text400)),
            child: Row(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  width: 90,
                  height: 40,
                  decoration: BoxDecoration(
                      border: Border(
                          right: BorderSide(
                              color: Utils.isLightMode(context) ? PsColors.text50 : PsColors.text300))),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('🇩🇿 ', style: TextStyle(fontSize: 14)),
                      Text(
                          '+213',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    child: TextField(
                      controller: widget.phoneController,
                      textDirection:
                          Directionality.of(context) == TextDirection.ltr
                              ? TextDirection.ltr
                              : TextDirection.rtl,
                      textAlign: Directionality.of(context) == TextDirection.ltr
                          ? TextAlign.left
                          : TextAlign.right,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(
                            left: PsDimens.space12,
                            right: PsDimens.space12,
                            bottom: PsDimens.space8),
                        border: InputBorder.none,
                        hintText: '550 00 00 00',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: PsColors.text400),
                      ),
                    ),
                  ),
                )
              ],
              // )
            )),
      ],
    );
  }
}
