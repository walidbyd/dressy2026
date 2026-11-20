import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/ps_colors.dart';
import '../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../core/vendor/viewobject/user.dart';
import '../../../../custom_ui/user/login/component/widgets/divider_or_widget.dart';
import '../../../../custom_ui/user/login/component/widgets/forgot_password_text_widget.dart';
import '../../../../custom_ui/user/login/component/widgets/go_to_register_text_widget.dart';
import '../../../../custom_ui/user/login/component/widgets/login_button.dart';
import '../../../../custom_ui/user/login/component/widgets/login_email_textbox.dart';
import '../../../../custom_ui/user/login/component/widgets/login_pwd_text_box.dart';
import '../../../../custom_ui/user/login/component/widgets/login_with_apple_widget.dart';
import '../../../../custom_ui/user/login/component/widgets/login_with_google_widget.dart';
import '../../../../custom_ui/user/login/component/widgets/login_with_phone_widget.dart';
import 'widgets/remember_me_widget.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    Key? key,
    this.animationController,
    this.animation,
    this.onProfileSelected,
    this.onForgotPasswordSelected,
    this.onSignInSelected,
    this.onPhoneSignInSelected,
    this.onFbSignInSelected,
    this.onGoogleSignInSelected,
  }) : super(key: key);

  final AnimationController? animationController;
  final Animation<double>? animation;
  final Function? onProfileSelected,
      onForgotPasswordSelected,
      onSignInSelected,
      onPhoneSignInSelected,
      onFbSignInSelected,
      onGoogleSignInSelected;

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  UserRepository? repo1;
  PsValueHolder? psValueHolder;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    widget.animationController!.forward();
    const Widget _spacingWidget = SizedBox(
      height: PsDimens.space28,
    );

    repo1 = Provider.of<UserRepository>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);

    return SliverToBoxAdapter(
        child: ChangeNotifierProvider<UserProvider>(
      lazy: false,
      create: (BuildContext context) {
        final UserProvider provider =
            UserProvider(repo: repo1, psValueHolder: psValueHolder);
        return provider;
      },
      child: Consumer<UserProvider>(builder:
          (BuildContext context, UserProvider provider, Widget? child) {
        /**
             * UI SECTION
             */
        return AnimatedBuilder(
          animation: widget.animationController!,
          child: Column(
            children: <Widget>[
              const SizedBox(height: PsDimens.space32),
              // Centered Dressy wordmark + tagline
              Text(
                'Dressy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: const Color(0xFF6B1D2F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'La mode seconde main en Algérie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Utils.isLightMode(context)
                      ? PsColors.text600
                      : PsColors.text400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: PsDimens.space24),
              CustomLoginEmailTextBox(emailController: emailController),
              CustomLoginPasswordTextBox(
                  passwordController: passwordController),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: PsDimens.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    RememberMeCheckBoxWidget(
                      emailController: emailController,
                      passwordController: passwordController,
                    ),
                    const SizedBox(
                      height: PsDimens.space10,
                    ),
                    CustomForgotPasswordTextWidget(
                      onForgotPasswordSelected: widget.onForgotPasswordSelected,
                    ),
                  ],
                ),
              ),
              CustomLoginButton(
                emailController: emailController,
                passwordController: passwordController,
                onProfileSelected: widget.onProfileSelected,
                callBackAfterLoginSuccess: callBackAfterLoginSuccess,
              ),
              if (Platform.isIOS ||
                  psValueHolder!.showPhoneLogin! ||
                  psValueHolder!.showGoogleLogin!)
                CustomDividerORWidget(),
              if (psValueHolder!.showPhoneLogin!)
                CustomLoginWithPhoneWidget(
                  onPhoneSignInSelected: widget.onPhoneSignInSelected,
                ),
              if (psValueHolder!.showGoogleLogin!)
                CustomLoginWithGoogleWidget(
                  onGoogleSignInSelected: widget.onGoogleSignInSelected,
                  callBackAfterLoginSuccess: callBackAfterLoginSuccess,
                ),
              if (Utils.isAppleSignInAvailable == 1 && Platform.isIOS)
                CustomLoginWithAppleIdWidget(
                  onAppleIdSignInSelected: widget.onGoogleSignInSelected,
                  callBackAfterLoginSuccess: callBackAfterLoginSuccess,
                ),
              const SizedBox(
                height: PsDimens.space20,
              ),
              CustomGoToRegisterTextWidget(
                onSignInSelected: widget.onSignInSelected,
              ),
              _spacingWidget,
            ],
          ),
          builder: (BuildContext context, Widget? child) {
            return FadeTransition(
                opacity: widget.animation!,
                child: Transform(
                    transform: Matrix4.translationValues(
                        0.0, 100 * (1.0 - widget.animation!.value), 0.0),
                    child: SingleChildScrollView(child: child)));
          },
        );
      }),
    ));
  }

  Future<void> callBackAfterLoginSuccess(User user) async {
    await Utils.completeAuthAndGoHome(context, user);
  }
}
