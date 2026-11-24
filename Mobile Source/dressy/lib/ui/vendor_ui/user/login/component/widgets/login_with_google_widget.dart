import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';

class LoginWithGoogleWidget extends StatelessWidget {
  const LoginWithGoogleWidget(
      {required this.onGoogleSignInSelected,
      required this.callBackAfterLoginSuccess});

  final Function? onGoogleSignInSelected, callBackAfterLoginSuccess;

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final AppLocalization? langProvider = Provider.of<AppLocalization>(context);
    final bool isLight = Utils.isLightMode(context);

    return Container(
      margin: const EdgeInsets.only(
          left: PsDimens.space16,
          top: PsDimens.space12,
          right: PsDimens.space16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            width: 1.0,
          ),
          color: isLight ? Colors.white : const Color(0xFF1F2937),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.0),
            onTap: () async {
              await userProvider.loginWithGoogleId(
                context,
                onGoogleSignInSelected,
                callBackAfterLoginSuccess,
                langProvider!.currentLocale.languageCode
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  child: Image.asset(
                    'assets/images/google_logo.png',
                  ),
                ),
                const SizedBox(
                  width: PsDimens.space12,
                ),
                Text(
                  'Continuer avec Google',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1F2937) : Colors.white,
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
