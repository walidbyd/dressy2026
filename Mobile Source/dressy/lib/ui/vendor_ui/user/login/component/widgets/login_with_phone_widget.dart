import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../common/dialog/warning_dialog_view.dart';

class LoginWithPhoneWidget extends StatefulWidget {
  const LoginWithPhoneWidget({required this.onPhoneSignInSelected});
  final Function? onPhoneSignInSelected;

  @override
  __LoginWithPhoneWidgetState createState() => __LoginWithPhoneWidgetState();
}

class __LoginWithPhoneWidgetState extends State<LoginWithPhoneWidget> {
  late UserProvider provider;
  @override
  Widget build(BuildContext context) {
    provider = Provider.of<UserProvider>(context);
    return Container(
      height: 52,
      margin: const EdgeInsets.only(
          top: PsDimens.space16,
          left: PsDimens.space16,
          right: PsDimens.space16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.0),
          color: const Color(0xFFED7768),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFED7768).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.0),
            onTap: () async {
              if (provider.isCheckBoxSelect) {
                if (widget.onPhoneSignInSelected != null) {
                  widget.onPhoneSignInSelected!();
                } else {
                  Navigator.pushNamed(
                    context,
                    RoutePaths.user_phone_signin_container,
                  );
                }
              } else {
                showDialog<dynamic>(
                    context: context,
                    builder: (BuildContext context) {
                      return WarningDialog(
                        message: 'login__warning_agree_privacy'.tr,
                        onPressed: () {},
                      );
                    });
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 20),
                SizedBox(
                  width: PsDimens.space12,
                ),
                Text(
                  'Continuer avec le téléphone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
